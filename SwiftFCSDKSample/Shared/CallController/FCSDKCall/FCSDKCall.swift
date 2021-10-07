//
//  FCSDKCall.swift
//  SwiftFCSDKSample
//
//  Created by Cole M on 9/22/21.
//

import Foundation
import SwiftUI
import SwiftFCSDK
import AVKit

final class FCSDKCall: NSObject, ObservableObject {
    
    
    var handle: String
    var hasVideo: Bool
    var previewView: ACBView
    var remoteView: ACBView
    weak var providerDelegate: ProviderDelegate?
    
   var uuid: UUID
   var isOutgoing: Bool
   
   var acbuc: ACBUC?
   var call: ACBClientCall?
   var audioPlayer: AVAudioPlayer?
   var lastIncomingCall: ACBClientCall?
   var callIdentifier: UUID?
    
    //Callbacks
    var stateDidChange: (() -> Void)?
    var hasStartedConnectingDidChange: (() -> Void)?
    var hasConnectedDidChange: (() -> Void)?
    var hasEndedDidChange: (() -> Void)?

//
    var connectingDate: Date? {
        didSet {
            stateDidChange?()
            hasStartedConnectingDidChange?()
        }
    }
//
    var connectDate: Date? {
        didSet {
            stateDidChange?()
            hasConnectedDidChange?()
        }
    }
    
    
    
    

    var endDate: Date? {
        didSet {
            stateDidChange?()
            hasEndedDidChange?()
        }
    }

    var isOnHold = false {
        didSet {
            stateDidChange?()
        }
    }

//    //Derived properties
//
    var hasStartedConnecting: Bool {
        get {
            return connectingDate != nil
        }
        set {
            connectingDate = newValue ? Date() : nil
        }
    }

    var hasConnected: Bool {
        get {
            return connectDate != nil
        }
        set {
            connectDate = newValue ? Date() : nil
        }
    }

    var hasEnded: Bool {
        get {
            return endDate != nil
        }
        set {
            endDate = newValue ? Date() : nil
        }
    }

    var duration: TimeInterval {
        guard let connectDate = connectDate else {
            return 0
        }
        return Date().timeIntervalSince(connectDate)
    }
    
    init(
        handle: String,
        hasVideo: Bool,
        previewView: ACBView,
        remoteView: ACBView,
        acbuc: ACBUC? = nil,
        uuid: UUID,
        isOutgoing: Bool = false
    ) {
        self.handle = handle
        self.hasVideo = hasVideo
        self.previewView = previewView
        self.remoteView = remoteView
        self.acbuc = acbuc
        self.uuid = uuid
        self.isOutgoing = isOutgoing
    }
    
}


extension FCSDKCall {
    
    func initializeCall(previewView: ACBView) async throws {
        guard let uc = self.acbuc else { throw OurErrors.nilACBUC }
        let phone = uc.phone()
        try? phone?.setPreviewView(previewView)
        phone?.preferredCaptureFrameRate = 30
        phone?.preferredCaptureResolution = .autoResolution
        phone?.delegate = self
        self.requestMicrophoneAndCameraPermissionFromAppSettings()
    }
    
    func startFCSDKCall() async throws {
        guard let uc = self.acbuc else { throw OurErrors.nilACBUC }
        let outboundCall = uc.clientPhone?.createCall(
            toAddress: self.handle,
            withAudio: AppSettings.perferredAudioDirection(),
            video: AppSettings.perferredVideoDirection(),
            delegate: self
        )

        self.call = outboundCall
        
        self.call?.videoView = self.remoteView
        self.call?.enableLocalAudio(true)
        self.call?.enableLocalVideo(true)
    }

    
    func answerFCSDKCall() {
        hasConnected = true
    }
    
    func endFCSDKCall() {
        hasEnded = true
    }
    
    
    func requestMicrophoneAndCameraPermissionFromAppSettings() {
        let requestMic = AppSettings.perferredAudioDirection() == .sendOnly || AppSettings.perferredAudioDirection() == .sendAndReceive
        let requestCam = AppSettings.perferredVideoDirection() == .sendOnly || AppSettings.perferredVideoDirection() == .sendAndReceive
        ACBClientPhone.requestMicrophoneAndCameraPermission(requestMic, video: requestCam)
    }
    
}

