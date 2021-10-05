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
    internal var call: FCSDKCall?
    internal var outgoingCall: FCSDKCall?
    
    init(callKitManager: CallKitManager, authenticationServices: AuthenticationService) {
        self.callKitManager = callKitManager
        self.authenticationServices = authenticationServices
        self.provider = CXProvider(configuration: providerConfiguration)
        super.init()
        self.provider?.setDelegate(self, queue: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(receiveCall), name: NSNotification.Name("call"), object: nil)
    }
    
    @objc func receiveCall(_ notification: Notification?) {
        if let dict = notification?.object as? NSDictionary {
            if let call = dict["call"] as? FCSDKCall {
                self.call = call
            }
        }
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
    
}
