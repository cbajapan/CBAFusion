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
    var fcsdkCall: FCSDKCall?
    var audioAllowed: Bool = false
    var videoAllowed: Bool = false
    var currentCamera: AVCaptureDevice.Position!
    var destination: String
    var hasVideo: Bool
    var isOutgoing: Bool
    var authenticationService: AuthenticationService?
    
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
    
    deinit{
        print("Deinit VC")
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
            
            guard let rate = FrameRateOptions(rawValue: UserDefaults.standard.string(forKey: "RateOption") ?? "") else { return }
            guard let res = ResolutionOptions(rawValue: UserDefaults.standard.string(forKey: "ResolutionOption") ?? "") else { return }
            guard let audio = AudioOptions(rawValue: UserDefaults.standard.string(forKey: "AudioOption") ?? "") else { return }
            self.authenticationService?.selectFramerate(rate: rate)
            self.authenticationService?.selectResolution(res: res)
            self.authenticationService?.selectAudio(audio: audio)
        }
        self.gestures()
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
            await self.onHoldView()
        case .resume:
            await self.removeOnHold()
        case .hasEnded:
            await self.breakDownView()
            await self.removeConnectingUI()
            await self.currentState(state: .setup)
        case .muteVideo:
            await self.muteVideo(isMute: true)
        case .resumeVideo:
            await self.muteVideo(isMute: false)
        case .muteAudio:
            await self.muteAudio(isMute: true)
        case .resumeAudio:
            await self.muteAudio(isMute: false)
        case .cameraFront:
            await self.tapLocalView(show: true)
        case .cameraBack:
            await self.tapLocalView(show: false)
        }
    }
    
    
    func initiateCall() async {
        let fcsdkCall = FCSDKCall(handle: self.destination, hasVideo: true, previewView: self.previewView, remoteView: self.remoteView, uuid: UUID(), acbuc: self.acbuc)
        await self.fcsdkCallDelegate?.passCallToService(fcsdkCall)
        await self.callKitManager.initializeCall(fcsdkCall)
    }
    
    func endCall() async {
        guard let currentCall = self.callKitManager.calls.last else { return }
        await self.callKitManager.finishEnd(call: currentCall)
    }
    
    @MainActor
    func muteVideo(isMute: Bool) async {
        guard let currentCall = self.callKitManager.calls.last else { return }
        if isMute {
            currentCall.call?.enableLocalVideo(false)
        } else {
            currentCall.call?.enableLocalVideo(true)
        }
    }
    
    @MainActor
    func muteAudio(isMute: Bool) async {
        guard let currentCall = self.callKitManager.calls.last else { return }
        if isMute {
            currentCall.call?.enableLocalAudio(false)
        } else {
            currentCall.call?.enableLocalAudio(true)
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
        self.stackView.anchors(top: self.view.topAnchor, leading: self.view.leadingAnchor, bottom: nil, trailing: self.view.trailingAnchor, paddingTop: 50, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
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
        
        if UIApplication.shared.applicationState != .background {
            //We can change width and height as we wish
            self.remoteView.anchors(top: self.view.topAnchor, leading: self.view.leadingAnchor, bottom: self.view.bottomAnchor, trailing: self.view.trailingAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
            
            if UIDevice.current.userInterfaceIdiom == .phone {
                self.previewView.anchors(top: nil, leading: nil, bottom: self.view.bottomAnchor, trailing: self.view.trailingAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 110, paddingRight: 20, width: 150, height: 200)
                
            } else {
                self.previewView.anchors(top: nil, leading: nil, bottom: self.view.bottomAnchor, trailing: self.view.trailingAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 110, paddingRight: 20, width: 250, height: 200)
            }
            
            //Not needed for video display just some custom UI Stuff
            self.previewView.samplePreviewDisplayLayer?.videoGravity = .resizeAspectFill
            // This will fill the frame, which could distort the video
            self.previewView.samplePreviewDisplayLayer?.frame = self.previewView.bounds
            self.previewView.samplePreviewDisplayLayer?.masksToBounds = true
            self.previewView.samplePreviewDisplayLayer?.cornerRadius = 8
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
    
    
    func onHoldView() async {
        guard let currentCall = self.callKitManager.calls.last else { return }
        currentCall.call?.hold()
        await breakDownView()
    }
    
    func removeOnHold() async {
        guard let currentCall = self.callKitManager.calls.last else { return }
        currentCall.call?.resume()
        await setupUI()
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
