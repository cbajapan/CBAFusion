//
//  ProviderDelegate+Extension.swift
//  CBAFusion
//
//  Created by Cole M on 10/4/21.
//

import Foundation
@preconcurrency import CallKit
import AVFoundation
import FCSDKiOS
import SwiftUI

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
                do {
                    var fcsdkCall = fcsdkCall
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
    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        self.logger.info("Answer call action")
        Task {
            await self.fcsdkCallService.answerFCSDKCall()
            print("Answer Action Fullfilled")
        }
        action.fulfill()
    }
    
    //Start Call
    
    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        self.logger.info("Start call action")
        startCall { result in
            switch result {
            case .success(let packet):
                provider.reportCall(with: packet.id, updated: packet.updated)
            case .failure(let error):
                self.logger.error("\(error)")
                action.fail()
            }
            return provider
        } completion: { result in
            switch result {
            case .success(_):
                action.fulfill()
            case .failure(let error):
                self.logger.error("\(error)")
                action.fail()
            }
        }
    }
    
    struct ReportCall: Sendable {
        var id: UUID
        var updated: CXCallUpdate
    }
    
    func startCall(reportCall: @Sendable @escaping (Result<ReportCall, Error>) -> CXProvider, completion: @Sendable @escaping (Result<Void, Error>) -> Void) {
        Task { [weak self] in
            guard let self else { return }
            var acbCall: ACBClientCall?
            do {
                let callUpdate = CXCallUpdate()
                callUpdate.supportsDTMF = true
                callUpdate.hasVideo = await fcsdkCallService.hasVideo
                callUpdate.supportsHolding = false
                
                guard var outgoingFCSDKCall = await self.fcsdkCallService.fcsdkCall else { return }
                await self.fcsdkCallService.startCall(previewView: outgoingFCSDKCall.communicationView?.previewView)
                acbCall = try await self.fcsdkCallService.initializeFCSDKCall()
                outgoingFCSDKCall.call = acbCall
                let provider = reportCall(.success(ReportCall(id: outgoingFCSDKCall.id, updated: callUpdate)))
                
                await self.fcsdkCallService.hasStartedConnectingDidChange(provider: provider,
                                                                          id: outgoingFCSDKCall.id,
                                                                          date: self.fcsdkCallService.connectingDate ?? Date())
                await self.fcsdkCallService.hasConnectedDidChange(provider: provider,
                                                                  id: outgoingFCSDKCall.id,
                                                                  date: self.fcsdkCallService.connectDate ?? Date())
                await self.fcsdkCallService.addCall(fcsdkCall: outgoingFCSDKCall)
                //We need to set the delegate initially because if the user is on another call we need to get notified through the delegate and end the call
                completion(.success(()))
            } catch {
                self.logger.error("\(error)")
                completion(.failure(OurErrors.noActiveCalls))
            }
        }
        
    }
    
    //Hold Call
    //TODO: - We want to keep track of which call we have and set it to an on hold state. Let's make it happen
    func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction) {
        print("Action", action)
        print("Provider", provider)
    }
    
    //End Call
    //TODO: - When we end the call we want to check if we have any calls on hold if it is on hold then resume the call. We also want to make sure the correct call is ended while handling multiple calls.
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        endCall { result in
            switch result {
            case .success:
                print("Call ended successfully.")
                action.fulfill()
            case .failure(let error):
                print("Error ending call: \(error)")
                action.fail()
            }
        }
    }
    
    func endCall(completion: @Sendable @escaping (Result<Void, Error>) -> Void) {
        Task {
            do {
                if var call = await self.fcsdkCallService.fcsdkCall {
                    if await fcsdkCallService.hasConnected == false && call.outbound == false {
                        call.missed = false
                        call.outbound = false
                        call.rejected = true
                    }
                    
                    // Attempt to end the call
                    try await self.fcsdkCallService.endFCSDKCall(call)
                    await fcsdkCallService.stopAudioSession()
                    
                    // If successful, call the completion handler with success
                    completion(.success(()))
                } else {
                    // If there is no active call, call the completion handler with an error
                    completion(.failure(OurErrors.noActiveCalls))
                }
            } catch {
                // If an error occurs, call the completion handler with the error
                completion(.failure(error))
            }
        }
    }
    
    
    //DTMF
    func provider(_ provider: CXProvider, perform action: CXPlayDTMFCallAction) {
        let digits = action.digits
        Task { [weak self] in
            guard let self else { return }
            self.logger.info("Provider - CXPlayDTMFCallAction")
            let dtmfDigits:String = digits
            await self.fcsdkCallService.fcsdkCall?.call?.playDTMFCode(dtmfDigits, localPlayback: true)
        }
        action.fulfill()
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

