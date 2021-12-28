//
//  callKitController.swift
//  CBAFusion
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
    internal let authenticationService: AuthenticationService
    internal let fcsdkCallService: FCSDKCallService
    internal var outgoingFCSDKCall: FCSDKCall?
    
    init(
        callKitManager: CallKitManager,
        authenticationService: AuthenticationService,
        fcsdkCallService: FCSDKCallService
    ) {
        self.callKitManager = callKitManager
        self.authenticationService = authenticationService
        self.fcsdkCallService = fcsdkCallService
        self.provider = CXProvider(configuration: type(of: self).providerConfiguration)
        super.init()
        self.provider?.setDelegate(self, queue: .global())
    }
    
    static let providerConfiguration: CXProviderConfiguration = {
        let config = CXProviderConfiguration()
        config.supportsVideo = true
        config.maximumCallsPerCallGroup = 1
        config.supportedHandleTypes = [.phoneNumber]
        //We want to default to the systems ringtone
//        config.ringtoneSound = "ringring.wav"
        config.iconTemplateImageData = #imageLiteral(resourceName: "cbaLogo").pngData()
        return config
    }()
}
