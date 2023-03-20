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
        self.hasEnded = true
        if isBuffer {
            await fcsdkCall?.call?.removeBufferView()
            await fcsdkCall?.call?.removePreviewView()
        }
    }
    
    @MainActor
    func setupBufferViews() async {
        fcsdkCall?.communicationView?.remoteView = await fcsdkCall?.call?.remoteBufferView()
        fcsdkCall?.communicationView?.previewView = await fcsdkCall?.call?.previewBufferView()
        fcsdkCall?.communicationView?.setupUI()
        fcsdkCall?.communicationView?.updateAnchors(UIDevice.current.orientation)
        fcsdkCall?.communicationView?.captureSession = await fcsdkCall?.call?.captureSession()
        if let backgroundImage = backgroundImage {
            let mode = virtualBackgroundMode
            await fcsdkCall?.call?.feedBackgroundImage(backgroundImage, mode: mode)
        }
    }
    
    @MainActor
    func notifyInCall() async {
        await self.inCall()
        isStreaming = true
    }
    
    
    func didChange(_ status: ACBClientCallStatus, call: ACBClientCall) async {
        switch status {
        case .setup:
           break
        case .preparingBufferViews:
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
            await self.endCall()
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
                        call.hold()
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
    
    func call(_ call: ACBClientCall, didReceiveSSRCsForAudio audioSSRCs: [String], andVideo videoSSRCs: [String]) {
        self.logger.info("Received SSRC information for AUDIO \(audioSSRCs) and VIDEO \(videoSSRCs)")
    }
    
    internal func call(_ call: ACBClientCall, didReportInboundQualityChange inboundQuality: Int) {
        self.logger.info("Call Quality: \(inboundQuality)")
    }
    
    func didReceiveMediaChangeRequest(_ call: ACBClientCall) async {
        let audio = call.hasRemoteAudio
        let video = call.hasRemoteVideo
        self.logger.info("HAS AUDIO \(audio)")
        self.logger.info("HAS VIDEO \(video)")
    }
}



