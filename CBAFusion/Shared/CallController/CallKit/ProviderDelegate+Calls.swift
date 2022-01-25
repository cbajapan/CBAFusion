//
//  callKitController+Call.swift
//  CBAFusion
//
//  Created by Cole M on 10/4/21.
//

import Foundation
import CallKit
import AVFoundation
import FCSDKiOS


extension ProviderDelegate {
    
    func reportIncomingCall(fcsdkCall: FCSDKCall) async {
        await MainActor.run {
            if self.authenticationService.showSettingsSheet {
                self.authenticationService.showSettingsSheet = false
            }
        }
        do {
            let update = CXCallUpdate()
            update.remoteHandle = CXHandle(type: .phoneNumber, value: fcsdkCall.handle)
            update.hasVideo = fcsdkCall.hasVideo
            update.supportsDTMF = true
            update.supportsHolding = false
            try await provider?.reportNewIncomingCall(with: fcsdkCall.id, update: update)
            await MainActor.run {
                self.fcsdkCallService.presentCommunication = true
            }
        } catch {
            let errorCode = (error as NSError).code
            
            //This error code means do no disturb is on
            if errorCode == 3 {
                await MainActor.run {
                    if !self.fcsdkCallService.doNotDisturb {
                        self.fcsdkCallService.doNotDisturb = true
                    }
                }
                fcsdkCall.activeCall = false
                await self.fcsdkCallService.contactService?.editCall(call: fcsdkCall)
            }
            self.logger.error("There was an error in \(#function) - Error: \(error.localizedDescription)")
        }
    }
    
    
    //    Answer Call after we get notified that we have an incoming call
    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        self.logger.info("Answer call action")
        Task {
            try await self.fcsdkCallService.answerFCSDKCall()
        }
        action.fulfill()
    }
    
    
    //Start Call
    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        self.logger.info("Start call action")
        Task {
            var acbCall: ACBClientCall?
            do {
                let callUpdate = CXCallUpdate()
                callUpdate.supportsDTMF = true
                callUpdate.hasVideo = fcsdkCallService.hasVideo
                callUpdate.supportsHolding = false
                
                guard let outgoingFCSDKCall = self.fcsdkCallService.currentCall else { return }
                guard let preview = outgoingFCSDKCall.previewView else { return }
                try await self.fcsdkCallService.initializeCall(previewView: preview)
                acbCall = try await self.fcsdkCallService.startFCSDKCall()
                outgoingFCSDKCall.call = acbCall

                provider.reportCall(with: outgoingFCSDKCall.id, updated: callUpdate)
                
                await self.fcsdkCallService.hasStartedConnectingDidChange(provider: provider,
                                                                          id: outgoingFCSDKCall.id,
                                                                          date: self.fcsdkCallService.connectingDate ?? Date())
                await self.fcsdkCallService.hasConnectedDidChange(provider: provider,
                                                                  id: outgoingFCSDKCall.id,
                                                                  date: self.fcsdkCallService.connectDate ?? Date())
                await self.fcsdkCallService.addCall(call: outgoingFCSDKCall)
                action.fulfill()
            } catch {
                self.logger.error("\(error)")
                action.fail()
            }
        }
    }
    
    
    //End Call
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        Task {
            let call = try await self.fcsdkCallService.contactService?.fetchActiveCall()
            if self.fcsdkCallService.currentCall != nil, call?.activeCall == false {
                guard let call = self.fcsdkCallService.currentCall else { return }
                call.missed = false
                call.outbound = false
                call.activeCall = false
                call.rejected = true
                await self.fcsdkCallService.contactService?.editCall(call: call)
                do {
                    try await self.fcsdkCallService.endACBClientCall()
                } catch {
                    self.logger.error("\(error)")
                }
            } else {
                await asyncEnd()
            }
            action.fulfill()
        }
    }
    
    func asyncEnd() async {
        do {
            try await self.fcsdkCallService.endFCSDKCall()
        } catch {
            self.logger.error("\(error)")
        }
    }
    
    //DTMF
    func provider(_ provider: CXProvider, perform action: CXPlayDTMFCallAction) {
        self.logger.info("Provider - CXPlayDTMFCallAction")
        let dtmfDigits:String = action.digits
        self.fcsdkCallService.currentCall?.call?.playDTMFCode(dtmfDigits, localPlayback: true)
        action.fulfill()
    }
    
    //Provider Began
    func providerDidBegin(_ provider: CXProvider) {
        self.logger.info("Provider began")
    }
    
    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        self.logger.info("DID_ACTIVATE_AUDIO_SESSION \(#function) with \(audioSession)")
        self.logger.info("\(audioSession.sampleRate)")
    }
    
    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        self.logger.info("DID_DEACTIVATE_AUDIO_SESSION \(#function) with \(audioSession)")
    }
    
    
    // Here we can reset the provider to remove any stale callkit calls
    func providerDidReset(_ provider: CXProvider) {
        self.logger.info("Provider did reset")
    }
    
    
}
