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
    }
    
    func didChange(_ status: ACBClientCallStatus, call: ACBClientCall) async {
        switch status {
        case .setup:
            break
        case .alerting:
            Task {
                await self.alerting()
            }
        case .ringing:
            Task {
                await ringing()
            }
        case .mediaPending:
            break
        case .inCall:
            Task {
                await self.inCall()
                await MainActor.run {
                    isStreaming = true
                }
            }
        case .timedOut:
            Task {
                await setErrorMessage(message: "Call timed out")
            }
        case .busy:
            Task {
                await setErrorMessage(message: "User is Busy")
            }
        case .notFound:
            Task {
                await setErrorMessage(message: "Could not find user")
            }
        case .error:
            Task {
                await setErrorMessage(message: "Unkown Error")
            }
        case .ended:
            Task {
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
    
//   @FCSDKTransportActor
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
    
//   @FCSDKTransportActor
    func didReceiveMediaChangeRequest(_ call: ACBClientCall) async {
            let audio = call.hasRemoteAudio
            let video = call.hasRemoteVideo
            self.logger.info("HAS AUDIO \(audio)")
            self.logger.info("HAS VIDEO \(video)")
    }
    
    
}



