//
//  FCSDKCall+ACBCallDelegate.swift
//  CBAFusion
//
//  Created by Cole M on 10/4/21.
//

import Foundation
import FCSDKiOS
import AVFoundation
import UIKit

extension FCSDKCallService: ACBClientCallDelegate {
    
    
    @MainActor private func endCall() async {
        if !endPressed {
            self.hasEnded = true
        }
        if #available(iOS 15.0, *), isBuffer {
                await self.fcsdkCall?.call?.removeBufferView()
                await self.fcsdkCall?.call?.removeLocalBufferView()
                
                fcsdkCall?.communicationView?.remoteView = nil
                fcsdkCall?.communicationView?.previewView = nil
                
            } else {
                // Fallback on earlier versions
            }
        self.endPressed = false
    }
    
    @MainActor
    func setupBufferViews() async {
        let localVideoScale = UserDefaults.standard.integer(forKey: "localVideoScale")
        let remoteVideoScale = UserDefaults.standard.integer(forKey: "remoteVideoScale")
        let scaleWithOrientation = UserDefaults.standard.bool(forKey: "scaleWithOrientation")
        
        fcsdkCall?.communicationView?.remoteView = await fcsdkCall?.call?.remoteBufferView(
            scaleMode: VideoScaleMode(rawValue: remoteVideoScale) ?? .horizontal,
            shouldScaleWithOrientation: scaleWithOrientation
        )
        
        fcsdkCall?.communicationView?.previewView = await fcsdkCall?.call?.localBufferView(
            scaleMode: VideoScaleMode(rawValue: localVideoScale) ?? .horizontal,
            shouldScaleWithOrientation: scaleWithOrientation
        )
        
        if #available(iOS 16, *) {
            let session = await fcsdkCall?.call?.captureSession()
            fcsdkCall?.communicationView?.captureSession = session
        }
        
        if #available(iOS 15, *) {
            await fcsdkCall?.call?.feedBackgroundImage(backgroundImage, mode: virtualBackgroundMode)
        }
        
            fcsdkCall?.communicationView?.setupUI()
            fcsdkCall?.communicationView?.updateAnchors(UIDevice.current.orientation)
            fcsdkCall?.communicationView?.gestures()
    }
    
    @MainActor
    func notifyInCall() async {
        await self.inCall()
        isStreaming = true
    }
    
    func didChange(_ status: ACBClientCallStatus, call: ACBClientCall) async {
        Task { @MainActor [weak self] in
        guard let self else { return }
            self.callStatus = status.rawValue
        }
        switch status {
        case .setup:
            break
        case .preparingBufferViews:
            //Just wait a second if we are answering from callkit for the view
            if #available(iOS 16.0, *) {
                try? await Task.sleep(until: .now + .seconds(1), clock: .suspending)
            } else {
                try? await Task.sleep(nanoseconds: NSEC_PER_SEC)
            }
            if isBuffer {
                await setupBufferViews()
            }
        case .alerting:
            await self.alerting()
        case .ringing:
            await ringing()
        case .mediaPending:
            break
        case .inCall:
            await notifyInCall()
        case .timedOut:
            await setErrorMessage(message: "Call timed out")
        case .busy:
            await setErrorMessage(message: "User is Busy")
        case .notFound:
            await setErrorMessage(message: "Could not find user")
        case .error:
            await setErrorMessage(message: "Unkown Error")
        case .ended:
            Task { @MainActor in
                await self.endCall()
            }
        @unknown default:
            break
        }
    }
    
    @MainActor
    func alerting() async {
        self.hasStartedConnecting = true
    }
    
    @MainActor
    func inCall() async {
        self.isRinging = false
        self.hasConnected = true
        self.connectDate = Date()
    }
    
    @MainActor
    func ringing() async {
        self.hasStartedConnecting = false
        self.connectingDate = Date()
        self.isRinging = true
    }
    
    @MainActor
    func setErrorMessage(message: String) async {
        self.sendErrorMessage = true
        self.errorMessage = message
    }
    
    func didReceiveSessionInterruption(_ message: String, call: ACBClientCall) async {
        if message == "Session interrupted" {
            if  self.fcsdkCall?.call != nil {
                if self.fcsdkCall?.call?.status == .inCall {
                    if !self.isOnHold {
                        await call.hold()
                        self.isOnHold = true
                    }
                }
            }
        }
    }
    
    func didReceiveCallFailure(with error: Error, call: ACBClientCall) async {
        await MainActor.run {
            self.sendErrorMessage = true
            self.errorMessage = error.localizedDescription
        }
    }
    
    
    func didReceiveDialFailure(with error: Error, call: ACBClientCall) async {
        await MainActor.run {
            self.sendErrorMessage = true
            self.errorMessage = error.localizedDescription
        }
    }
    
    func didReceiveCallRecordingPermissionFailure(_ message: String, call: ACBClientCall?) async {
        await MainActor.run {
            self.sendErrorMessage = true
            self.errorMessage = message
        }
    }
    
    func didReceiveSSRCs(for audioSSRCs: [String], andVideo videoSSRCs: [String], call: ACBClientCall) async {
        self.logger.info("Received SSRC information for\n AUDIO \(audioSSRCs)\n VIDEO \(videoSSRCs)")
    }
    
    func didReportInboundQualityChange(_ inboundQuality: Int, with call: ACBClientCall) async {
        self.logger.info("Call Quality: \(inboundQuality)")
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.callQuality = inboundQuality
    }
}
    
    func didReceiveMediaChangeRequest(_ call: ACBClientCall) async {
        let audio = call.hasRemoteAudio
        let video = call.hasRemoteVideo
        self.logger.info("HAS AUDIO \(audio)")
        self.logger.info("HAS VIDEO \(video)")
    }
    func didAddRemoteMediaStream(_ call: ACBClientCall) async {
        print("\(#function)")
    }
    
    func didAddLocalMediaStream(_ call: ACBClientCall) async {
        print("\(#function)")
    }
}
