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

class CommunicationViewController: UIViewController {
    
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
    
    override func loadView() {
        view = CommunicationView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        preferredContentSize = CGSize(width: 1080, height: 1920)
        NotificationCenter.default.addObserver(self, selector: #selector(UIApplicationDelegate.applicationDidBecomeActive(_:)), name: UIApplication.didBecomeActiveNotification, object: nil)
        Task {
            if self.authenticationService?.connectedToSocket != nil {
                self.configureVideo()
                if self.isOutgoing {
                    await self.initiateCall()
                } else {
                    let communicationView = self.view as! CommunicationView
                    await self.fcsdkCallDelegate?.passViewsToService(preview: communicationView.previewView, remoteView: communicationView.remoteView)
                }
            } else {
                self.logger.info("Not Connected to Server")
            }
        }
        self.gestures()
    }
    
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
                    blocked: false)
                
                try await self.contactService.delegate?.createContact(contact)
                await createCallObject(contact: contact)
            }
        } catch {
            self.logger.error("\(error)")
        }
    }
    
    @MainActor
    func createCallObject(contact: ContactModel) async {
        let communicationView = self.view as! CommunicationView
        let fcsdkCall = FCSDKCall(
            id: UUID(),
            handle: self.destination,
            hasVideo: self.hasVideo,
            previewView: communicationView.previewView,
            remoteView: communicationView.remoteView,
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
        guard let activeCall = await self.contactService.fetchActiveCall() else { return }
        await self.callKitManager.finishEnd(call: activeCall)
    }
    
    @MainActor
    func muteVideo(isMute: Bool) throws {
        if isMute {
            self.fcsdkCallService.fcsdkCall?.call?.enableLocalVideo(false)
        } else {
            self.fcsdkCallService.fcsdkCall?.call?.enableLocalVideo(true)
        }
    }
    
    @MainActor
    func muteAudio(isMute: Bool) throws {
        if isMute {
            self.fcsdkCallService.fcsdkCall?.call?.enableLocalAudio(false)
        } else {
            self.fcsdkCallService.fcsdkCall?.call?.enableLocalAudio(true)
        }
    }
    
    func gestures() {
        let communicationView = self.view as! CommunicationView
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(draggedLocalView(_:)))
        communicationView.previewView.isUserInteractionEnabled = true
        communicationView.previewView.addGestureRecognizer(panGesture)
    }
    
    @objc func applicationDidBecomeActive(_ notification: Notification) {
        let communicationView = self.view as! CommunicationView
        if communicationView.remoteView.frame.isEmpty,
           self.fcsdkCallService.presentCommunication,
           !self.isOutgoing {
            communicationView.anchors()
        }
    }
    
    func onHoldView() throws {
        self.fcsdkCallService.fcsdkCall?.call?.hold()
    }
    
    func removeOnHold() throws {
        self.fcsdkCallService.fcsdkCall?.call?.resume()
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
        Task {
            await MainActor.run {
                let communicationView = self.view as! CommunicationView
                communicationView.bringSubviewToFront(communicationView.previewView)
                let translation = sender.translation(in: self.view)
                communicationView.previewView.center = CGPoint(x: communicationView.previewView.center.x + translation.x, y: communicationView.previewView.center.y + translation.y)
                sender.setTranslation(CGPoint.zero, in: self.view)
            }
        }
    }
    
    @MainActor
    func flipCamera(show: Bool) {
        if show {
            self.currentCamera = .front
        } else {
            self.currentCamera = .back
        }
        self.acbuc.phone.setCamera(self.currentCamera)
    }
    
    @MainActor
    func configureVideo() {
        self.audioAllowed = AppSettings.perferredAudioDirection() == .receiveOnly || AppSettings.perferredAudioDirection() == .sendAndReceive
        self.videoAllowed = AppSettings.perferredVideoDirection() == .receiveOnly || AppSettings.perferredVideoDirection() == .sendAndReceive
        
        try? self.configureResolutionOptions()
        try? self.configureFramerateOptions()
        
        self.currentCamera = .front
    }
    
    @MainActor
    func updateRemoteViewForBuffer(remote: UIView, local: UIView) async {
        let communicationView = self.view as! CommunicationView
        communicationView.remoteView.removeFromSuperview()
        communicationView.remoteView = view
        //We get the buffer view from the SDK when the call has been answered. This means we already have the ACBClientCall Object
        ///This method is used to set the remoteView with a BufferView
        guard let remote = await self.fcsdkCallService.fcsdkCall?.call?.remoteBufferView() else { return }
        communicationView.remoteView = remote
        communicationView.previewView = local
    }
    
    /// Configurations for Capture
    func configureResolutionOptions() throws {
        _ = self.acbuc.phone.recommendedCaptureSettings()
    }
    
    
    func configureFramerateOptions() throws {
        _ = acbuc.phone.recommendedCaptureSettings()
    }
}
