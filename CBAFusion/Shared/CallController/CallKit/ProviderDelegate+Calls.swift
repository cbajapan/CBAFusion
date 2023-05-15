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
import SwiftUI

extension ProviderDelegate {
    
    @MainActor
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
                do {
                    fcsdkCall.activeCall = false
                    try await self.fcsdkCallService.endFCSDKCall(fcsdkCall)
                    
                    await MainActor.run {
                        if !self.fcsdkCallService.doNotDisturb {
                            self.fcsdkCallService.doNotDisturb = true
                        }
                        self.fcsdkCallService.hasEnded = false
                    }
                } catch {
                    self.logger.error("\(error)")
                }
            }
            self.logger.error("There was an error in \(#function) - Error: \(error.localizedDescription)")
        }
    }
    
    
    // Answer Call after we get notified that we have an incoming call
    @MainActor
    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        self.logger.info("Answer call action")
        Task {
            await self.fcsdkCallService.answerFCSDKCall()
            action.fulfill()
            print("Answer Action Fullfilled")
        }
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
                
                guard let outgoingFCSDKCall = self.fcsdkCallService.fcsdkCall else { return }
                await self.fcsdkCallService.startCall(previewView: outgoingFCSDKCall.communicationView?.previewView)
                acbCall = try await self.fcsdkCallService.initializeFCSDKCall()
                outgoingFCSDKCall.call = acbCall
                provider.reportCall(with: outgoingFCSDKCall.id, updated: callUpdate)
                
                await self.fcsdkCallService.hasStartedConnectingDidChange(provider: provider,
                                                                          id: outgoingFCSDKCall.id,
                                                                          date: self.fcsdkCallService.connectingDate ?? Date())
                await self.fcsdkCallService.hasConnectedDidChange(provider: provider,
                                                                  id: outgoingFCSDKCall.id,
                                                                  date: self.fcsdkCallService.connectDate ?? Date())
                await self.fcsdkCallService.addCall(fcsdkCall: outgoingFCSDKCall)
                //We need to set the delegate initially because if the user is on another call we need to get notified through the delegate and end the call
                self.fcsdkCallService.fcsdkCall?.call?.delegate = self.fcsdkCallService
                action.fulfill()
            } catch {
                self.logger.error("\(error)")
                action.fail()
            }
        }
    }
    
    //Hold Call
    //TODO: - We want to keep track of which call we have and set it to an on hold state. Let's make it happen
    func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction) {
        Task {
            print("Action", action)
            print("Provider", provider)
        }
    }

    //End Call
    //TODO: - When we end the call we want to check if we have any calls on hold if it is on hold then resume the call. We also want to make sure the correct call is ended while handling multiple calls.
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        Task {
            // if we are on a call end otherwise also end
            if let call = self.fcsdkCallService.fcsdkCall {
                if fcsdkCallService.hasConnected == false && call.outbound == false {
                    call.missed = false
                    call.outbound = false
                    call.rejected = true
                }
                do {
                    try await self.fcsdkCallService.endFCSDKCall(call)
                    fcsdkCallService.stopAudioSession()
                    action.fulfill()
                } catch {
                    self.logger.error("\(error)")
                    action.fail()
                }
            } else {
                self.logger.info("No Call To End")
                action.fail()
            }
            await MainActor.run {
                self.fcsdkCallService.hasEnded = false
                self.fcsdkCallService.hasConnected = false
                self.fcsdkCallService.isStreaming = false
            }
        }
    }
    //DTMF
    func provider(_ provider: CXProvider, perform action: CXPlayDTMFCallAction) {
        Task {
            self.logger.info("Provider - CXPlayDTMFCallAction")
            let dtmfDigits:String = action.digits
        self.fcsdkCallService.fcsdkCall?.call?.playDTMFCode(dtmfDigits, localPlayback: true)
            action.fulfill()
        }
    }
    
    //Provider Began
    func providerDidBegin(_ provider: CXProvider) {
        self.logger.info("Provider began")
    }

    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        self.logger.info("DID_ACTIVATE_AUDIO_SESSION \(#function) with \(audioSession)")
        self.logger.info("\(audioSession.sampleRate)")
        ACBAudioDeviceManager.activeCallKitAudioSession(audioSession)
    }
    
    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        self.logger.info("DID_DEACTIVATE_AUDIO_SESSION \(#function) with \(audioSession)")
        ACBAudioDeviceManager.deactiveCallKitAudioSession(audioSession)
    }
    
    // Here we can reset the provider to remove any stale callkit calls
    func providerDidReset(_ provider: CXProvider) {
        self.logger.info("Provider did reset")
    }
    
    
}

