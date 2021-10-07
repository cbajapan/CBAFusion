//
//  CallKitController+Provider.swift
//  SwiftFCSDKSample
//
//  Created by Cole M on 10/4/21.
//

import Foundation
import CallKit
import AVFoundation


enum CallKitEvents {
    case connecting
    case connected
}


protocol ProviderDelegate: NSObject {
    func callStatus(events: CallKitEvents)
}



extension CallKitController {
    
    /// We want to end any on going calls if the provider resets and remove them from the list of calls here
    func providerDidReset(_ provider: CXProvider) {
        print("Provider did reset")
    }
    
    //Answer Call
    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        print("answer call action")
        action.fulfill()
    }
    
    
    //Start Call
    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        print("start call action")

        guard let unwrapCall = self.call else { return }
        
        unwrapCall.handle = action.handle.value

        configureAudioSession()
        self.call?.hasStartedConnectingDidChange = { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.provider?.reportOutgoingCall(with: unwrapCall.uuid, startedConnectingAt: unwrapCall.connectingDate)
        }
        self.call?.hasConnectedDidChange = { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.provider?.reportOutgoingCall(with: unwrapCall.uuid, connectedAt: unwrapCall.connectDate)
        }
        
        self.outgoingCall = unwrapCall
        action.fulfill()
    }
    
    //End Call
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        print("end call action")
        action.fulfill()
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
        Task {
            do {
                guard let previewView = call?.previewView else { return }
                try await outgoingCall?.initializeCall(previewView: previewView)
                try await outgoingCall?.startFCSDKCall()
            } catch {
                print("\(OurErrors.nilACBUC.rawValue)")
            }
        guard let outgoing = self.outgoingCall else { return }
        await self.callKitManager.addCalls(call: outgoing)
            NotificationCenter.default.post(name: NSNotification.Name("add"), object: nil)
        }
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
