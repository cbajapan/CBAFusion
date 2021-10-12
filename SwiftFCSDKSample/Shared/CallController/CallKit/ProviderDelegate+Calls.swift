//
//  callKitController+Call.swift
//  SwiftFCSDKSample
//
//  Created by Cole M on 10/4/21.
//

import Foundation
import CallKit
import AVFoundation
import SwiftFCSDK

extension ProviderDelegate {

    func reportIncomingCall(uuid: UUID, handle: String, hasVideo: Bool = false, completion: ((NSError?) -> Void)? = nil) {
        
        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type: .phoneNumber, value: handle)
        update.hasVideo = hasVideo
        
        provider?.reportNewIncomingCall(with: uuid, update: update) { error in
            
            
            if error == nil {
//                let call =  FCSDKCall(uuid: uuid)
//                call.handle = handle
                
//                self.callKitManager.addCalls(call: call)
            }
            
            completion?(error as NSError?)
        }
    }
    
    
    func providerDidReset(_ provider: CXProvider) {
        print("Provider did reset")
    }
    
    //Answer Call after we get notified that we have an incoming call in the push controller
    @MainActor func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) async  {
        print("answer call action")
        
        guard let call = callKitManager.callWithUUID(uuid: action.callUUID) else {
            action.fail()
            return
        }
        
        configureAudioSession()
        
        self.fcsdkCallService.answerFCSDKCall()
        
        action.fulfill()
    }
    
    
    //Start Call
    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        print("start call action")

        configureAudioSession()

        Task {
            var acbCall: ACBClientCall?
            do {
                self.outgoingFCSDKCall = try await self.fcsdkCallService.setFCSDKCall()
                guard let preView = outgoingFCSDKCall?.previewView else { return }
                try await self.fcsdkCallService.initializeCall(previewView: preView)
                acbCall = try await self.fcsdkCallService.startFCSDKCall()
                outgoingFCSDKCall?.call = acbCall
            } catch {
                print("\(OurErrors.nilACBUC.rawValue)")
            }
            
            await self.fcsdkCallService.hasStartedConnectingDidChange(provider: provider, id: outgoingFCSDKCall?.uuid ?? UUID(), date: Date())
            await self.fcsdkCallService.hasConnectedDidChange(provider: provider, id: outgoingFCSDKCall?.uuid ?? UUID(), date: Date())
            
            guard let oc = outgoingFCSDKCall else { return }
            self.callKitManager.addCalls(call: oc)
            NotificationCenter.default.post(name: NSNotification.Name("add"), object: nil)
            action.fulfill()
        }
    }

    
    //End Call
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) async {
        // Retrieve the SpeakerboxCall instance corresponding to the action's call UUID
        guard let call = callKitManager.callWithUUID(uuid: action.callUUID) else {
            action.fail()
            return
        }
        
        // Stop call audio when ending a call.
        
        // Trigger the call to be ended via the underlying network service.
        self.fcsdkCallService.endFCSDKCall()
        
        // Signal to the system that the action was successfully performed.
        action.fulfill()
        
        Task {
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
    @MainActor func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        print("Activate")
    }
    
    
    //Did deactivate
    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        print("Deactivate")
    }
    
    //DTMF
    func provider(_ provider: CXProvider, perform action: CXPlayDTMFCallAction) {
        print("DTMF")
        action.fulfill()
    }
    
    //Provider Began
    func providerDidBegin(_ provider: CXProvider) {
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
