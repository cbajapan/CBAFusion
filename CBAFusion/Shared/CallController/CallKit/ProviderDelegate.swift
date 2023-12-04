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
import Logging

final class ProviderDelegate: NSObject, CXProviderDelegate {
    internal let provider: CXProvider?
    internal let callKitManager: CallKitManager
    internal let authenticationService: AuthenticationService
    internal let fcsdkCallService: FCSDKCallService
    
    var logger: Logger
    
    init(
        callKitManager: CallKitManager,
        authenticationService: AuthenticationService,
        fcsdkCallService: FCSDKCallService
    ) {
        self.logger = Logger(label: "\(Constants.BUNDLE_IDENTIFIER) - CallKitManager - ")
        self.callKitManager = callKitManager
        self.authenticationService = authenticationService
        self.fcsdkCallService = fcsdkCallService
        self.provider = CXProvider(configuration: type(of: self).providerConfiguration)
        super.init()
        self.provider?.setDelegate(self, queue: .global())
    }
    
    static let providerConfiguration: CXProviderConfiguration = {
        var config: CXProviderConfiguration?
        if #available(iOS 14.0, *) {
            config = CXProviderConfiguration()
        } else {
            config = CXProviderConfiguration(localizedName: "CBA_CXProviderConfiguration")
        }
        guard let config = config else { fatalError() }
        config.supportsVideo = true
        config.maximumCallsPerCallGroup = 1
        config.supportedHandleTypes = [.generic, .phoneNumber]
        //We want to default to the systems ringtone
//        config.ringtoneSound = "ringring.wav"
        config.iconTemplateImageData = #imageLiteral(resourceName: "cbaLogo").pngData()
        return config
    }()
}
