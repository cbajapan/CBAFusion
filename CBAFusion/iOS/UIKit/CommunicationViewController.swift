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


final class RemoteViews: ObservableObject {
    
    static let shared = RemoteViews()
    
    @Published var views = [RemoteVideoViewModel]()
    
    func getViews() async -> [RemoteVideoViewModel] {
        return views
    }
}


struct RemoteVideoViewModel: Hashable {
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

class RemoteViewItemCell: UICollectionViewCell {
    
    static let reuseIdentifer = "remote-video-item-cell-reuse-identifier"
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

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
        Task { [weak self] in
            guard let self else { return }
            view.addSubview(communicationView)
            communicationView.anchors(
                top: view.topAnchor,
                leading: view.leadingAnchor,
                bottom: view.bottomAnchor,
                trailing: view.trailingAnchor
            )
            communicationView.previewView?.isUserInteractionEnabled = true
            communicationView.backgroundColor = .clear
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
    }
    
    deinit {
        RemoteViews.shared.views.removeAll()
        NotificationCenter.default.removeObserver(self)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.isScrollEnabled = false
        collectionView.delegate = self
        collectionView.allowsSelection = true
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.configureHierarchy()
        self.configureDataSource()
        Task { @MainActor [weak self] in
            guard let self else { return }
            await self.performQuery()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            deleteSnap()
        }
    }
    
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
    
    @MainActor
    func deleteSnap() {
        var snapshot = dataSource.snapshot()
        snapshot.deleteAllItems()
        dataSource.apply(snapshot)
    }
    
    func configureHierarchy() {
        collectionView.register(RemoteViewItemCell.self, forCellWithReuseIdentifier: RemoteViewItemCell.reuseIdentifer)
    }
    
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
    
    @MainActor
    func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource<ConferenceCallSections, RemoteVideoViewModel>(collectionView: collectionView) { [weak self]
            (collectionView: UICollectionView, indexPath: IndexPath, model: RemoteVideoViewModel) -> UICollectionViewCell? in
            guard let self else { return nil }
            let section = ConferenceCallSections(rawValue: indexPath.section)!
            switch section {
            case .inital:
                if let item = collectionView.dequeueReusableCell(withReuseIdentifier: RemoteViewItemCell.reuseIdentifer, for: indexPath) as? RemoteViewItemCell {
                    self.setCollectionViewItem(item: item, viewModel: model)
                    return item
                } else {
                    fatalError("Cannot create other item")
                }
            }
        }
    }
    
    enum SectionType: Sendable {
        case fullscreen, conference
    }
    static func createLayout(sectionType: SectionType) -> UICollectionViewCompositionalLayout {
        switch sectionType {
        case .fullscreen:
            return UICollectionViewCompositionalLayout(section: CollectionViewSections.shared.fullScreenItem())
        case .conference:
            return UICollectionViewCompositionalLayout(section: CollectionViewSections.shared.conferenceViewSection(itemCount: 2))
        }
    }
}

extension CommunicationViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        if #available(iOS 15.0, *), fcsdkCallService.isBuffer {
            communicationView.updateAnchors(UIDevice.current.orientation, flipped: communicationView.isFlipped)
        }
    }
    
    @objc func applicationDidBecomeActive(_ notification: Notification) {}
    
    func initiateCall() async {
        do {
            try await self.contactService.fetchContacts()
            if let contact = self.contactService.contacts?.first(where: { $0.number == self.destination } )  {
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
    
    //Feed buffer views if we are using buffers instead of the standard view
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
    
    func endCall() async throws {
        guard let activeCall = await self.contactService.fetchActiveCall() else { return }
        try await self.fcsdkCallService.endFCSDKCall(activeCall)
        await self.callKitManager.finishEnd(call: activeCall)
    }
    
    func muteVideo(isMute: Bool) async throws {
        if isMute {
            await self.fcsdkCallService.fcsdkCall?.call?.enableLocalVideo(false)
        } else {
            await self.fcsdkCallService.fcsdkCall?.call?.enableLocalVideo(true)
        }
    }
    
    func muteAudio(isMute: Bool) async throws {
        if isMute {
            await self.fcsdkCallService.fcsdkCall?.call?.enableLocalAudio(false)
        } else {
            await self.fcsdkCallService.fcsdkCall?.call?.enableLocalAudio(true)
        }
    }
    
    func gestures() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(draggedLocalView(_:)))
        guard let previewView = communicationView.previewView else { return }
        previewView.isUserInteractionEnabled = true
        previewView.addGestureRecognizer(panGesture)
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
    
    func blurView() async {
        await MainActor.run {
            communicationView.blurEffectView = UIVisualEffectView(effect: communicationView.blurEffect)
            communicationView.blurEffectView?.frame = self.view.bounds
            communicationView.blurEffectView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            self.view.addSubview(communicationView.blurEffectView!)
        }
    }
    
    func removeBlurView() async {
        await MainActor.run {
            communicationView.blurEffectView?.removeFromSuperview()
        }
    }
    
    @objc func draggedLocalView(_ sender:UIPanGestureRecognizer) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            guard let previewView = communicationView.previewView else { return }
            communicationView.bringSubviewToFront(previewView)
            let translation = sender.translation(in: self.view)
            previewView.center = CGPoint(x: previewView.center.x + translation.x, y: previewView.center.y + translation.y)
            sender.setTranslation(CGPoint.zero, in: self.view)
        }
    }
    
    func flipCamera(showFrontCamera: Bool) async {
        if showFrontCamera {
            self.currentCamera = .front
        } else {
            self.currentCamera = .back
        }
        
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
    
    
    func configureVideo() async {
        self.audioAllowed = AppSettings.perferredAudioDirection() == .receiveOnly || AppSettings.perferredAudioDirection() == .sendAndReceive
        self.videoAllowed = AppSettings.perferredVideoDirection() == .receiveOnly || AppSettings.perferredVideoDirection() == .sendAndReceive
        
        try? await self.configureRecommendedSettings()
        
        self.currentCamera = .front
    }
    
    func layoutPipLayer() async {
        guard let remoteView = RemoteViews.shared.views.first?.remoteVideoView else { return }
        let sourceLayer = remoteView.sampleBufferLayer
        communicationView.pipLayer = sourceLayer
        await setUpPip(communicationView)
    }
    
    /// Configurations for Capture
    func configureRecommendedSettings() async throws {
        _ = await self.acbuc.phone.recommendedCaptureSettings()
    }
}
