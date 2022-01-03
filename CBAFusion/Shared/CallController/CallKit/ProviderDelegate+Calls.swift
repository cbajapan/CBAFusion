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
                try await provider?.reportNewIncomingCall(with: fcsdkCall.uuid, update: update)
            
            await self.fcsdkCallService.presentCommunicationSheet()
            await self.callKitManager.addCall(call: fcsdkCall)
        } catch {
            let errorCode = (error as NSError).code
            
            //This error code means do no disturb is on
            if errorCode == 3 {
                await MainActor.run {
                    if !self.fcsdkCallService.doNotDisturb {
                        self.fcsdkCallService.doNotDisturb = true
                    }
                }
            }
            print("There was an error in \(#function) - Error: \(error.localizedDescription)")
        }
    }
    
    
    //    Answer Call after we get notified that we have an incoming call
    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        print("answer call action")
                Task {
                await self.fcsdkCallService.startAudioSession()
                try await self.fcsdkCallService.answerFCSDKCall()
                }
                action.fulfill()
        }
    
    
    
    
    //Start Call
    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        print("start call action")
        Task {
            var acbCall: ACBClientCall?
            do {
                let callUpdate = CXCallUpdate()
                callUpdate.supportsDTMF = true
                callUpdate.hasVideo = fcsdkCallService.hasVideo
                callUpdate.supportsHolding = false
                
                self.outgoingFCSDKCall = self.fcsdkCallService.fcsdkCall
                guard let outgoingFCSDKCall = outgoingFCSDKCall else { return }
                guard let preview = outgoingFCSDKCall.previewView else { return }
                try await self.fcsdkCallService.initializeCall(previewView: preview)
                acbCall = try await self.fcsdkCallService.startFCSDKCall()
                outgoingFCSDKCall.call = acbCall
                provider.reportCall(with: outgoingFCSDKCall.uuid, updated: callUpdate)
                
                await self.fcsdkCallService.hasStartedConnectingDidChange(provider: provider,
                                                                          id: outgoingFCSDKCall.uuid,
                                                                          date: self.fcsdkCallService.connectingDate ?? Date())
                await self.fcsdkCallService.hasConnectedDidChange(provider: provider,
                                                                  id: outgoingFCSDKCall.uuid,
                                                                  date: self.fcsdkCallService.connectDate ?? Date())
                action.fulfill()
            } catch {
                print("\(OurErrors.nilACBUC.rawValue)")
                action.fail()
            }
            
            guard let oc = outgoingFCSDKCall else { return }
            await self.callKitManager.addCall(call: oc)
        }
    }
    
    //    func provider(_ provider: CXProvider, execute transaction: CXTransaction) -> Bool {
    //        
    //    }
    
    
    //End Call
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        Task {
            await self.fcsdkCallService.stopAudioSession()
            await asyncEnd()
        }
        action.fulfill()
    }
    
    func asyncEnd() async {
        // Retrieve the FCSDKCall instance corresponding to the action's call UUID
        await self.fcsdkCallService.endFCSDKCall()
        await callKitManager.removeAllCalls()
    }
    
    //DTMF
    func provider(_ provider: CXProvider, perform action: CXPlayDTMFCallAction) {
        print("Provider - CXPlayDTMFCallAction")
        let dtmfDigits:String = action.digits
        self.fcsdkCallService.fcsdkCall?.call?.playDTMFCode(dtmfDigits, localPlayback: true)
        action.fulfill()
    }
    
    //Provider Began
    func providerDidBegin(_ provider: CXProvider) {
        print("Provider began")
    }
    
    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        print("DID_ACTIVATE_AUDIO_SESSION \(#function) with \(audioSession)")
        print(audioSession.sampleRate)
    }
    
    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        print("DID_DEACTIVATE_AUDIO_SESSION \(#function) with \(audioSession)")
    }
    
    
    // Here we can reset the provider to remove any stale callkit calls
    func providerDidReset(_ provider: CXProvider) {
        print("Provider did reset")
    }
    
    
}
