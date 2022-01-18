//
//  FCSDKCallService.swift
//  CBAFusion
//
//  Created by Cole M on 10/12/21.
//

import Foundation
import AVFoundation
import SwiftUI
import FCSDKiOS
import CallKit
import Logging

class FCSDKCallService: NSObject, ObservableObject {
    
    var appDelegate: AppDelegate?
    var contactService: ContactService?
    var logger: Logger
    @Published var destination: String = ""
    @Published var hasVideo: Bool = true
    @Published var isOutgoing: Bool = false
    @Published var acbuc: ACBUC?
    @Published var currentCall: FCSDKCall? = nil
    @Published var hasStartedConnecting: Bool = false
    @Published var isRinging: Bool = false
    @Published var hasConnected: Bool = false
    @Published var isOnHold: Bool = false
    @Published var hasEnded: Bool = false
    @Published var presentCommunication: Bool = false
    @Published var connectDate: Date?
    @Published var connectingDate: Date?
    @Published var showDTMFSheet: Bool = false
    @Published var doNotDisturb: Bool = false
    @Published var sendErrorMessage: Bool = false
    @Published var errorMessage: String = "Unknown Error"
    @Published var audioDeviceManager: ACBAudioDeviceManager?
    
    override init() {
        self.logger = Logger(label: "\(Constants.BUNDLE_IDENTIFIER) - FCSDKCall Service - ")
    }
    deinit {
        self.currentCall?.call?.delegate = nil
    }
    
    
    func setPhoneDelegate() {
        self.acbuc?.phone.delegate = self
    }
    
    
    func startFCSDKCall() async throws -> ACBClientCall? {
        guard let uc = self.currentCall?.acbuc else { throw OurErrors.nilACBUC }
        let outboundCall = uc.phone.createCall(
            toAddress: self.currentCall?.handle ?? "",
            withAudio: AppSettings.perferredAudioDirection(),
            video: AppSettings.perferredVideoDirection(),
            delegate: self
        )
        self.currentCall?.call = outboundCall
        self.currentCall?.call?.enableLocalAudio(true)
        self.currentCall?.call?.enableLocalVideo(true)
        await MainActor.run {
            //We Pass the view up to the SDK when using metalKit View
//            self.currentCall?.call?.remoteView = self.currentCall?.remoteView
        }
        return self.currentCall?.call
    }
    
    func initializeCall(previewView: UIView) async throws {
        await MainActor.run {
            self.hasStartedConnecting = true
            self.connectingDate = Date()
        }
        guard let uc = self.currentCall?.acbuc else { throw OurErrors.nilACBUC }
        uc.phone.delegate = self
        //We Pass the view up to the SDK
        uc.phone.previewView = previewView
    }
    
    @MainActor
    func presentCommunicationSheet() async {
        self.presentCommunication = true
    }
    
    func answerFCSDKCall() async throws {
        await MainActor.run {
            self.hasConnected = true
            self.connectDate = Date()
            self.presentCommunication = true
        }
        
        //We Pass the view up to the SDK
//        self.currentCall?.call?.remoteView = self.currentCall?.remoteView

        guard let view = self.currentCall?.previewView else { throw OurErrors.nilPreviewView }
        guard let uc = self.acbuc else { throw OurErrors.nilACBUC }
        //We Pass the view up to the SDK
        uc.phone.previewView = view
        try? self.currentCall?.call?.answer(withAudio: AppSettings.perferredAudioDirection(), andVideo: AppSettings.perferredVideoDirection())
    }
    
    func endACBClientCall() async throws {
        guard let currentCall = self.currentCall else { throw OurErrors.nilFCSDKCall }
        self.currentCall?.call?.end(currentCall.call)
    }
    
    func endFCSDKCall() async throws {
        guard let currentCall = self.currentCall else { throw OurErrors.nilFCSDKCall }
        self.currentCall?.call?.end(currentCall.call)
        await self.removeCall(call: currentCall)
    }
    
    func hasStartedConnectingDidChange(provider: CXProvider, id: UUID, date: Date) async {
        provider.reportOutgoingCall(with: id, startedConnectingAt: date)
    }
    
    func hasConnectedDidChange(provider: CXProvider, id: UUID, date: Date) async {
        provider.reportOutgoingCall(with: id, connectedAt: date)
    }
    
    var duration: TimeInterval {
        guard let connectDate = connectDate else {
            return 0
        }
        return Date().timeIntervalSince(connectDate)
    }
    
    func startAudioSession() async {
        await MainActor.run {
            self.audioDeviceManager = self.acbuc?.phone.audioDeviceManager
        }
        self.audioDeviceManager?.start()
    }
    
    func stopAudioSession() async {
        await MainActor.run {
            self.audioDeviceManager = nil
        }
        self.audioDeviceManager?.stop()
    }
    
    var audioPlayer: AVAudioPlayer?
    func playOutgoingRingtone() async {
        let path  = Bundle.main.path(forResource: "ringring", ofType: ".wav")
        let fileURL = URL(fileURLWithPath: path!)
        self.audioPlayer = try! AVAudioPlayer(contentsOf: fileURL)
        self.audioPlayer?.volume = 1.0
        self.audioPlayer?.numberOfLoops = -1
        self.audioPlayer?.prepareToPlay()
        self.audioPlayer?.play()
    }
    
    func stopOutgoingRingtone() async {
        self.audioPlayer?.stop()
        self.audioPlayer = nil
    }
}

/// Settings
extension FCSDKCallService {
    func selectAudio(audio: AudioOptions) {
        switch audio {
        case .ear:
            self.audioDeviceManager?.setAudioDevice(.earpiece)
        case .speaker:
            self.audioDeviceManager?.setAudioDevice(.speakerphone)
        }
    }
    
    func selectResolution(res: ResolutionOptions) {
        switch res {
        case .auto:
            self.acbuc?.phone.preferredCaptureResolution = ACBVideoCapture.resolutionAuto;
        case .res288p:
            self.acbuc?.phone.preferredCaptureResolution = ACBVideoCapture.resolution352x288;
        case .res480p:
            self.acbuc?.phone.preferredCaptureResolution = ACBVideoCapture.resolution640x480;
        case .res720p:
            self.acbuc?.phone.preferredCaptureResolution = ACBVideoCapture.resolution1280x720;
        }
    }
    
    func selectFramerate(rate: FrameRateOptions) {
        switch rate {
        case .fro20:
            self.acbuc?.phone.preferredCaptureFrameRate = 20
        case .fro30:
            self.acbuc?.phone.preferredCaptureFrameRate = 30
        }
    }
}

// Call Model Methods
extension FCSDKCallService {
    
    @MainActor
    func addCall(call: FCSDKCall) async {
        do {
            try await self.contactService?.addCall(call, isEdit: false)
        } catch {
             self.logger.error("\(error)")
        }
    }
    
    @MainActor
    func removeCall(call: FCSDKCall) async {
        call.activeCall = false
        await self.contactService?.editCall(call: call)
        self.currentCall = nil
    }
    
    @MainActor
    func removeAllCalls() async {
        await self.contactService?.deleteCalls()
    }
    
}
