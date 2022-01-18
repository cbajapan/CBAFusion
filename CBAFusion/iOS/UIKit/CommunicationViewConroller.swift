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

class CommunicationViewController: AVPictureInPictureVideoCallViewController {
    
    enum CallState {
        case setup
        case hasStartedConnecting
        case isRinging
        case hasConnected
        case isOutgoing
        case hasEnded
        case cameraFront
        case cameraBack
        case hold
        case resume
        case muteAudio
        case resumeAudio
        case muteVideo
        case resumeVideo
    }
    
    weak var delegate: CommunicationViewControllerDelegate?
    weak var fcsdkCallDelegate: FCSDKCallDelegate?
    var stackView: UIStackView = {
        let stk = UIStackView()
        stk.alignment = .center
        return stk
    }()
    let numberLabel = UILabel()
    let nameLabel = UILabel()
    var remoteView = UIView()
    var previewView = UIView()
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
    let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.dark)
    var blurEffectView: UIVisualEffectView?
    var logger: Logger
    
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
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit{
        self.logger.info("Deinit VC")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        preferredContentSize = CGSize(width: 1080, height: 1920)
        Task {
            if self.authenticationService?.connectedToSocket != nil {
                await self.configureVideo()
                if self.isOutgoing {
                    do {
                        try await self.initiateCall()
                    } catch {
                         self.logger.error("\(error)")
                    }
                } else {
                    await self.fcsdkCallDelegate?.passViewsToService(preview: self.previewView, remoteView: self.remoteView)
                }
            } else {
                self.logger.info("Not Connected to Server")
            }
        }

        self.gestures()
    }
    
    @MainActor
    func updateRemoteViewForBuffer(view: UIView) async {
        self.remoteView.removeFromSuperview()
        self.remoteView = view
        print("Remote View", self.remoteView)
    }
    
    @MainActor
    func currentState(state: CallState) async {
        switch state {
        case .setup:
            break
        case .hasStartedConnecting:
            await self.connectingUI(isRinging: false)
        case .isRinging:
            await self.connectingUI(isRinging: true)
        case .hasConnected:
            await self.removeConnectingUI()
            await self.setupUI()
            await self.anchors()
        case .isOutgoing:
            break
        case .hold:
            do {
                try await self.onHoldView()
            } catch {
                 self.logger.error("\(error)")
            }
        case .resume:
            do {
                try await self.removeOnHold()
            } catch {
                 self.logger.error("\(error)")
            }
        case .hasEnded:
            await self.breakDownView()
            await self.removeConnectingUI()
            await self.currentState(state: .setup)
        case .muteVideo:
            do {
                try await self.muteVideo(isMute: true)
            } catch {
                 self.logger.error("\(error)")
            }
        case .resumeVideo:
            do {
                try await self.muteVideo(isMute: false)
            } catch {
                 self.logger.error("\(error)")
            }
        case .muteAudio:
            do {
                try await self.muteAudio(isMute: true)
            } catch {
                 self.logger.error("\(error)")
            }
        case .resumeAudio:
            do {
                try await self.muteAudio(isMute: false)
            } catch {
                 self.logger.error("\(error)")
            }
        case .cameraFront:
            await self.tapLocalView(show: true)
        case .cameraBack:
            await self.tapLocalView(show: false)
        }
    }
    
    
    func initiateCall() async throws {
        if let contact = self.contactService.contacts?.first(where: { $0.number == self.destination } )  {
            await createCallObject(contact: contact)
        } else {
            let contact = ContactModel(
                id: UUID(),
                username: self.destination,
                number: self.destination,
                calls: nil,
                blocked: false)
            
            do {
                try await self.contactService.delegate?.createContact(contact)
            } catch {
                 self.logger.error("\(error)")
            }
            
            await createCallObject(contact: contact)
        }
    }
    
    func createCallObject(contact: ContactModel) async {
        let fcsdkCall = FCSDKCall(
            id: UUID(),
            handle: self.destination,
            hasVideo: self.hasVideo,
            previewView: self.previewView,
            remoteView: self.remoteView,
            acbuc: self.acbuc,
            call: nil,
            activeCall: true,
            outbound: true,
            missed: false,
            rejected: false,
            contact: contact.id,
            createdAt: Date(),
            updatedAt: nil,
            deletedAt: nil)
        
        await self.fcsdkCallDelegate?.passCallToService(fcsdkCall)
        await self.callKitManager.initializeCall(fcsdkCall)
    }

    func endCall() async throws {
        guard let activeCall = try await self.contactService.fetchActiveCall() else { throw OurErrors.noActiveCalls }
        await self.callKitManager.finishEnd(call: activeCall)
    }
//We cannot mute because the call is nil we need make sure the call is on the fcsdkCall
    @MainActor
    func muteVideo(isMute: Bool) async throws {
        if isMute {
            self.fcsdkCallService.currentCall?.call?.enableLocalVideo(false)
        } else {
            self.fcsdkCallService.currentCall?.call?.enableLocalVideo(true)
        }
    }
    
    @MainActor
    func muteAudio(isMute: Bool) async throws {
        if isMute {
            self.fcsdkCallService.currentCall?.call?.enableLocalAudio(false)
        } else {
            self.fcsdkCallService.currentCall?.call?.enableLocalAudio(true)
        }
    }
    
    @MainActor
    func connectingUI(isRinging: Bool) async {
        self.numberLabel.text = self.fcsdkCall?.call?.remoteAddress
        self.numberLabel.font = .boldSystemFont(ofSize: 18)
        if isRinging {
            self.nameLabel.text = "Ringing..."
        } else {
            self.nameLabel.text = "FCSDK iOS Connecting..."
        }
        self.nameLabel.font = .systemFont(ofSize: 16)
        self.view.addSubview(self.stackView)
        self.stackView.addArrangedSubview(self.numberLabel)
        self.stackView.addArrangedSubview(self.nameLabel)
        self.stackView.axis = .vertical
        if UIApplication.shared.applicationState != .background || self.fcsdkCall?.call?.status == .inCall {
            self.stackView.anchors(top: self.view.topAnchor, leading: self.view.leadingAnchor, bottom: nil, trailing: self.view.trailingAnchor, topPadding: 50, leadPadding: 0, bottomPadding: 0, trailPadding: 0, width: 0, height: 0)
        }
    }
    
    @MainActor
    func removeConnectingUI() async {
        self.stackView.removeFromSuperview()
    }
    
    @MainActor
    func setupUI() async {
        self.view.addSubview(self.remoteView)
        self.remoteView.addSubview(self.previewView)
    }
    
    func gestures() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(draggedLocalView(_:)))
        self.previewView.isUserInteractionEnabled = true
        self.previewView.addGestureRecognizer(panGesture)
    }
    
    @MainActor
    func anchors() async {
        
        //We can adjust the size of video if we want to via the constraints API, the next 2 lines can center a view
        //        self.remoteView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
        //        self.remoteView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        
        if UIApplication.shared.applicationState != .background || self.fcsdkCall?.call?.status == .inCall {
            //We can change width and height as we wish
            self.remoteView.anchors(top: self.view.topAnchor, leading: self.view.leadingAnchor, bottom: self.view.bottomAnchor, trailing: self.view.trailingAnchor, topPadding: 0, leadPadding: 0, bottomPadding: 0, trailPadding: 0, width: 0, height: 0)
            if UIDevice.current.userInterfaceIdiom == .phone {
                self.previewView.anchors(top: nil, leading: nil, bottom: self.view.bottomAnchor, trailing: self.view.trailingAnchor, topPadding: 0, leadPadding: 0, bottomPadding: 110, trailPadding: 20, width: 150, height: 200)
                
            } else {
                self.previewView.anchors(top: nil, leading: nil, bottom: self.view.bottomAnchor, trailing: self.view.trailingAnchor, topPadding: 0, leadPadding: 0, bottomPadding: 110, trailPadding: 20, width: 250, height: 200)
            }
            
            //Not needed for video display just some custom UI Stuff
//            self.previewView.samplePreviewDisplayLayer?.videoGravity = .resizeAspectFill
//            // This will fill the frame, which could distort the video
//            self.previewView.samplePreviewDisplayLayer?.frame = self.previewView.bounds
//            self.previewView.samplePreviewDisplayLayer?.masksToBounds = true
//            self.previewView.samplePreviewDisplayLayer?.cornerRadius = 8
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        Task {
            await anchors()
        }
    }
    
    @MainActor
    func breakDownView() async {
        self.remoteView.removeFromSuperview()
        self.previewView.removeFromSuperview()
    }
    
    func onHoldView() async throws {
        self.fcsdkCallService.currentCall?.call?.hold()
    }
    
    func removeOnHold() async throws {
        self.fcsdkCallService.currentCall?.call?.resume()
    }
    
    func blurView() async {
        await MainActor.run {
            self.blurEffectView = UIVisualEffectView(effect: self.blurEffect)
            self.blurEffectView?.frame = self.view.bounds
            self.blurEffectView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            self.view.addSubview(self.blurEffectView!)
        }
    }
    
    func removeBlurView() async {
        await MainActor.run {
            self.blurEffectView?.removeFromSuperview()
        }
    }
    
    @objc func draggedLocalView(_ sender:UIPanGestureRecognizer) {
        Task {
            await MainActor.run {
                self.view.bringSubviewToFront(previewView)
                let translation = sender.translation(in: self.view)
                previewView.center = CGPoint(x: previewView.center.x + translation.x, y: previewView.center.y + translation.y)
                sender.setTranslation(CGPoint.zero, in: self.view)
            }
        }
    }
    
    
    
    @MainActor
    func tapLocalView(show: Bool) async {
        if show {
            self.currentCamera = .front
        } else {
            self.currentCamera = .back
        }
        self.acbuc.phone.setCamera(self.currentCamera)
    }
    
    @MainActor
    func configureVideo() async {
        self.audioAllowed = AppSettings.perferredAudioDirection() == .receiveOnly || AppSettings.perferredAudioDirection() == .sendAndReceive
        self.videoAllowed = AppSettings.perferredVideoDirection() == .receiveOnly || AppSettings.perferredVideoDirection() == .sendAndReceive
        
        try? self.configureResolutionOptions()
        try? self.configureFramerateOptions()
        
        self.currentCamera = .front
    }
    
    /// Configurations for Capture
    func configureResolutionOptions() throws {
        _ = self.acbuc.phone.recommendedCaptureSettings()
    }
    
    
    func configureFramerateOptions() throws {
        _ = acbuc.phone.recommendedCaptureSettings()
    }
    
    
    
}
