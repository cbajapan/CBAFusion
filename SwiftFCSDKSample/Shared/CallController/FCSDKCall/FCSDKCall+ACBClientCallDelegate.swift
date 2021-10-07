//
//  FCSDKCall+ACBCallDelegate.swift
//  SwiftFCSDKSample
//
//  Created by Cole M on 10/4/21.
//

import Foundation
import SwiftFCSDK
import AVFoundation

extension FCSDKCall: ACBClientCallDelegate {
    
    func playRingtone() {
        let path  = Bundle.main.path(forResource: "ringring", ofType: ".wav")
        let fileURL = URL(fileURLWithPath: path!)
        
        self.audioPlayer = try? AVAudioPlayer(contentsOf: fileURL)
        self.audioPlayer?.volume = 1.0
        self.audioPlayer?.numberOfLoops = -1
        self.audioPlayer?.prepareToPlay()
        self.audioPlayer?.play()
    }
    
    func stopRingtone() {
        guard let player = self.audioPlayer else { return }
        player.stop()
    }
    
    
    func call(_ call: ACBClientCall?, didChange status: ACBClientCallStatus) {
        switch status {
        case .setup:
          break
        case .alerting:
            break
        case .ringing:
            self.playRingtone()
        case .mediaPending:
            break
        case .inCall:
            stopRingtone()
            hasConnected = true
            _ = duration
        case .timedOut:
            if call == self.lastIncomingCall {
                self.lastIncomingCall = nil
                self.stopRingtone()
            }
            if self.callIdentifier != nil {
                self.call?.end()
                self.lastIncomingCall?.end()
            }
            self.callIdentifier = nil
        case .busy:
            if call == self.lastIncomingCall {
                self.lastIncomingCall = nil
                self.stopRingtone()
            }
            if self.callIdentifier != nil {
                self.call?.end()
                self.lastIncomingCall?.end()
            }
            self.callIdentifier = nil
        case .notFound:
            break
        case .error:
            break
        case .ended:
            if call == self.lastIncomingCall {
                self.lastIncomingCall = nil
                self.stopRingtone()
            }
            if self.callIdentifier != nil {
                self.call?.end()
                self.lastIncomingCall?.end()
            }
            self.callIdentifier = nil
            hasEnded = true
        }
    }
    
    func call(_ call: ACBClientCall?, didReceiveSessionInterruption message: String?) {
        if message == "Session interrupted" {
            if self.call != nil {
                if self.call?.callStatusMachine?.state == .inCall {
                    if !self.isOnHold {
                        self.call?.hold()
                        self.isOnHold = true
                        //TODO: - Reflect in UI and perform action
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
