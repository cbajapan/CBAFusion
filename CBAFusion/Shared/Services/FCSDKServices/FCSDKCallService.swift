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

@MainActor
final class FCSDKCallService: NSObject, ObservableObject {
    
    static let shared = FCSDKCallService()
    var cameraFront = true
    @Published var newView: UIView?
    var appDelegate: AppDelegate?
    var contactService: ContactService?
    var logger: Logger
    weak var delegate: AuthenticationProtocol?
    var audioPlayer: AVAudioPlayer?
    @Published var destination: String = ""
    @Published var hasVideo: Bool = false
    @Published var isOutgoing: Bool = false
    @Published var showBackgroundSelectorSheet: Bool = false
    @Published var fcsdkCall: FCSDKCall? = nil
    @Published var hasStartedConnecting: Bool = false
    @Published var isRinging: Bool = false
    @Published var hasConnected: Bool = false
    @Published var isOnHold: Bool = false
    @Published var endPressed: Bool = false {
        didSet {
            if endPressed {
                hasEnded = true
            }
        }
    }
    @Published var hasEnded: Bool = false
    @Published var presentCommunication: Bool = false
    @Published var connectDate: Date?
    @Published var connectingDate: Date?
    @Published var showDTMFSheet: Bool = false
    @Published var doNotDisturb: Bool = false
    @Published var sendErrorMessage: Bool = false
    @Published var errorMessage: String = "Unknown Error"
    @Published var isStreaming: Bool = false
    @Published var backgroundImage: UIImage?
    @Published var virtualBackgroundMode: VirtualBackgroundMode = .image
    @Published var isBuffer: Bool = true
    @Published var swapViews: Bool = false
    @Published var isMirroredFrontCamera: Bool = true
    @Published var defaultAudioDevice: ACBAudioDevice = .speakerphone
    @Published var callStatus: String = ""
    @Published var callQuality: Int = 0
    
    var audioDeviceManager: ACBAudioDeviceManager?
    var captureSession: AVCaptureSession?
    
    override init() {
        self.logger = Logger(label: "\(Constants.BUNDLE_IDENTIFIER) - FCSDKCall Service - ")
        UserDefaults.standard.removeObject(forKey: "ResolutionOption")
        UserDefaults.standard.removeObject(forKey: "RateOption")
    }
    
    deinit {
        print("Reclaiming FCSDKCallService")
    }
    
    func initializeFCSDKCall() async throws -> ACBClientCall? {
        let defaultAudio = UserDefaults.standard.string(forKey: MediaValue.keyAudioDirection.rawValue) ?? "SendAndReceive"
        let defaultVideo = UserDefaults.standard.string(forKey: MediaValue.keyVideoDirection.rawValue) ?? "SendAndReceive"
        
        let audioDirection = AppSettings.mediaDirection(for: defaultAudio)
        let videoDirection = AppSettings.mediaDirection(for: defaultVideo)
        guard let uc = self.fcsdkCall?.acbuc else { throw OurErrors.nilACBUC }
        let outboundCall = await uc.phone.createCall(
            toAddress: self.fcsdkCall?.handle ?? "",
            withAudio: audioDirection,
            video: videoDirection,
            delegate: self
        )
        outboundCall?.delegate = self
        uc.phone.mirrorFrontFacingCameraPreview = isMirroredFrontCamera
        self.fcsdkCall?.call = outboundCall
        await self.fcsdkCall?.call?.enableLocalVideo(true)
        
        Task { @MainActor [weak self] in
            guard let self else { return }
            //We Pass the view up to the SDK when using metalKit View
            if !self.isBuffer {
                self.fcsdkCall?.call?.remoteView = RemoteViews.shared.views.first?.remoteVideoView
            }
        }
        return self.fcsdkCall?.call
    }
    
    @MainActor
    func startCall(previewView: UIView?) async {
        self.hasStartedConnecting = true
        self.connectingDate = Date()
        guard let uc = self.fcsdkCall?.acbuc else { return }
        await setPhoneDelegate()
        if !isBuffer {
            //We Pass the view up to the SDK
            uc.phone.previewView = previewView
        }
    }
    
    func setPhoneDelegate() async {
        
        let selectedAudio = UserDefaults.standard.string(forKey: "AudioOption") ?? ACBAudioDevice.speakerphone.rawValue
        let selectedResolution = UserDefaults.standard.string(forKey: "ResolutionOption") ?? ResolutionOptions.auto.rawValue
        let selectedFrameRate = UserDefaults.standard.string(forKey: "RateOption") ?? FrameRateOptions.fro30.rawValue
        
        delegate?.uc?.phone.delegate = self
        self.selectResolution(res: ResolutionOptions(rawValue: selectedResolution) ?? ResolutionOptions.auto)
        self.selectFramerate(rate:  FrameRateOptions(rawValue: selectedFrameRate) ?? FrameRateOptions.fro30)
        self.selectAudio(audio: ACBAudioDevice(rawValue: selectedAudio) ?? ACBAudioDevice.speakerphone )
    }
    
    @MainActor
    func presentCommunicationSheet() async {
        self.presentCommunication = true
    }
    
    func answerFCSDKCall() async {
        self.connectDate = Date()
        guard let fcsdkCall = self.fcsdkCall?.call else { return }
        guard let uc = delegate?.uc else { return }
        if !isBuffer {
            fcsdkCall.remoteView = RemoteViews.shared.views.first?.remoteVideoView
            guard let view = self.fcsdkCall?.communicationView?.previewView else { return }
            //We Pass the view up to the SDK
            uc.phone.previewView = view
        }
        uc.phone.delegate = self
        await answer(fcsdkCall)
    }
    
    func answer(_ fcsdkCall: ACBClientCall) async {
        let defaultAudio = UserDefaults.standard.string(forKey: MediaValue.keyAudioDirection.rawValue) ?? "SendAndReceive"
        let defaultVideo = UserDefaults.standard.string(forKey: MediaValue.keyVideoDirection.rawValue) ?? "SendAndReceive"
        
        let audioDirection = AppSettings.mediaDirection(for: defaultAudio)
        let videoDirection = AppSettings.mediaDirection(for: defaultVideo)
        guard let uc = delegate?.uc else { return }
        uc.phone.mirrorFrontFacingCameraPreview = isMirroredFrontCamera
        await fcsdkCall.answer(
            withAudio: audioDirection,
            andVideo: videoDirection
        )
    }
    
    func endFCSDKCall(_ fcsdkCall: FCSDKCall) async throws {
        await fcsdkCall.call?.end()
        await self.removeCall(fcsdkCall: fcsdkCall)
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
        guard let uc = delegate?.uc else { return }
        uc.phone.audioDeviceManager.start()
        self.audioDeviceManager = uc.phone.audioDeviceManager
    }
    
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
    
    func selectAudio(audio: ACBAudioDevice) {
        UserDefaults.standard.setValue(audio.rawValue, forKey: "AudioOption")
        switch audio {
        case .earpiece:
            self.audioDeviceManager?.setAudioDevice(.earpiece)
        case .speakerphone:
            self.audioDeviceManager?.setAudioDevice(.speakerphone)
        case .wiredHeadset:
            self.audioDeviceManager?.setAudioDevice(.wiredHeadset)
        case .bluetooth:
            self.audioDeviceManager?.setAudioDevice(.bluetooth)
        case .none:
            self.audioDeviceManager?.setAudioDevice(.none)
        default:
            break
        }
    }
    
    func selectDefaultAudio(audio: ACBAudioDevice) {
        UserDefaults.standard.setValue(audio.rawValue, forKey: "DefaultAudio")
        switch audio {
        case .earpiece:
            self.audioDeviceManager?.setDefaultAudio(.earpiece)
        case .speakerphone:
            self.audioDeviceManager?.setDefaultAudio(.speakerphone)
        case .wiredHeadset:
            self.audioDeviceManager?.setDefaultAudio(.wiredHeadset)
        case .bluetooth:
            self.audioDeviceManager?.setDefaultAudio(.bluetooth)
        case .none:
            self.audioDeviceManager?.setDefaultAudio(.none)
        default:
            break
        }
    }
    
    func selectResolution(res: ResolutionOptions) {
        guard let uc = delegate?.uc else { return }
        switch res {
        case .auto:
            uc.phone.preferredCaptureResolution = ACBVideoCapture.resolutionAuto
        case .res288p:
            //4:3
            uc.phone.preferredCaptureResolution = ACBVideoCapture.resolution352x288
        case .res480p:
            //4:3
            uc.phone.preferredCaptureResolution = ACBVideoCapture.resolution640x480
        case .res720p:
            //16:9
            uc.phone.preferredCaptureResolution = ACBVideoCapture.resolution1024x768
        }
    }
    
    func selectFramerate(rate: FrameRateOptions) {
        guard let uc = delegate?.uc else { return }
        switch rate {
        case .fro20:
            uc.phone.preferredCaptureFrameRate = 20
        case .fro30:
            uc.phone.preferredCaptureFrameRate = 30
        case .fro60:
            uc.phone.preferredCaptureFrameRate = 60
        }
    }
}

// Call Model Methods
extension FCSDKCallService {
    
    func addCall(fcsdkCall: FCSDKCall) async {
        do {
            try await self.contactService?.addCall(fcsdkCall.contact!, fcsdkCall: fcsdkCall)
        } catch {
            self.logger.error("Error adding call - ERROR: \(error)")
        }
    }
    
    @MainActor
    func removeCall(fcsdkCall: FCSDKCall) async {
        var fcsdkCall = fcsdkCall
        fcsdkCall.activeCall = false
        await self.contactService?.editCall(fcsdkCall: fcsdkCall)
    }
    
    @MainActor
    func removeAllCalls() async {
        await self.contactService?.deleteCalls()
    }
    
    @available(iOS 15, *)
    func removeBackground() async {
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.backgroundImage = nil
            self.virtualBackgroundMode = .image
        }
        await fcsdkCall?.call?.removeBackgroundImage()
    }
    
    @MainActor
    @available(iOS 15, *)
    func setBackgroundImage(_ image: UIImage? = nil, mode: VirtualBackgroundMode = .image) async {
        self.backgroundImage = image
        self.virtualBackgroundMode = mode
        await fcsdkCall?.call?.feedBackgroundImage(backgroundImage, mode: virtualBackgroundMode)
    }
}

