//
//  CommunicationViewConroller.swift
//  CBAFusion
//
//  Created by Cole M on 9/1/21.
//

import Foundation
import UIKit
import FCSDKiOS
import AVKit
import Logging

/// A singleton class that manages remote video views.
final class RemoteViews: ObservableObject, @unchecked Sendable {
    let lock = NSLock()
    
    @MainActor
    static let shared = RemoteViews()
    
    /// An array of remote video view models.
    @Published var views = [RemoteVideoViewModel]()
    
    /// Asynchronously retrieves the current remote video views.
    /// - Returns: An array of `RemoteVideoViewModel`.
    @MainActor
    func getViews() async -> [RemoteVideoViewModel] {
        lock.withLock {
            views
        }
    }
}

/// A view model representing a remote video view.
struct RemoteVideoViewModel: Hashable, Sendable {
    var id = UUID()
    var remoteVideoView: UIView
    
    init(remoteVideoView: UIView) {
        self.remoteVideoView = remoteVideoView
    }
    
    static func == (lhs: RemoteVideoViewModel, rhs: RemoteVideoViewModel) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/// A custom collection view cell for displaying remote video items.
class RemoteViewItemCell: UICollectionViewCell {
    
    static let reuseIdentifier = "remote-video-item-cell-reuse-identifier"
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layoutMargins = .zero
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// A view controller that manages the communication view and video calls.
class CommunicationViewController: UICollectionViewController {
    
    weak var fcsdkCallDelegate: FCSDKCallDelegate?
    var callKitManager: CallKitManager
    var fcsdkCallService: FCSDKCallService
    var contactService: ContactService
    var authenticationService: AuthenticationService?
    var acbuc: ACBUC
    var fcsdkCall: FCSDKCall?
    var audioAllowed: Bool = false
    var videoAllowed: Bool = false
    var currentCamera: AVCaptureDevice.Position!
    var destination: String
    var hasVideo: Bool
    var isOutgoing: Bool
    var logger: Logger
    var pipController: AVPictureInPictureController?
    var vc: UIViewController?
    let videoDataOutput = AVCaptureVideoDataOutput()
    var dataSource: UICollectionViewDiffableDataSource<ConferenceCallSections, RemoteVideoViewModel>!
    let communicationView = CommunicationView()
    
    /// Initializes a new instance of `CommunicationViewController`.
    /// - Parameters:
    ///   - callKitManager: The CallKit manager.
    ///   - fcsdkCallService: The SDK call service.
    ///   - contactService: The contact service.
    ///   - destination: The destination for the call.
    ///   - hasVideo: A boolean indicating if the call has video.
    ///   - acbuc: The ACBUC instance.
    ///   - isOutgoing: A boolean indicating if the call is outgoing.
    init(
        callKitManager: CallKitManager,
        fcsdkCallService: FCSDKCallService,
        contactService: ContactService,
        destination: String,
        hasVideo: Bool,
        acbuc: ACBUC,
        isOutgoing: Bool
    ) {
        self.logger = Logger(label: "\(Constants.BUNDLE_IDENTIFIER) - CommunicationViewController - ")
        self.callKitManager = callKitManager
        self.fcsdkCallService = fcsdkCallService
        self.contactService = contactService
        self.destination = destination
        self.hasVideo = hasVideo
        self.acbuc = acbuc
        self.isOutgoing = isOutgoing
        let layout = CommunicationViewController.createLayout(sectionType: .fullscreen)
        super.init(collectionViewLayout: layout)
        
        preferredContentSize = CGSize(width: 1080, height: 1920)
        NotificationCenter.default.addObserver(self, selector: #selector(UIApplicationDelegate.applicationDidBecomeActive(_:)), name: UIApplication.didBecomeActiveNotification, object: nil)
        
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            self.setupCommunicationView()
            await self.handleCallInitialization()
        }
    }
    
    deinit {
        Task { @MainActor in
            RemoteViews.shared.views.removeAll()
        }
        NotificationCenter.default.removeObserver(self)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @MainActor
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.isScrollEnabled = false
        collectionView.delegate = self
        collectionView.allowsSelection = true
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            self.configureHierarchy()
            self.configureDataSource()
            await self.performQuery()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            self.deleteSnap()
        }
    }
    
    /// Asynchronously performs a query to update the collection view with remote video views.
    @MainActor
    func performQuery() async {
        var snapshot = NSDiffableDataSourceSnapshot<ConferenceCallSections, RemoteVideoViewModel>()
        dataSource.apply(snapshot)
        
        let data = await RemoteViews.shared.getViews()
        if data.isEmpty {
            snapshot.deleteSections([.inital])
            snapshot.deleteItems(data)
            dataSource.apply(snapshot, animatingDifferences: false)
        } else {
            snapshot.appendSections([.inital])
            snapshot.appendItems(data, toSection: .inital)
            dataSource.apply(snapshot, animatingDifferences: true)
        }
    }
    
    /// Deletes all items from the current snapshot of the data source.
    @MainActor
    func deleteSnap() {
        var snapshot = dataSource.snapshot()
        snapshot.deleteAllItems()
        dataSource.apply(snapshot)
    }
    
    /// Configures the collection view hierarchy.
    func configureHierarchy() {
        collectionView.register(RemoteViewItemCell.self, forCellWithReuseIdentifier: RemoteViewItemCell.reuseIdentifier)
    }
    
    /// Sets up the communication view and its constraints.
    @MainActor
    fileprivate func setupCommunicationView() {
        view.addSubview(communicationView)
        communicationView.anchors(
            top: view.topAnchor,
            leading: view.leadingAnchor,
            bottom: view.bottomAnchor,
            trailing: view.trailingAnchor
        )
        communicationView.previewView?.isUserInteractionEnabled = true
        communicationView.backgroundColor = .clear
    }
    
    /// Configures the data source for the collection view.
    @MainActor
    func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource<ConferenceCallSections, RemoteVideoViewModel>(collectionView: collectionView) { @MainActor [weak self] (collectionView: UICollectionView, indexPath: IndexPath, model: RemoteVideoViewModel) -> UICollectionViewCell? in
            guard let self = self else { return nil }
            let section = ConferenceCallSections(rawValue: indexPath.section)!
            switch section {
            case .inital:
                if let item = collectionView.dequeueReusableCell(withReuseIdentifier: RemoteViewItemCell.reuseIdentifier, for: indexPath) as? RemoteViewItemCell {
                    self.setCollectionViewItem(item: item, viewModel: model)
                    return item
                } else {
                    fatalError("Cannot create other item")
                }
            }
        }
    }
    
    /// Sets the collection view item with the corresponding view model.
    /// - Parameters:
    ///   - item: The collection view cell to configure.
    ///   - viewModel: The view model containing the remote video view.
    @MainActor
    fileprivate func setCollectionViewItem(item: RemoteViewItemCell? = nil, viewModel: RemoteVideoViewModel) {
        guard let item = item else { return }
        item.addSubview(viewModel.remoteVideoView)
        viewModel.remoteVideoView.anchors(
            top: item.topAnchor,
            leading: item.leadingAnchor,
            bottom: item.bottomAnchor,
            trailing: item.trailingAnchor
        )
    }
    
    
    
    enum SectionType: Sendable {
        case fullscreen, conference
    }
    
    
    
    /// Creates a layout for the collection view based on the specified section type.
    /// - Parameter sectionType: The type of section layout to create.
    /// - Returns: A `UICollectionViewCompositionalLayout`.
    @MainActor
    static func createLayout(sectionType: SectionType) -> UICollectionViewCompositionalLayout {
        let sections = CollectionViewSections()
        switch sectionType {
        case .fullscreen:
            return UICollectionViewCompositionalLayout(section: sections.fullScreenItem())
        case .conference:
            return UICollectionViewCompositionalLayout(section: sections.conferenceViewSection(itemCount: 4, aspectRatio: UIScreen.main.bounds.size.width / UIScreen.main.bounds.size.height))
        }
    }
    
    /// Handles the initialization of the call and UI setup.
    @MainActor
    private func handleCallInitialization() async {
        if self.authenticationService?.connectedToSocket != nil {
            await self.configureVideo()
            if !fcsdkCallService.isBuffer {
                RemoteViews.shared.views.append(.init(remoteVideoView: UIView()))
                communicationView.previewView = UIView()
                communicationView.setupUI()
                communicationView.updateAnchors(UIDevice.current.orientation)
            }
            if self.isOutgoing {
                await self.initiateCall()
            } else {
                await self.fcsdkCallDelegate?.passViewsToService(communicationView: communicationView)
            }
        } else {
            self.logger.info("Not Connected to Server")
        }
        self.gestures()
    }
    
    // MARK: - Call Management
    
    /// Initiates a call to the specified destination.
    func initiateCall() async {
        do {
            try await self.contactService.fetchContacts()
            if let contact = self.contactService.contacts?.first(where: { $0.number == self.destination }) {
                await createCallObject(contact: contact)
            } else {
                let contact = ContactModel(
                    id: UUID(),
                    username: self.destination,
                    number: self.destination,
                    calls: [],
                    blocked: false
                )
                try await self.contactService.delegate?.createContact(contact)
                await createCallObject(contact: contact)
            }
        } catch {
            self.logger.error("\(error)")
        }
    }
    
    /// Creates a call object and passes it to the call delegate.
    /// - Parameter contact: The contact to associate with the call.
    func createCallObject(contact: ContactModel) async {
        let fcsdkCall = FCSDKCall(
            id: UUID(),
            handle: self.destination,
            hasVideo: self.hasVideo,
            communicationView: communicationView,
            acbuc: self.acbuc,
            activeCall: true,
            outbound: true,
            missed: false,
            rejected: false,
            contact: contact.id,
            createdAt: Date()
        )
        
        await self.fcsdkCallDelegate?.passCallToService(fcsdkCall)
        await self.callKitManager.initializeCall(fcsdkCall)
    }
    
    /// Ends the current active call.
    func endCall() async throws {
        guard let activeCall = await self.contactService.fetchActiveCall() else { return }
        try await self.fcsdkCallService.endFCSDKCall(activeCall)
        await self.callKitManager.finishEnd(call: activeCall)
    }
    
    /// Mutes or unmutes the local video.
    /// - Parameter isMute: A boolean indicating whether to mute the video.
    func muteVideo(isMute: Bool) async throws {
        if isMute {
            await blurView()
        } else {
            await removeBlurView()
        }
        await self.fcsdkCallService.fcsdkCall?.call?.enableLocalVideo(!isMute)
    }
    
    /// Mutes or unmutes the local audio.
    /// - Parameter isMute: A boolean indicating whether to mute the audio.
    func muteAudio(isMute: Bool) async throws {
        await self.fcsdkCallService.fcsdkCall?.call?.enableLocalAudio(!isMute)
    }
    
    // MARK: - Gesture Handling
    
    /// Configures gesture recognizers for the communication view.
    func gestures() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(draggedLocalView(_:)))
        guard let previewView = communicationView.previewView else { return }
        previewView.isUserInteractionEnabled = true
        previewView.addGestureRecognizer(panGesture)
    }
    
    /// Handles dragging of the local view.
    /// - Parameter sender: The pan gesture recognizer.
    @objc func draggedLocalView(_ sender: UIPanGestureRecognizer) {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            guard let previewView = communicationView.previewView else { return }
            communicationView.bringSubviewToFront(previewView)
            let translation = sender.translation(in: self.view)
            previewView.center = CGPoint(x: previewView.center.x + translation.x, y: previewView.center.y + translation.y)
            sender.setTranslation(.zero, in: self.view)
        }
    }
    
    // MARK: - Camera Management
    
    /// Flips the camera between front and back.
    /// - Parameter showFrontCamera: A boolean indicating whether to show the front camera.
    func flipCamera(showFrontCamera: Bool) async {
        self.currentCamera = showFrontCamera ? .front : .back
        
        if #available(iOS 15, *) {
            if fcsdkCallService.backgroundImage != nil, currentCamera == .back {
                await self.acbuc.phone.currentCalls.last?.removeBackgroundImage()
                await self.acbuc.phone.setCamera(self.currentCamera)
            } else if let image = fcsdkCallService.backgroundImage {
                await self.acbuc.phone.setCamera(self.currentCamera)
                await self.acbuc.phone.currentCalls.last?.feedBackgroundImage(image, mode: image.title == "blur" ? .blur : .image)
            } else {
                await self.acbuc.phone.setCamera(self.currentCamera)
            }
        } else {
            await self.acbuc.phone.setCamera(self.currentCamera)
        }
        
        if FCSDKCallService.shared.swapViews {
            if showFrontCamera {
                FCSDKCallService.shared.delegate?.uc?.phone.previewView = communicationView.previewView
                FCSDKCallService.shared.fcsdkCall?.call?.remoteView = RemoteViews.shared.views.first?.remoteVideoView
            } else {
                FCSDKCallService.shared.delegate?.uc?.phone.previewView = RemoteViews.shared.views.first?.remoteVideoView
                FCSDKCallService.shared.fcsdkCall?.call?.remoteView = communicationView.previewView
            }
        }
    }
    
    /// Configures video settings based on user preferences.
    func configureVideo() async {
        self.audioAllowed = AppSettings.perferredAudioDirection() == .receiveOnly || AppSettings.perferredAudioDirection() == .sendAndReceive
        self.videoAllowed = AppSettings.perferredVideoDirection() == .receiveOnly || AppSettings.perferredVideoDirection() == .sendAndReceive
        
        try? await self.configureRecommendedSettings()
        
        self.currentCamera = .front
    }
    
    /// Configures recommended settings for video capture.
    func configureRecommendedSettings() async throws {
        _ = await self.acbuc.phone.recommendedCaptureSettings()
    }
    
    func blurView() async {
        await MainActor.run {
            communicationView.blurEffectView = UIVisualEffectView(effect: communicationView.blurEffect)
            communicationView.blurEffectView?.frame = self.view.bounds
            communicationView.block.frame = self.view.bounds
            communicationView.blurEffectView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            if let blurEffectView = communicationView.blurEffectView, let previewView = communicationView.previewView {
                previewView.addSubview(communicationView.block)
                previewView.addSubview(blurEffectView)
            }
        }
    }
    func removeBlurView() async {
        await MainActor.run {
            communicationView.block.removeFromSuperview()
            communicationView.blurEffectView?.removeFromSuperview()
        }
    }
    
    func onHoldView() async throws {
        await self.fcsdkCallService.fcsdkCall?.call?.hold()
        if #available(iOS 16, *) {
            //            try await createScreenShot()
        } else {
            // Fallback on earlier versions
        }
    }
    
    func removeOnHold() async throws {
        await self.fcsdkCallService.fcsdkCall?.call?.resume()
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension CommunicationViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        if #available(iOS 15.0, *), fcsdkCallService.isBuffer {
            communicationView.updateAnchors(UIDevice.current.orientation, flipped: communicationView.isFlipped)
        }
    }
    
    @objc func applicationDidBecomeActive(_ notification: Notification) {}
    
}
