//
//  callKitController+Call.swift
//  SwiftFCSDKSample
//
//  Created by Cole M on 10/4/21.
//

import Foundation
import CallKit
import AVFoundation
import FCSDKiOS

extension ProviderDelegate {
    
    func reportIncomingCall(fcsdkCall: FCSDKCall) {
        Task {
            await callKitManager.removeAllCalls()
            
            let update = CXCallUpdate()
            update.remoteHandle = CXHandle(type: .phoneNumber, value: fcsdkCall.handle)
            update.hasVideo = fcsdkCall.hasVideo
            update.supportsDTMF = true
            update.supportsHolding = true
            
            do {
                try await provider?.reportNewIncomingCall(with: fcsdkCall.uuid, update: update)
                await self.fcsdkCallService.presentCommunicationSheet()
                await self.callKitManager.addCall(call: fcsdkCall)
            } catch {
                if error.localizedDescription == "The operation couldn’t be completed. (com.apple.CallKit.error.incomingcall error 3.)" {
                    await MainActor.run {
                        self.fcsdkCallService.doNotDisturb = true
                    }
                }
                print("There was an error in \(#function) - Error: \(error.localizedDescription)")
            }
        }
    }
    
    
    func providerDidReset(_ provider: CXProvider) {
        print("Provider did reset")
    }
    
    //Answer Call after we get notified that we have an incoming call in the push controller
    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        print("answer call action")
        Task {
            do {
                try await self.fcsdkCallService.answerFCSDKCall()
            } catch {
                print("\(OurErrors.nilACBUC.rawValue)")
            }
            action.fulfill()
        }
    }
    
    
    
    //Start Call
    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        print("start call action")
        Task {
            await self.fcsdkCallService.presentCommunicationSheet()
            var acbCall: ACBClientCall?
            do {
                self.outgoingFCSDKCall = self.fcsdkCallService.fcsdkCall
                guard let outgoingFCSDKCall = outgoingFCSDKCall else { return }
                guard let preview = outgoingFCSDKCall.previewView else { return }
                try await self.fcsdkCallService.initializeCall(previewView: preview)
                acbCall = try await self.fcsdkCallService.startFCSDKCall()
                outgoingFCSDKCall.call = acbCall
                
                let callUpdate = CXCallUpdate()
                callUpdate.supportsDTMF = true
                callUpdate.hasVideo = fcsdkCallService.hasVideo
                callUpdate.supportsHolding = true
                provider.reportCall(with: outgoingFCSDKCall.uuid, updated: callUpdate)
                
            } catch {
                print("\(OurErrors.nilACBUC.rawValue)")
            }
            
            await self.fcsdkCallService.hasStartedConnectingDidChange(provider: provider, id: outgoingFCSDKCall?.uuid ?? UUID(), date: self.fcsdkCallService.connectingDate ?? Date())
            await self.fcsdkCallService.hasConnectedDidChange(provider: provider, id: outgoingFCSDKCall?.uuid ?? UUID(), date:self.fcsdkCallService.connectDate ?? Date())
            
            guard let oc = outgoingFCSDKCall else { return }
            await self.callKitManager.addCall(call: oc)
            action.fulfill()
        }
    }
    
    
    //End Call
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        Task {
            await asyncEnd()
            action.fulfill()
        }
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
}
