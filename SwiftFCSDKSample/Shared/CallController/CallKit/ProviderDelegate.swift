//
//  callKitController.swift
//  SwiftFCSDKSample
//
//  Created by Cole M on 9/7/21.
//

import Foundation
import CallKit
import UIKit
import AVFoundation
import FCSDKiOS

final class ProviderDelegate: NSObject, CXProviderDelegate {
    
    internal let provider: CXProvider?
    internal let callKitManager: CallKitManager
    internal let fcsdkCallService: FCSDKCallService
    internal var incomingCall: FCSDKCall?
    internal var outgoingFCSDKCall: FCSDKCall?
    
    init(
        callKitManager: CallKitManager,
        fcsdkCallService: FCSDKCallService
    ) {
        self.callKitManager = callKitManager
        self.fcsdkCallService = fcsdkCallService
        self.provider = CXProvider(configuration: type(of: self).providerConfiguration)
        super.init()
        self.provider?.setDelegate(self, queue: nil)
    }
    
    static let providerConfiguration: CXProviderConfiguration = {
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
