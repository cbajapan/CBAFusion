//
//  CommunicationViewConroller.swift
//  SwiftFCSDKSample
//
//  Created by Cole M on 9/1/21.
//

import Foundation
import UIKit
import FCSDKiOS
import AVKit


enum CallState {
    case hasStartedConnecting
    case isRinging
    case hasConnected
    case isOutgoing
    case hold
    case resume
    case hasEnded
}

//internal var activeCustomPlayerViewControllers = Set<CommunicationViewController>()

class CommunicationViewController:  UIViewController {
    //Only needed for PiP
    //    AVPictureInPictureVideoCallViewController
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
    var fcsdkCall: FCSDKCall?
    var audioAllowed: Bool = false
    var videoAllowed: Bool = false
    var currentCamera: AVCaptureDevice.Position!
    var destination: String
    var hasVideo: Bool
    var isOutgoing: Bool
    
    
    init(
        callKitManager: CallKitManager,
        destination: String,
        hasVideo: Bool,
        acbuc: ACBUC,
        isOutgoing: Bool
    ) {
        self.callKitManager = callKitManager
        self.destination = destination
        self.hasVideo = hasVideo
        self.acbuc = acbuc
        self.isOutgoing = isOutgoing
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        preferredContentSize = CGSize(width: 1080, height: 1920)
        Task {
            await self.configureVideo()
            if self.isOutgoing {
                await self.initiateCall()
            } else {
                await self.fcsdkCallDelegate?.passViewsToService(preview: self.previewView, remoteView: self.remoteView)
            }
            self.gestures()
        }
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
                self.view.layoutIfNeeded()
            }
        case .isOutgoing:
            break
        case .hold:
            self.onHoldView()
        case .resume:
            self.removeOnHold()
        case .hasEnded:
            Task {
                await self.breakDownView()
            }
        }
    }
    
    
    func initiateCall() async {
        let fcsdkCallViewModel = FCSDKCallViewModel(fcsdkCall: FCSDKCall(handle: self.destination, hasVideo: true, previewView: self.previewView, remoteView: self.remoteView, uuid: UUID(), acbuc: self.acbuc))
        await self.fcsdkCallDelegate?.passCallToService(fcsdkCallViewModel.fcsdkCall)
        await self.callKitManager.initializeCall(fcsdkCallViewModel.fcsdkCall)
    }
    
    func endCall() {
        guard let currentCall = self.callKitManager.calls.last else { return }
        self.callKitManager.finishEnd(call: currentCall)
    }
    
    func muteVideo(isMute: Bool) {
        guard let currentCall = self.callKitManager.calls.last else { return }
        if isMute {
            currentCall.call?.enableLocalVideo(false)
        } else {
            currentCall.call?.enableLocalVideo(true)
        }
    }
    
    func muteAudio(isMute: Bool) {
        guard let currentCall = self.callKitManager.calls.last else { return }
        if isMute {
            currentCall.call?.enableLocalAudio(false)
        } else {
            currentCall.call?.enableLocalAudio(true)
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
    
    //    func setupPiP() {
    //
    //        AVPictureInPictureController.isPictureInPictureSupported()
    //
    //        let pipContentSource = AVPictureInPictureController.ContentSource(
    //            activeVideoCallSourceView: self.remoteView,
    //            contentViewController: self)
    //
    //        let pipController = AVPictureInPictureController(contentSource: pipContentSource)
    //        pipController.canStartPictureInPictureAutomaticallyFromInline = true
    //        pipController.delegate = self
    //        pipController.startPictureInPicture()
    //
    //    }
    //    2021-10-11 09:14:19.418617+0800 SwiftFCSDKSample[5751:2158591] [Common] -[PGPictureInPictureProxy (0x10321a720) _updateAutoPIPSettingsAndNotifyRemoteObjectWithReason:] - Acquiring remote object proxy for connection <NSXPCConnection: 0x2820dcdc0> connection to service with pid 64 named com.apple.pegasus failed with error: Error Domain=NSCocoaErrorDomain Code=4099 "The connection to service with pid 64 named com.apple.pegasus was invalidated from this process." UserInfo={NSDebugDescription=The connection to service with pid 64 named com.apple.pegasus was invalidated from this process.}
    
    func gestures() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(draggedLocalView(_:)))
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapLocalView(_:)))
        self.previewView.addGestureRecognizer(tapGesture)
        self.previewView.isUserInteractionEnabled = true
        self.previewView.addGestureRecognizer(panGesture)
    }
    
    //PiP Anchors with custom UI Stuff
    func anchors() async {
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }
            
            strongSelf.remoteView.anchors(top: strongSelf.view.topAnchor, leading: strongSelf.view.leadingAnchor, bottom: strongSelf.view.bottomAnchor, trailing: strongSelf.view.trailingAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
            
            if UIDevice.current.userInterfaceIdiom == .phone {
                
                let viewHeight = strongSelf.view.frame.height
                let viewWidth = strongSelf.view.frame.width
                var height: CGFloat = 0.0
                var width: CGFloat = 0.0
                
                switch UIDevice.current.orientation{
                case .landscapeLeft:
                    width = viewWidth / 2
                    height = viewHeight / 3
                case .portrait:
                    width = viewWidth / 2
                    height = viewHeight / 3
                case .landscapeRight:
                    width = viewWidth / 2
                    height = viewHeight / 3
                default:
                    break
                }
                strongSelf.previewView.anchors(top: nil, leading: nil, bottom: strongSelf.remoteView.bottomAnchor, trailing: strongSelf.remoteView.trailingAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 90, paddingRight: 30, width: width, height: height)
                
            } else {
                
                let viewHeight = strongSelf.view.frame.height
                let viewWidth = strongSelf.view.frame.width
                var height: CGFloat = 0.0
                var width: CGFloat = 0.0
                
                switch UIDevice.current.orientation{
                case .landscapeLeft:
                    width = viewWidth / 4
                    height = viewHeight / 2
                case .portrait:
                    width = viewWidth / 4
                    height = viewHeight / 2
                case .landscapeRight:
                    width = viewWidth / 4
                    height = viewHeight / 2
                default:
                    break
                }
                strongSelf.previewView.anchors(top: nil, leading: nil, bottom: strongSelf.remoteView.bottomAnchor, trailing: strongSelf.remoteView.trailingAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 90, paddingRight: 30, width: width, height: height)
            }
            
            //Not needed for video display just some custom UI Stuff
            strongSelf.previewView.samplePreviewDisplayLayer?.videoGravity = .resizeAspectFill
            strongSelf.previewView.samplePreviewDisplayLayer?.frame = strongSelf.previewView.bounds
            strongSelf.previewView.samplePreviewDisplayLayer?.masksToBounds = true
            strongSelf.previewView.samplePreviewDisplayLayer?.cornerRadius = 8
            strongSelf.view.layoutIfNeeded()
        }
    }
    
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        Task {
            await anchors()
        }
    }
    
    func breakDownView() async {
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.remoteView.removeFromSuperview()
            strongSelf.remoteView.layoutIfNeeded()
            strongSelf.previewView.removeFromSuperview()
            strongSelf.previewView.layoutIfNeeded()
        }
    }
    
    func onHoldView() {
        guard let currentCall = self.callKitManager.calls.last else { return }
        currentCall.call?.hold()
        Task {
            await breakDownView()
        }
    }
    
    func removeOnHold() {
        guard let currentCall = self.callKitManager.calls.last else { return }
        currentCall.call?.resume()
        Task {
            await setupUI()
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
        self.fcsdkCallViewModel?.acbuc.clientPhone.setCamera(self.currentCamera)
    }
    
    //    func showPip(show: Bool) {
    //        setupPiP()
    //    }
    
    
    @MainActor func configureVideo() async {
        
        self.audioAllowed = AppSettings.perferredAudioDirection() == .receiveOnly || AppSettings.perferredAudioDirection() == .sendAndReceive
        self.videoAllowed = AppSettings.perferredVideoDirection() == .receiveOnly || AppSettings.perferredVideoDirection() == .sendAndReceive
        
        try? self.configureResolutionOptions()
        try? self.configureFramerateOptions()
        
        self.currentCamera = .front
    }
    
    /// Configurations for Capture
    func configureResolutionOptions() throws {
        let res = self.acbuc.clientPhone.recommendedCaptureSettings()
        res?.forEach({ r in
            print("Resolution: \(String(describing: r.description))")
        })
    }
    
    
    
    
    func configureFramerateOptions() throws {
        let frameRate = acbuc.clientPhone.recommendedCaptureSettings()
        print("FrameRate: \(String(describing: frameRate))")
    }
}
