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
    weak var delegate: AuthenticationProtocol?
    var audioPlayer: AVAudioPlayer?
    @Published var destination: String = ""
    @Published var hasVideo: Bool = false
    @Published var isOutgoing: Bool = false
    @Published var acbuc: ACBUC? {
        didSet {
            Task { [weak self] in
            self?.uc = self?.acbuc
            }
        }
    }
//   @FCSDKTransportActor
    var uc: ACBUC?
    @Published var fcsdkCall: FCSDKCall? = nil
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
    @Published var isStreaming: Bool = false
//   @FCSDKTransportActor
    var audioDeviceManager: ACBAudioDeviceManager?
    
    override init() {
        self.logger = Logger(label: "\(Constants.BUNDLE_IDENTIFIER) - FCSDKCall Service - ")
    }
    
    deinit {
       print("Reclaiming FCSDKCallService")
    }
//
//   @FCSDKTransportActor
//    func setPhoneDelegate() {
//        self.acbuc?.phone.delegate = self
//    }
//

    func initializeFCSDKCall() async throws -> ACBClientCall? {
        
        guard let uc = self.fcsdkCall?.acbuc else { throw OurErrors.nilACBUC }
        let outboundCall = await uc.phone.createCall(
            toAddress: self.fcsdkCall?.handle ?? "",
            withAudio: AppSettings.perferredAudioDirection(),
            video: AppSettings.perferredVideoDirection(),
            delegate: self
        )
        self.fcsdkCall?.call = outboundCall
        self.fcsdkCall?.call?.enableLocalVideo(true)
        
        await MainActor.run {
            //We Pass the view up to the SDK when using metalKit View
#if arch(arm64) && !targetEnvironment(simulator)
            if #available(iOS 15.0.0, *) {
                self.logger.info("You are using iOS 15 you can use buffer view")
            } else {
                self.fcsdkCall?.call?.remoteView = self.fcsdkCall?.remoteView
            }
#elseif targetEnvironment(simulator)
            self.fcsdkCall?.call?.remoteView = self.fcsdkCall?.remoteView
#endif
        }
        return self.fcsdkCall?.call
    }
    
    @MainActor
    func startCall(previewView: UIView) async {
        self.hasStartedConnecting = true
        self.connectingDate = Date()
        guard let uc = self.fcsdkCall?.acbuc else { return }
        await setPhoneDelegate(uc)
        //We Pass the view up to the SDK
        uc.phone.previewView = previewView
        }
    
//   @FCSDKTransportActor
    func setPhoneDelegate(_ uc: ACBUC) async {
        uc.phone.delegate = self
    }
    
    @MainActor
    func presentCommunicationSheet() async {
        self.presentCommunication = true
    }
    
    @MainActor
    func answerFCSDKCall() async {
            self.hasConnected = true
            self.connectDate = Date()
        guard let fcsdkCall = self.fcsdkCall?.call else { return }
#if arch(arm64) && !targetEnvironment(simulator)
        if #available(iOS 15.0.0, *) {
            self.logger.info("You are using iOS 15 you can use buffer view")
        } else {
                fcsdkCall.remoteView = self.fcsdkCall?.remoteView
            }
#elseif targetEnvironment(simulator)
        fcsdkCall.remoteView = self.fcsdkCall?.remoteView
#endif
        guard let view = self.fcsdkCall?.previewView else { return }
        guard let uc = self.acbuc else { return }
        //We Pass the view up to the SDK
        uc.phone.previewView = view
        await answer(fcsdkCall)
    }
    
//   @FCSDKTransportActor
    func answer(_ fcsdkCall: ACBClientCall) async {
        await fcsdkCall.answer(withAudio: AppSettings.perferredAudioDirection(), andVideo: AppSettings.perferredVideoDirection())
    }
//   @FCSDKTransportActor
    func endFCSDKCall(_ fcsdkCall: FCSDKCall) async throws {
        await fcsdkCall.call?.end()
        await self.removeCall(fcsdkCall: fcsdkCall)
        await MainActor.run {
            self.hasEnded = true
        }
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
    
//   @FCSDKTransportActor
    func startAudioSession() {
            self.audioDeviceManager = self.uc?.phone.audioDeviceManager
//            self.audioDeviceManager?.start()
    }
    
//   @FCSDKTransportActor
    func stopAudioSession() {
        self.audioDeviceManager?.stop()
        self.audioDeviceManager = nil
    }
    
    @MainActor
    func startRing() {
        let path  = Bundle.main.path(forResource: "ringring", ofType: ".wav")
        let fileURL = URL(fileURLWithPath: path!)
        self.audioPlayer = try! AVAudioPlayer(contentsOf: fileURL)
        self.audioPlayer?.volume = 1.0
        self.audioPlayer?.numberOfLoops = -1
        self.audioPlayer?.prepareToPlay()
        self.audioPlayer?.play()
    }
    
    func stopRing() {
        self.audioPlayer?.stop()
        self.audioPlayer = nil
    }
    
}

/// Settings
extension FCSDKCallService {
    
//   @FCSDKTransportActor
    func selectAudio(audio: AudioOptions) {
        switch audio {
        case .ear:
            self.audioDeviceManager?.setAudioDevice(.earpiece)
        case .speaker:
            self.audioDeviceManager?.setAudioDevice(.speakerphone)
        }
    }
    
//   @FCSDKTransportActor
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
    
//   @FCSDKTransportActor
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
    func addCall(fcsdkCall: FCSDKCall) async {
        do {
            try await self.contactService?.addCall(fcsdkCall.contact!, fcsdkCall: fcsdkCall)
        } catch {
            self.logger.error("Error adding call - ERROR: \(error)")
        }
    }
    
    @MainActor
    func removeCall(fcsdkCall: FCSDKCall) async {
        fcsdkCall.activeCall = false
        await self.contactService?.editCall(fcsdkCall: fcsdkCall)
    }
    
    @MainActor
    func removeAllCalls() async {
        await self.contactService?.deleteCalls()
    }
    
}
