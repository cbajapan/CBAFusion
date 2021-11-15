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
    
    
    func reportIncomingCall(fcsdkCall: FCSDKCall) async {
        
        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type: .phoneNumber, value: fcsdkCall.handle)
        update.hasVideo = fcsdkCall.hasVideo
        
        do {
            try await provider?.reportNewIncomingCall(with: fcsdkCall.uuid, update: update)
            await self.fcsdkCallService.presentCommunicationSheet()
            await self.callKitManager.addCall(call: fcsdkCall)
        } catch {
            print("There was an error in \(#function) - Error: \(error)")
        }
    }
    
    
    func providerDidReset(_ provider: CXProvider) {
        print("Provider did reset")
    }
    
    //Answer Call after we get notified that we have an incoming call in the push controller
    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        print("answer call action")
        configureAudioSession()
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
        configureAudioSession()
        Task {
            await self.fcsdkCallService.presentCommunicationSheet()
            var acbCall: ACBClientCall?
            do {
                self.outgoingFCSDKCall = self.fcsdkCallService.fcsdkCall
                guard let preView = outgoingFCSDKCall?.previewView else { return }
                try await self.fcsdkCallService.initializeCall(previewView: preView)
                acbCall = try await self.fcsdkCallService.startFCSDKCall()
                outgoingFCSDKCall?.call = acbCall
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
        // Retrieve the FCSDKCall instance corresponding to the action's call UUID
        Task {
            guard let call = await self.callKitManager.callWithUUID(uuid: action.callUUID) else {
                action.fail()
                return
            }
            
            // Stop call audio when ending a call.
            
            // Trigger the call to be ended via the underlying network service.
            self.fcsdkCallService.endFCSDKCall()
            
            // Signal to the system that the action was successfully performed.
            action.fulfill()

            // Remove the ended call from the app's list of calls.
            await callKitManager.removeCall(call: call)
        }
        
    }
    
    
    //Mute Call
    func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
        print("mute call action")
        action.fulfill()
    }
    
    //Timeout action
    func provider(_ provider: CXProvider, timedOutPerforming action: CXAction) {
        print("Timed Out")
        action.fulfill()
    }
    
    //Did Activate audio session
    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        print("Activate")
    }
    
    
    //Did deactivate
    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        print("Deactivate")
    }
    
    //DTMF
    func provider(_ provider: CXProvider, perform action: CXPlayDTMFCallAction) {
        print("Provider - CXPlayDTMFCallAction")
        configureAudioSession()
        
        let dtmfDigits:String = action.digits
        self.fcsdkCallService.fcsdkCall?.call?.playDTMFCode(dtmfDigits, localPlayback: true)

//        print(dtmfDigits, "DIGITS_______1")
//        for (index, _) in dtmfDigits.enumerated() {
//            let dtmfDigit = dtmfDigits.utf8CString[index]
//            print(dtmfDigit, "DIGITS_______")
//
//            //dtmf on
//
//        }
//
//        //dtmf off
        
        // Signal to the system that the action has been successfully performed.
        action.fulfill()
    }
    
    //Provider Began
    func providerDidBegin(_ provider: CXProvider) async {
        print("Provider began")
    }
    
    //Hold call
    func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction) {
        action.fulfill()
    }
    
    //setGroup Call
    func provider(_ provider: CXProvider, perform action: CXSetGroupCallAction) {
        print("set group call")
        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, execute transaction: CXTransaction) -> Bool {
        print("execute transaction")
        return false
    }
}
