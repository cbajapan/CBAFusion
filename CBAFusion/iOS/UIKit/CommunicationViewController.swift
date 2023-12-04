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



class CommunicationViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
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
        super.init(nibName: nil, bundle: nil)
    }
    
    deinit {
        authenticationService = nil
        logger.info("Deinit VC")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func loadView() {
        view = CommunicationView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        preferredContentSize = CGSize(width: 1080, height: 1920)
        NotificationCenter.default.addObserver(self, selector: #selector(UIApplicationDelegate.applicationDidBecomeActive(_:)), name: UIApplication.didBecomeActiveNotification, object: nil)
        Task { [weak self] in
            guard let self else { return }
            let communicationView = self.view as! CommunicationView
            if self.authenticationService?.connectedToSocket != nil {
                await self.configureVideo()
                if !fcsdkCallService.isBuffer {
                    communicationView.remoteView = UIView()
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

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
            let communicationView = self.view as! CommunicationView
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
                    calls: nil,
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
        let communicationView = self.view as! CommunicationView
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
        let communicationView = self.view as! CommunicationView
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(draggedLocalView(_:)))
        guard let previewView = communicationView.previewView else { return }
        previewView.isUserInteractionEnabled = true
        previewView.addGestureRecognizer(panGesture)
    }
    
    
    func onHoldView() async throws {
        await self.fcsdkCallService.fcsdkCall?.call?.hold()
    }
    
    func removeOnHold() async throws {
        await self.fcsdkCallService.fcsdkCall?.call?.resume()
    }
    
    func blurView() async {
        await MainActor.run {
            let communicationView = self.view as! CommunicationView
            communicationView.blurEffectView = UIVisualEffectView(effect: communicationView.blurEffect)
            communicationView.blurEffectView?.frame = self.view.bounds
            communicationView.blurEffectView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            self.view.addSubview(communicationView.blurEffectView!)
        }
    }
    
    func removeBlurView() async {
        await MainActor.run {
            let communicationView = self.view as! CommunicationView
            communicationView.blurEffectView?.removeFromSuperview()
        }
    }
    
    @objc func draggedLocalView(_ sender:UIPanGestureRecognizer) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            let communicationView = self.view as! CommunicationView
            guard let previewView = communicationView.previewView else { return }
            communicationView.bringSubviewToFront(previewView)
            let translation = sender.translation(in: self.view)
            previewView.center = CGPoint(x: previewView.center.x + translation.x, y: previewView.center.y + translation.y)
            sender.setTranslation(CGPoint.zero, in: self.view)
        }
    }
    
    func flipCamera(showFrontCamera: Bool) async {
        let communicationView = self.view as! CommunicationView
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
                FCSDKCallService.shared.acbuc?.phone.previewView = communicationView.previewView
                FCSDKCallService.shared.fcsdkCall?.call?.remoteView = communicationView.remoteView
            } else {
                FCSDKCallService.shared.acbuc?.phone.previewView  = communicationView.remoteView
                FCSDKCallService.shared.fcsdkCall?.call?.remoteView = communicationView.previewView
            }
        }
    }
    

    func configureVideo() async {
        self.audioAllowed = AppSettings.perferredAudioDirection() == .receiveOnly || AppSettings.perferredAudioDirection() == .sendAndReceive
        self.videoAllowed = AppSettings.perferredVideoDirection() == .receiveOnly || AppSettings.perferredVideoDirection() == .sendAndReceive
        
        try? await self.configureResolutionOptions()
        try? await self.configureFramerateOptions()
        
        self.currentCamera = .front
    }

    func layoutPipLayer() async {
        let communicationView = self.view as! CommunicationView
        guard let remoteView = communicationView.remoteView else { return }
        let layer = remoteView.layer as? AVSampleBufferDisplayLayer
        communicationView.pipLayer = layer
        await setUpPip(communicationView)
    }
    
    /// Configurations for Capture
    func configureResolutionOptions() async throws {
        _ = await self.acbuc.phone.recommendedCaptureSettings()
    }
    
    func configureFramerateOptions() async throws {
        _ = await acbuc.phone.recommendedCaptureSettings()
    }
}
