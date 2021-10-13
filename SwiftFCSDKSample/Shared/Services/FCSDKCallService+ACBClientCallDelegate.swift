//
//  FCSDKCall+ACBCallDelegate.swift
//  SwiftFCSDKSample
//
//  Created by Cole M on 10/4/21.
//

import Foundation
import SwiftFCSDK
import AVFoundation

extension FCSDKCallService: ACBClientCallDelegate {
    
    func call(_ call: ACBClientCall?, didChange status: ACBClientCallStatus) {
        switch status {
        case .setup:
            break
        case .alerting:
            DispatchQueue.main.async { [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.hasStartedConnecting = true
            }
        case .ringing:
            DispatchQueue.main.async { [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.hasStartedConnecting = false
                strongSelf.isRinging = true
            }
            self.playRingtone()
        case .mediaPending:
          break
        case .inCall:
            self.stopRingtone()
            DispatchQueue.main.async { [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.isRinging = false
                strongSelf.hasConnected = true
            }
        case .timedOut:
            if call == self.acbCall {
                self.acbCall = nil
            }
            if self.acbCall?.callId != nil {
                self.acbCall?.end()
                self.acbCall?.end()
            }
            self.acbCall?.callId = nil
        case .busy:
            if call == self.acbCall {
                self.acbCall = nil
            }
            if self.acbCall?.callId != nil {
                self.acbCall?.end()
                self.acbCall?.end()
            }
            self.acbCall?.callId = nil
        case .notFound:
            break
        case .error:
            break
        case .ended:
            if call == self.acbCall {
                self.acbCall = nil
            }
            if self.acbCall?.callId != nil {
                self.acbCall?.end()
                self.acbCall?.end()
            }
            self.acbCall?.callId = nil
            hasEnded = true
        }
    }
    
    func call(_ call: ACBClientCall?, didReceiveSessionInterruption message: String?) {
        if message == "Session interrupted" {
            if self.acbCall != nil {
                if self.acbCall?.callStatusMachine?.state == .inCall {
                    if !self.isOnHold {
                        self.acbCall?.hold()
                        self.isOnHold = true
                    }
                }
            }
        }
    }
    
    func call(_ call: ACBClientCall?, didReceiveCallFailureWithError error: Error?) {
        //TODO: - Reflect in UI
    }
    
    func call(_ call: ACBClientCall?, didReceiveDialFailureWithError error: Error?) {
        //TODO: - Reflect in UI
    }
    
    func call(_ call: ACBClientCall?, didReceiveCallRecordingPermissionFailure message: String?) {
        //TODO: - Reflect in UI
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
