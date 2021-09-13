//
//  CallKitController.swift
//  SwiftFCSDKSample
//
//  Created by Cole M on 9/7/21.
//

import Foundation
import CallKit
import UIKit
import AVFoundation

protocol CallKitProtocol: NSObject {
    
}


final class CallKitController: NSObject, CXProviderDelegate {
    
    
    internal let provider: CXProvider?
    internal let callKitManager: CallKitManager
    
    init(callKitManager: CallKitManager) {
        self.callKitManager = callKitManager
        self.provider = CXProvider(configuration: providerConfiguration)
        super.init()
        self.provider?.setDelegate(self, queue: nil)
    }
    
    
    
    var providerConfiguration: CXProviderConfiguration = {
        let config = CXProviderConfiguration()
        config.supportsVideo = true
        config.maximumCallsPerCallGroup = 1
        config.supportedHandleTypes = [.phoneNumber, .emailAddress, .generic]
        config.iconTemplateImageData = UIImage(systemName: "person.fill")?.pngData()
        config.ringtoneSound = "ringring.wav"
        return config
    }()
    
    
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
    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
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
