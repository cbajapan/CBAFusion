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
    
    func call(_ call: ACBClientCall, didChange status: ACBClientCallStatus) {
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
                if self.audioPlayer != nil {
                    await stopOutgoingRingtone()
                }
                //We get the buffer view from the SDK when the call has been answered. This means we already have the ACBClientCall Object
                ///This method is used to set the remoteView with a BufferView
                self.currentCall?.remoteView = await self.currentCall?.call?.remoteBufferView()
                await self.inCall()
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
    
    func call(_ call: ACBClientCall, didReceiveSessionInterruption message: String) {
        if message == "Session interrupted" {
            if  self.currentCall?.call != nil {
                if  self.currentCall?.call?.status == .inCall {
                    if !self.isOnHold {
                        call.hold()
                        self.isOnHold = true
                    }
                }
            }
        }
    }
    
    func call(_ call: ACBClientCall, didReceiveCallFailureWithError error: Error) {
        Task {
            await MainActor.run {
                self.sendErrorMessage = true
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    
    
    func call(_ call: ACBClientCall, didReceiveDialFailureWithError error: Error) {
        Task {
            await MainActor.run {
                self.sendErrorMessage = true
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func call(_ call: ACBClientCall?, didReceiveCallRecordingPermissionFailure message: String) {
        Task {
            await MainActor.run {
                self.sendErrorMessage = true
                self.errorMessage = message
            }
        }
    }
    
    func call(_ call: ACBClientCall, didReceiveSSRCsForAudio audioSSRCs: [AnyHashable]?, andVideo videoSSRCs: [AnyHashable]?) {
        guard let audio = audioSSRCs else {return}
        guard let video = videoSSRCs else {return}
        self.logger.info("Received SSRC information for AUDIO \(audio) and VIDEO \(video)")
    }
    
    internal func call(_ call: ACBClientCall, didReportInboundQualityChange inboundQuality: Int) {
        self.logger.info("Call Quality: \(inboundQuality)")
    }
    
    func callDidReceiveMediaChangeRequest(_ call: ACBClientCall) {
    }
    
    
}
