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
   //@FCSDKTransportActor
    var fcsdkCallService: FCSDKCallService
    var contactService: ContactService
    var authenticationService: AuthenticationService?
   //@FCSDKTransportActor
    var acbuc: ACBUC
   //@FCSDKTransportActor
    var fcsdkCall: FCSDKCall?
   //@FCSDKTransportActor
    var audioAllowed: Bool = false
   //@FCSDKTransportActor
    var videoAllowed: Bool = false
   //@FCSDKTransportActor
    var currentCamera: AVCaptureDevice.Position!
    var destination: String
    var hasVideo: Bool
    var isOutgoing: Bool
    var logger: Logger
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
        
//        if #available(iOS 16.0, *) {
//            Task {
//                await enableMulticamera()
//            }
//        }
    }
    
    deinit {
        authenticationService = nil
        fcsdkCall = nil
        logger.info("Deinit VC")
    }
//    @available(iOS 16.0, *)
//    func enableMulticamera() async {
//        Task.detached(priority: .background) {
//            let captureSession = AVCaptureSession()
//            let defaultDevices = AVCaptureDevice.DiscoverySession(
//                deviceTypes: [
//                    .builtInDualCamera,
//                    .builtInMicrophone,
//                    .builtInWideAngleCamera
//                ],
//                mediaType: .video,
//                position: .front
//            )
//            // Configure the capture session.
//            captureSession.beginConfiguration()
//            var captureDevice: AVCaptureDevice?
//
//            _ = defaultDevices.devices.map { dev in
//                if dev.hasMediaType(.video) {
//                    captureDevice = dev
//                }
//            }
//            guard let d = captureDevice else { return }
//            let input = try! AVCaptureDeviceInput(device: d)
//            captureSession.removeInput(input)
//
//            if captureSession.canAddInput(input) {
//
//                captureSession.addInput(input)
//
//            }
//
//
//
//
//
//            let output = AVCaptureVideoDataOutput()
//            guard captureSession.canAddOutput(output) else { return }
//            captureSession.sessionPreset = .high
//            captureSession.addOutput(output)
//            captureSession.commitConfiguration()
//
//
//            captureSession.removeOutput(self.videoDataOutput)
//
//            if captureSession.canAddOutput(self.videoDataOutput) {
//                captureSession.addOutput(self.videoDataOutput)
//                self.videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
//                self.videoDataOutput.setSampleBufferDelegate(self, queue: .global(qos: .background))
//
//            }
//
//            print("CONNECTIONS", captureSession.connections)
//            print("INPUTS", captureSession.inputs)
//            print("OUTPUTS", captureSession.outputs)
//            print("Supported___", captureSession.isMultitaskingCameraAccessSupported)
//            print(captureSession.isMultitaskingCameraAccessEnabled)
//
//            if captureSession.isMultitaskingCameraAccessSupported {
//                // Enable using the camera in multitasking modes.
//                captureSession.isMultitaskingCameraAccessEnabled = true
//            }
//            captureSession.commitConfiguration()
//
//            // Start the capture session.
//            captureSession.startRunning()
//        }
//    }
    
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
        Task {
            if self.authenticationService?.connectedToSocket != nil {
//                await
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
    
   //@FCSDKTransportActor
    func muteVideo(isMute: Bool) async throws {
        if isMute {
            self.fcsdkCallService.fcsdkCall?.call?.enableLocalVideo(false)
        } else {
            self.fcsdkCallService.fcsdkCall?.call?.enableLocalVideo(true)
        }
    }
    
   //@FCSDKTransportActor
    func muteAudio(isMute: Bool) async throws {
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
//        let communicationView = self.view as! CommunicationView
//        if communicationView.remoteView.frame.isEmpty,
//           self.fcsdkCallService.presentCommunication,
//           !self.isOutgoing {
//No Need. There must have been updates in SwiftUI/UIKit on loading view from background state
//            communicationView.anchors()
//        }
    }
    
   //@FCSDKTransportActor
    func onHoldView() async throws {
        self.fcsdkCallService.fcsdkCall?.call?.hold()
    }
    
   //@FCSDKTransportActor
    func removeOnHold() async throws {
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
    
   //@FCSDKTransportActor
    func flipCamera(show: Bool) {
        if show {
            self.currentCamera = .front
        } else {
            self.currentCamera = .back
        }
        self.acbuc.phone.setCamera(self.currentCamera)
    }
    
   //@FCSDKTransportActor
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
        //We get the buffer view from the SDK when the call has been answered. This means we already have the ACBClientCall Object
        ///This method is used to set the remoteView with a BufferView
        guard let remote = await self.fcsdkCallService.fcsdkCall?.call?.remoteBufferView() else { return }
//        
//        guard let local = await self.fcsdkCallService.fcsdkCall?.call?.preivewBufferView() else { return }
        communicationView.remoteView = remote
//        communicationView.previewView = local
    }
    
    /// Configurations for Capture
  //@FCSDKTransportActor
    func configureResolutionOptions() throws {
        _ = self.acbuc.phone.recommendedCaptureSettings()
    }
    
   //@FCSDKTransportActor
    func configureFramerateOptions() throws {
        _ = acbuc.phone.recommendedCaptureSettings()
    }
}
