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

/// The Set of custom player controllers currently using or transitioning out of PiP
internal var activeCustomPlayerViewControllers = Set<CommunicationViewController>()

class CommunicationViewController: UIViewController {
    
    weak var delegate: CommunicationViewControllerDelegate?
    var remoteView = SampleBufferVideoCallView()
    var previewView: ACBView = {
        let lv = ACBView()
        lv.layer.cornerRadius = 8
        return lv
    }()
    var callKitManager: CallKitManager
    var acbuc: ACBUC
    var call: FCSDKCall?
    var audioAllowed: Bool = false
    var videoAllowed: Bool = false
    var currentCamera: AVCaptureDevice.Position!
    var destination: String
    var hasVideo: Bool
    
    
    init(
        callKitManager: CallKitManager,
        destination: String,
        hasVideo: Bool,
        acbuc: ACBUC) {
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
        Task {
            await setupUI()
            await anchors()
            await configureVideo()
            await gestures()
            await initiateCall()
        }
    }
    
    func initiateCall() async {
        let call = FCSDKCall(
            handle: self.destination,
            hasVideo: self.hasVideo,
            previewView: self.previewView,
            remoteView: self.remoteView,
            acbuc: self.acbuc,
            uuid: UUID(),
            isOutgoing: true
        )
        await self.callKitManager.initializeCall(call: call)
    }
    
    @objc func setCurrentCall() {
        guard let currentCall = self.callKitManager.calls.last else { return }
        self.call = currentCall
    }
    
    func endCall() async {
        guard let currentCall = self.call else { return }
        await self.callKitManager.finishEnd(call: currentCall)
        await self.callKitManager.removeCall(call: currentCall)
    }
    
    
    func determineState() {
        //            if self.callKitManager.calls.last?.hasStartedConnecting != nil {
        
        //            } else if self.callKitManager.calls.last?.hasConnected != nil {
        //                Text("Connected")
        //            }
        //            else if self.callKitManager.calls.last?.isOutgoing != nil {
        //                Text("Is Outgoing")
        //            }
        //            else if self.callKitManager.calls.last?.isOnHold != nil {
        //                Text("Is on Hold")
        //            }
        //            else if self.callKitManager.calls.last?.hasEnded != nil {
        //                Text("Has Ended")
        //            }
    }
    
    
    @MainActor func setupUI() async {

        //        pipController = AVPictureInPictureController(playerLayer: playerView.sampleBufferDisplayLayer)
        //        pipController.delegate = self
        //        let pipContentSource = AVPictureInPictureController.ContentSource(
        //                                    activeVideoCallSourceView: playerView,
        //                                    contentViewController: pipController)
        
        
        
        //        let pipController = AVPictureInPictureController(contentSource: pipContentSource)
        //        pipController.canStartPictureInPictureAutomaticallyFromInline = true
        //        pipController.delegate = self
        
        
//        previewView.layer.addSublayer(playerView.sampleBufferDisplayLayer)
        
        
//        playerView.sampleBufferDisplayLayer.frame = view.bounds
//        self.view.addSubview(self.previewView)
//        previewView.layer.frame = self.previewView.bounds
//        view.layer.addSublayer(previewView.layer)
        
       
        view.addSubview(remoteView)
        remoteView.addSubview(previewView)
        remoteView.sampleBufferDisplayLayer?.frame = remoteView.bounds
    }

    
    @MainActor func gestures() async {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(draggedLocalView(_:)))
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapLocalView(_:)))
        self.previewView.addGestureRecognizer(tapGesture)
        self.previewView.isUserInteractionEnabled = true
        self.previewView.addGestureRecognizer(panGesture)
    }
    
    @MainActor func anchors() async {
        self.remoteView.anchors(top: view.topAnchor, leading: view.leadingAnchor, bottom: view.bottomAnchor, trailing: view.trailingAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
//        self.remoteView.backgroundColor = .blue
        self.previewView.anchors(top: nil, leading: nil, bottom: remoteView.bottomAnchor, trailing: remoteView.trailingAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 90, paddingRight: 30, width: view.frame.width / 2, height: view.frame.height / 3)
//        self.previewView.backgroundColor = .green
    }
    
    
    // Gestures
    @objc func draggedLocalView(_ sender:UIPanGestureRecognizer){
        self.view.bringSubviewToFront(previewView)
        let translation = sender.translation(in: self.view)
        previewView.center = CGPoint(x: previewView.center.x + translation.x, y: previewView.center.y + translation.y)
        sender.setTranslation(CGPoint.zero, in: self.view)
    }
    
    @objc func tapLocalView(_ sender: UITapGestureRecognizer) {
        self.currentCamera = self.currentCamera == AVCaptureDevice.Position.back ? AVCaptureDevice.Position.front : AVCaptureDevice.Position.back
        self.call?.acbuc?.clientPhone?.setCamera(self.currentCamera)
    }
    
    func showPip(show: Bool) {
        
    }
    
    
    @MainActor func configureVideo() async {
        
        self.audioAllowed = AppSettings.perferredAudioDirection() == .receiveOnly || AppSettings.perferredAudioDirection() == .sendAndReceive
        self.videoAllowed = AppSettings.perferredVideoDirection() == .receiveOnly || AppSettings.perferredVideoDirection() == .sendAndReceive
        
        try? self.configureResolutionOptions()
        try? self.configureFramerateOptions()
        
        
        self.currentCamera = AVCaptureDevice.Position.front
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
