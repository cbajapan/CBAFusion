//
//  FCSDKCall+ACBCallDelegate.swift
//  SwiftFCSDKSample
//
//  Created by Cole M on 10/4/21.
//

import Foundation
import SwiftFCSDK
import AVFoundation

extension FCSDKCall {
    
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
    
    func stopRingingIfNoOtherCallIsRinging(call: ACBClientCall?) {
        if (self.lastIncomingCall != nil) && (self.lastIncomingCall != call) {
            return
        }
        
        let status = self.call?.status
        if (status == .ringing) || (status == .alerting) {
            return
        }
        
        stopRingtone()
    }
    
    func updateUIForEndedCall(call: ACBClientCall) {
        if call == self.lastIncomingCall {
            self.lastIncomingCall = nil
            //Need Alert View
            //            self.lastIncomingCallAlert
            //Need Local Notification Maybe???
            
            self.stopRingingIfNoOtherCallIsRinging(call: nil)
            self.switchToNotInCallUI()
            
        }
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
            guard let c = call else { return }
            self.stopRingingIfNoOtherCallIsRinging(call: c)
            hasConnected = true
            _ = duration
        case .timedOut:
            guard let c = call else { return }
            self.updateUIForEndedCall(call: c)
            if self.callIdentifier != nil {
                self.call?.end()
                self.lastIncomingCall?.end()
            }
            self.callIdentifier = nil
        case .busy:
            guard let c = call else { return }
            self.updateUIForEndedCall(call: c)
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
            guard let c = call else { return }
            self.updateUIForEndedCall(call: c)
            if self.callIdentifier != nil {
                self.call?.end()
                self.lastIncomingCall?.end()
            }
            self.callIdentifier = nil
            hasEnded = true
        }
    }    
}
