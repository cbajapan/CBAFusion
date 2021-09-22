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
import SwiftFCSDK

final class CallKitController: NSObject, CXProviderDelegate {
    
    internal let provider: CXProvider?
    internal let callKitManager: CallKitManager
    internal let authenticationServices: AuthenticationService
    
    
    init(callKitManager: CallKitManager, authenticationServices: AuthenticationService) {
        self.callKitManager = callKitManager
        self.authenticationServices = authenticationServices
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
    
    func configureAudioSession() {
        // See https://forums.developer.apple.com/thread/64544
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(AVAudioSession.Category.playAndRecord, mode: .default)
            try session.setActive(true)
            try session.setMode(AVAudioSession.Mode.voiceChat)
            try session.setPreferredSampleRate(44100.0)
            try session.setPreferredIOBufferDuration(0.005)
        } catch {
            print(error)
        }
    }

    
    
    /// We want to end any on going calls if the provider resets and remove them from the list of calls here
    func providerDidReset(_ provider: CXProvider) {
        print("Provider did reset")
    }
    
    //Answer Call
    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        print("answer call action")
        action.fulfill()
    }

    var call: FCSDKCall?
    //Start Call
     func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
         print("start call action")

        let call = FCSDKCall(acbuc: self.authenticationServices.acbuc, uuid: action.callUUID, isOutgoing: true)
        call.handle = action.handle.value
        
        configureAudioSession()
        
        call.hasStartedConnectingDidChange = { [weak self] in
            self?.provider?.reportOutgoingCall(with: call.uuid, startedConnectingAt: call.connectingDate)
        }
        call.hasConnectedDidChange = { [weak self] in
            self?.provider?.reportOutgoingCall(with: call.uuid, connectedAt: call.connectDate)
        }

        self.outgoingCall = call
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
    
    var outgoingCall: FCSDKCall?
    //Did Activate audio session
    @MainActor func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        print("Activate")
        do {
        try outgoingCall?.startFCSDKCall()
        } catch {
            print("\(OurErrors.nilACBUC.rawValue)")
        }
        self.callKitManager.addCalls(call: FCSDKCall(acbuc: self.authenticationServices.acbuc, uuid: outgoingCall?.uuid ?? UUID(), isOutgoing: outgoingCall?.isOutgoing ?? true))
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
