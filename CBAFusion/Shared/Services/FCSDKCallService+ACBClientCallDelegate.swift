//
//  FCSDKCall+ACBCallDelegate.swift
//  CBAFusion
//
//  Created by Cole M on 10/4/21.
//

import Foundation
import FCSDKiOS
import AVFoundation

extension FCSDKCallService: ACBClientCallDelegate {
    
    @MainActor private func endCall() async {
        self.hasEnded = true
    }
    
    func call(_ call: ACBClientCall?, didChange status: ACBClientCallStatus) {
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
                await self.playRingtone()
            }
        case .mediaPending:
            break
        case .inCall:
            Task {
                await self.stopRingtone()
                await self.inCall()
            }
        case .timedOut:
            Task {
                await setErrorMessage(message: "Call timed out")
                await self.stopRingtone()
            }
        case .busy:
            Task {
                await setErrorMessage(message: "User is Busy")
                await self.stopRingtone()
            }
        case .notFound:
            Task {
                await setErrorMessage(message: "Could not find user")
                await self.stopRingtone()
            }
        case .error:
            Task {
                await setErrorMessage(message: "Unkown Error")
                await self.stopRingtone()
            }
        case .ended:
            Task {
                await self.endCall()
                await self.stopRingtone()
            }
        @unknown default:
            break
        }
    }
    
    @MainActor func alerting() async {
        self.hasStartedConnecting = true
    }
    
    @MainActor func inCall() async {
        self.isRinging = false
        self.hasConnected = true
        self.connectDate = Date()
    }
    
    @MainActor func ringing() async {
        self.hasStartedConnecting = false
        self.connectingDate = Date()
        self.isRinging = true
    }
    
    @MainActor func setErrorMessage(message: String) async {
        self.sendErrorMessage = true
        self.errorMessage = message
    }
    
    func call(_ call: ACBClientCall?, didReceiveSessionInterruption message: String?) {
        if message == "Session interrupted" {
            if  self.fcsdkCall?.call != nil {
                if  self.fcsdkCall?.call?.currentState == ACBClientCallStatus.inCall.rawValue {
                    if !self.isOnHold {
                        call?.hold()
                        self.isOnHold = true
                    }
                }
            }
        }
    }
    
    func call(_ call: ACBClientCall?, didReceiveCallFailureWithError error: Error?) throws {
        self.sendErrorMessage = true
        self.errorMessage = error?.localizedDescription ?? "didReceiveCallFailureWithError Error"
    }
    
    func call(_ call: ACBClientCall?, didReceiveDialFailureWithError error: Error?) {
        self.sendErrorMessage = true
        self.errorMessage = error?.localizedDescription ?? "didReceiveDialFailureWithError Error"
    }
    
    func call(_ call: ACBClientCall?, didReceiveCallRecordingPermissionFailure message: String?) {
        self.sendErrorMessage = true
        self.errorMessage = message ?? "didReceiveCallRecordingPermissionFailure Error"
    }
    
    func call(_ call: ACBClientCall?, didReceiveSSRCsForAudio audioSSRCs: [AnyHashable]?, andVideo videoSSRCs: [AnyHashable]?) {
        guard let audio = audioSSRCs else {return}
        guard let video = videoSSRCs else {return}
        print("Received SSRC information for AUDIO \(audio) and VIDEO \(video)")
    }
    
    func call(_ call: ACBClientCall?, didReportInboundQualityChange inboundQuality: Int) {
        //TODO: - Reflect in UI
        print("Call Quality: \(inboundQuality)")
    }
    
    func callDidReceiveMediaChangeRequest(_ call: ACBClientCall?) {
    }
    
    
}
