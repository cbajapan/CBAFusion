//
//  CommunicationViewConroller.swift
//  SwiftFCSDKSample
//
//  Created by Cole M on 9/1/21.
//

import Foundation
import UIKit
import SwiftFCSDK
import AVKit

enum CallState {
    case hasStartedConnecting
    case isRinging
    case hasConnected
    case isOutgoing
    case isOnHold
    case notOnHold
    case hasEnded
}

internal var activeCustomPlayerViewControllers = Set<CommunicationViewController>()

class CommunicationViewController: AVPictureInPictureVideoCallViewController {
    
    weak var delegate: CommunicationViewControllerDelegate?
    weak var fcsdkCallDelegate: FCSDKCallDelegate?
    var stackView: UIStackView = {
       let stk = UIStackView()
        stk.alignment = .center
        return stk
    }()
    let numberLabel = UILabel()
    let nameLabel = UILabel()
    var remoteView = SampleBufferVideoCallView()
    var previewView = SamplePreviewVideoCallView()
    var callKitManager: CallKitManager
    var acbuc: ACBUC
    var fcsdkCallViewModel: FCSDKCallViewModel?
    var audioAllowed: Bool = false
    var videoAllowed: Bool = false
    var currentCamera: AVCaptureDevice.Position!
    var destination: String
    var hasVideo: Bool
    let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.dark)
    var blurEffectView: UIVisualEffectView?
    
    
    init(
        callKitManager: CallKitManager,
        destination: String,
        hasVideo: Bool,
        acbuc: ACBUC
    ) {
        self.callKitManager = callKitManager
        self.destination = destination
        self.hasVideo = hasVideo
        self.acbuc = acbuc
        super.init(nibName: nil, bundle: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(setCurrentCall), name: NSNotification.Name("add"), object: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        preferredContentSize = CGSize(width: 1080, height: 1920)
        Task {
            await configureVideo()
            await initiateCall()
        }
        gestures()
    }
    
    func initiateCall() async {
        let fcsdkCallViewModel = FCSDKCallViewModel(fcsdkCall: FCSDKCall(handle: self.destination, hasVideo: true, previewView: self.previewView, remoteView: self.remoteView, uuid: UUID(), acbuc: self.acbuc))
        await self.fcsdkCallDelegate?.passCallToService(fcsdkCallViewModel.fcsdkCall)
        await self.callKitManager.initializeCall(fcsdkCallViewModel.fcsdkCall)
    }
    
    @objc func setCurrentCall() {
        guard let currentCall = self.callKitManager.calls.last else { return }
        self.fcsdkCallViewModel?.fcsdkCall = currentCall
    }
    
    func endCall() async {
        guard let currentCall = self.fcsdkCallViewModel?.fcsdkCall else { return }
        await self.callKitManager.finishEnd(call: currentCall)
        await self.callKitManager.removeCall(call: currentCall)
    }
    
    func currentState(state: CallState) {
        switch state {
        case .hasStartedConnecting:
            Task {
            await self.connectingUI(isRinging: false)
            }
        case .isRinging:
            Task {
            await self.connectingUI(isRinging: true)
            }
        case .hasConnected:
            Task {
            await self.removeConnectingUI()
            await self.setupUI()
            await self.anchors()
            }
        case .isOutgoing:
            break
        case .isOnHold:
            self.onHoldView()
        case .notOnHold:
            self.removeOnHold()
        case .hasEnded:
            self.breakDownView()
        }
    }
    
    func connectingUI(isRinging: Bool) async {
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.numberLabel.text = strongSelf.fcsdkCallViewModel?.call?.remoteAddress
            strongSelf.numberLabel.font = .boldSystemFont(ofSize: 18)
            if isRinging {
            strongSelf.nameLabel.text = "Ringing..."
            } else {
            strongSelf.nameLabel.text = "FCSDK iOS Connecting..."
            }
            strongSelf.nameLabel.font = .systemFont(ofSize: 16)
            strongSelf.view.addSubview(strongSelf.stackView)
            strongSelf.stackView.addArrangedSubview(strongSelf.numberLabel)
            strongSelf.stackView.addArrangedSubview(strongSelf.nameLabel)
            strongSelf.stackView.axis = .vertical
            strongSelf.stackView.anchors(top: strongSelf.view.topAnchor, leading: strongSelf.view.leadingAnchor, bottom: nil, trailing: strongSelf.view.trailingAnchor, paddingTop: 50, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        }
    }
    
    func removeConnectingUI() async {
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.stackView.removeFromSuperview()
        }
    }
    
    func setupUI() async {
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.view.addSubview(strongSelf.remoteView)
            strongSelf.remoteView.addSubview(strongSelf.previewView)
        }
    }
    
    func setupPiP() {
        
        AVPictureInPictureController.isPictureInPictureSupported()
        
        let pipContentSource = AVPictureInPictureController.ContentSource(
            activeVideoCallSourceView: self.remoteView,
            contentViewController: self)
        
        let pipController = AVPictureInPictureController(contentSource: pipContentSource)
        pipController.canStartPictureInPictureAutomaticallyFromInline = true
        pipController.delegate = self
        pipController.startPictureInPicture()
        
    }
    //    2021-10-11 09:14:19.418617+0800 SwiftFCSDKSample[5751:2158591] [Common] -[PGPictureInPictureProxy (0x10321a720) _updateAutoPIPSettingsAndNotifyRemoteObjectWithReason:] - Acquiring remote object proxy for connection <NSXPCConnection: 0x2820dcdc0> connection to service with pid 64 named com.apple.pegasus failed with error: Error Domain=NSCocoaErrorDomain Code=4099 "The connection to service with pid 64 named com.apple.pegasus was invalidated from this process." UserInfo={NSDebugDescription=The connection to service with pid 64 named com.apple.pegasus was invalidated from this process.}
    
    func gestures() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(draggedLocalView(_:)))
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapLocalView(_:)))
        self.previewView.addGestureRecognizer(tapGesture)
        self.previewView.isUserInteractionEnabled = true
        self.previewView.addGestureRecognizer(panGesture)
    }
    
    func anchors() async {
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.remoteView.anchors(top: strongSelf.view.topAnchor, leading: strongSelf.view.leadingAnchor, bottom: strongSelf.view.bottomAnchor, trailing: strongSelf.view.trailingAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
            strongSelf.previewView.anchors(top: nil, leading: nil, bottom: strongSelf.remoteView.bottomAnchor, trailing: strongSelf.remoteView.trailingAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 90, paddingRight: 30, width: strongSelf.view.frame.width / 2, height: strongSelf.view.frame.height / 3)
            strongSelf.previewView.sampleBufferDisplayLayer?.videoGravity = .resizeAspectFill
            strongSelf.previewView.sampleBufferDisplayLayer?.frame = strongSelf.previewView.bounds
            strongSelf.previewView.sampleBufferDisplayLayer?.masksToBounds = true
            strongSelf.previewView.sampleBufferDisplayLayer?.cornerRadius = 8
        }
    }
        
    
    func breakDownView() {
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.remoteView.removeFromSuperview()
            strongSelf.previewView.removeFromSuperview()
        }
    }
    
    func onHoldView() {
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.blurEffectView = UIVisualEffectView(effect: strongSelf.blurEffect)
            strongSelf.blurEffectView?.frame = strongSelf.view.bounds
            strongSelf.blurEffectView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            strongSelf.view.addSubview(strongSelf.blurEffectView!)
            strongSelf.fcsdkCallViewModel?.call?.hold()
        }
    }
    
    func removeOnHold() {
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.blurEffectView?.removeFromSuperview()
            strongSelf.fcsdkCallViewModel?.call?.resume()
        }
    }
    
    // Gestures
    @objc func draggedLocalView(_ sender:UIPanGestureRecognizer){
        self.view.bringSubviewToFront(previewView)
        let translation = sender.translation(in: self.view)
        previewView.center = CGPoint(x: previewView.center.x + translation.x, y: previewView.center.y + translation.y)
        sender.setTranslation(CGPoint.zero, in: self.view)
    }
    
    @objc func tapLocalView(_ sender: UITapGestureRecognizer) {
        self.currentCamera = self.currentCamera == .back ?.front : .back
        self.fcsdkCallViewModel?.acbuc.clientPhone?.setCamera(self.currentCamera)
    }
    
    func showPip(show: Bool) {
        setupPiP()
    }
    
    
    @MainActor func configureVideo() async {
        
        self.audioAllowed = AppSettings.perferredAudioDirection() == .receiveOnly || AppSettings.perferredAudioDirection() == .sendAndReceive
        self.videoAllowed = AppSettings.perferredVideoDirection() == .receiveOnly || AppSettings.perferredVideoDirection() == .sendAndReceive
        
        try? self.configureResolutionOptions()
        try? self.configureFramerateOptions()
        
        self.currentCamera = .front
    }
    
    /// Configurations for Capture
    func configureResolutionOptions() throws {
        var show720Res = false
        var show480Res = false
        guard let recCaptureSettings = self.acbuc.clientPhone?.recommendedCaptureSettings() else { throw OurErrors.nilResolution }
        
        for captureSetting in recCaptureSettings {
            guard let captureSetting = captureSetting as? ACBVideoCaptureSetting else {
                continue
            }
            if captureSetting.resolution == .resolution1280x720 {
                show720Res = true
                show480Res = true
            } else if captureSetting.resolution == .resolution640x480 {
                show480Res = true
            }
        }
        
        if !show720Res {
            // Pass value back to swiftUI Settings Sheet
            //            resolutionControl.setEnabled(false, forSegmentAt: 3)
        }
        if !show480Res {
            // Pass value back to swiftUI Settings Sheet
            //            resolutionControl.setEnabled(false, forSegmentAt: 2)
        }
    }
    
    
    
    
    func configureFramerateOptions() throws {
        //disable 30fps unless one of the recommended settings allows it
        
        // Pass value back to swiftUI Settings Sheet
        //        framerateControl.setEnabled(false, forSegmentAt: 1)
        //        framerateControl.selectedSegmentIndex = 0
        guard let recCaptureSettings = acbuc.clientPhone?.recommendedCaptureSettings() else { throw OurErrors.nilFrameRate }
        for captureSetting in recCaptureSettings {
            guard let captureSetting = captureSetting as? ACBVideoCaptureSetting else {
                continue
            }
            if captureSetting.frameRate > 20 {
                
                // Pass value back to swiftUI Settings Sheet
                //                framerateControl.setEnabled(true, forSegmentAt: 1)
                //                framerateControl.selectedSegmentIndex = 1
                break
            }
        }
    }
    
}
