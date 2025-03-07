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

/// A service class for managing calls using the FCSDK.
@MainActor
final class FCSDKCallService: NSObject, ObservableObject {
    
    // MARK: - Properties
    
    static let shared = FCSDKCallService()
    
    var cameraFront = true
    var appDelegate: AppDelegate?
    var contactService: ContactService?
    var logger: Logger
    weak var delegate: AuthenticationProtocol?
    var audioPlayer: AVAudioPlayer?
    
    // MARK: - Published Properties
    @Published var newView: UIView?
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
    
    @MainActor var audioDeviceManager: ACBAudioDeviceManager?
    var captureSession: AVCaptureSession?
    
    // MARK: - Initializer
    
    override init() {
        self.logger = Logger(label: "\(Constants.BUNDLE_IDENTIFIER) - FCSDKCall Service - ")
        UserDefaults.standard.removeObject(forKey: "ResolutionOption")
        UserDefaults.standard.removeObject(forKey: "RateOption")
    }
    
    deinit {
        print("Reclaiming FCSDKCallService")
    }
    
    // MARK: - Call Initialization
    
    /// Initializes a new call using the FCSDK.
    /// - Throws: An error if the call cannot be initialized.
    /// - Returns: An optional ACBClientCall instance.
    func initializeFCSDKCall() async throws -> ACBClientCall? {
        let defaultAudio = UserDefaults.standard.string(forKey: MediaValue.keyAudioDirection.rawValue) ?? "SendAndReceive"
        let defaultVideo = UserDefaults.standard.string(forKey: MediaValue.keyVideoDirection.rawValue) ?? "SendAndReceive"
        
        let audioDirection = AppSettings.mediaDirection(for: defaultAudio)
        let videoDirection = AppSettings.mediaDirection(for: defaultVideo)
        
        guard let uc = self.fcsdkCall?.acbuc else { throw OurErrors.nilACBUC }
        uc.phone.mirrorFrontFacingCameraPreview = isMirroredFrontCamera
        
        let outboundCall = await uc.phone.createCall(
            toAddress: self.fcsdkCall?.handle ?? "",
            withAudio: audioDirection,
            video: videoDirection,
            delegate: self
        )
        
        self.fcsdkCall?.call = outboundCall
        await self.fcsdkCall?.call?.enableLocalVideo(true)
        
        // Pass the view to the SDK when using MetalKit View
        if !self.isBuffer {
            self.fcsdkCall?.call?.remoteView = RemoteViews.shared.views.first?.remoteVideoView
        }
        
        return self.fcsdkCall?.call
    }
    
    // MARK: - Call Management
    
    /// Sets the current call.
    /// - Parameter call: The ACBClientCall to set.
    @MainActor
    func setCall(call: ACBClientCall) async {
        self.fcsdkCall?.call = call
    }
    
    /// Starts the call process.
    /// - Parameter previewView: The view to display during the call.
    @MainActor
    func startCall(previewView: UIView?) async {
        self.hasStartedConnecting = true
        self.connectingDate = Date()
        
        guard let uc = self.fcsdkCall?.acbuc else { return }
        await setPhoneDelegate()
        
        if !isBuffer {
            uc.phone.previewView = previewView
        }
    }
    
    /// Sets the phone delegate and configures audio and video settings.
    @MainActor
    func setPhoneDelegate() async {
        let selectedAudio = UserDefaults.standard.string(forKey: "AudioOption") ?? ACBAudioDevice.speakerphone.rawValue
        let selectedResolution = UserDefaults.standard.string(forKey: "ResolutionOption") ?? ResolutionOptions.auto.rawValue
        let selectedFrameRate = UserDefaults.standard.string(forKey: "RateOption") ?? FrameRateOptions.fro30.rawValue
        
        delegate?.uc?.phone.delegate = self
        self.selectResolution(res: ResolutionOptions(rawValue: selectedResolution) ?? ResolutionOptions.auto)
        self.selectFramerate(rate: FrameRateOptions(rawValue: selectedFrameRate) ?? FrameRateOptions.fro30)
        self.selectAudio(audio: ACBAudioDevice(rawValue: selectedAudio) ?? ACBAudioDevice.speakerphone)
    }
    
    /// Presents the communication sheet.
    @MainActor
    func presentCommunicationSheet() async {
        self.presentCommunication = true
    }
    
    /// Answers an incoming call.
    func answerFCSDKCall() async {
        self.connectDate = Date()
        
        guard let fcsdkCall = self.fcsdkCall?.call, let uc = delegate?.uc else { return }
        
        if !isBuffer {
            fcsdkCall.remoteView = RemoteViews.shared.views.first?.remoteVideoView
            guard let view = self.fcsdkCall?.communicationView?.previewView else { return }
            uc.phone.previewView = view
        }
        await answer(fcsdkCall)
    }
    
    /// Answers the specified call with audio and video settings.
    /// - Parameter fcsdkCall: The call to answer.
    func answer(_ fcsdkCall: ACBClientCall) async {
        let defaultAudio = UserDefaults.standard.string(forKey: MediaValue.keyAudioDirection.rawValue) ?? "SendAndReceive"
        let defaultVideo = UserDefaults.standard.string(forKey: MediaValue.keyVideoDirection.rawValue) ?? "SendAndReceive"
        
        let audioDirection = AppSettings.mediaDirection(for: defaultAudio)
        let videoDirection = AppSettings.mediaDirection(for: defaultVideo)
        
        guard let uc = delegate?.uc else { return }
        uc.phone.mirrorFrontFacingCameraPreview = isMirroredFrontCamera
        
        await fcsdkCall.answer(withAudio: audioDirection, andVideo: videoDirection)
    }
    
    /// Ends the specified call.
    /// - Parameter fcsdkCall: The call to end.
    /// - Throws: An error if the call cannot be ended.
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
    
    
    // MARK: - Call Duration
    
    /// Calculates the duration of the call.
    var duration: TimeInterval {
        guard let connectDate = connectDate else {
            return 0
        }
        return Date().timeIntervalSince(connectDate)
    }
    
    // MARK: - Audio Session Management
    
    /// Starts the audio session.
    @MainActor
    func startAudioSession() async {
        guard let uc = delegate?.uc else { return }
        uc.phone.audioDeviceManager.start()
        self.audioDeviceManager = uc.phone.audioDeviceManager
    }
    
    /// Stops the audio session.
    @MainActor func stopAudioSession() {
        self.audioDeviceManager?.stop()
        self.audioDeviceManager = nil
    }
    
    // MARK: - Ring Management
    
    /// Starts ringing sound.
    @MainActor
    func startRing() {
        guard let path = Bundle.main.path(forResource: "ringring", ofType: ".wav") else { return }
        let fileURL = URL(fileURLWithPath: path)
        
        do {
            self.audioPlayer = try AVAudioPlayer(contentsOf: fileURL)
            self.audioPlayer?.volume = 1.0
            self.audioPlayer?.numberOfLoops = -1
            self.audioPlayer?.prepareToPlay()
            self.audioPlayer?.play()
        } catch {
            logger.error("Error starting ring: \(error)")
        }
    }
    
    /// Stops ringing sound.
    func stopRing() {
        self.audioPlayer?.stop()
        self.audioPlayer = nil
    }
}

// MARK: - Settings Management

extension FCSDKCallService {
    
    /// Selects the audio device for the call.
    /// - Parameter audio: The audio device to select.
    @MainActor func selectAudio(audio: ACBAudioDevice) {
        UserDefaults.standard.setValue(audio.rawValue, forKey: "AudioOption")
        self.audioDeviceManager?.setAudioDevice(audio)
    }
    
    /// Selects the default audio device.
    /// - Parameter audio: The audio device to set as default.
    @MainActor func selectDefaultAudio(audio: ACBAudioDevice) {
        UserDefaults.standard.setValue(audio.rawValue, forKey: "DefaultAudio")
        self.audioDeviceManager?.setDefaultAudio(audio)
    }
    
    /// Selects the resolution for the video call.
    /// - Parameter res: The resolution option to select.
    func selectResolution(res: ResolutionOptions) {
        guard let uc = delegate?.uc else { return }
        uc.phone.preferredCaptureResolution = ACBVideoCapture.resolutionAuto
//        switch res {
//        case .auto:
//            uc.phone.preferredCaptureResolution = ACBVideoCapture.resolutionAuto
//            UserDefaults.standard.set(ResolutionOptions.auto.rawValue, forKey: "ResolutionOption")
//        case .res288p:
//            uc.phone.preferredCaptureResolution = ACBVideoCapture.resolution352x288
//            UserDefaults.standard.set(ResolutionOptions.res288p.rawValue, forKey: "ResolutionOption")
//        case .res480p:
//            uc.phone.preferredCaptureResolution = ACBVideoCapture.resolution640x480
//            UserDefaults.standard.set(ResolutionOptions.res480p.rawValue, forKey: "ResolutionOption")
//        case .res720p:
//            uc.phone.preferredCaptureResolution = ACBVideoCapture.resolution1280x720
//            UserDefaults.standard.set(ResolutionOptions.res720p.rawValue, forKey: "ResolutionOption")
//        }
    }
    
    /// Selects the frame rate for the video call.
    /// - Parameter rate: The frame rate option to select.
    func selectFramerate(rate: FrameRateOptions) {
        guard let uc = delegate?.uc else { return }
        switch rate {
        case .fro20:
            uc.phone.preferredCaptureFrameRate = 20
            UserDefaults.standard.set(FrameRateOptions.fro20.rawValue, forKey: "RateOption")
        case .fro30:
            uc.phone.preferredCaptureFrameRate = 30
            UserDefaults.standard.set(FrameRateOptions.fro30.rawValue, forKey: "RateOption")
        case .fro60:
            uc.phone.preferredCaptureFrameRate = 60
            UserDefaults.standard.set(FrameRateOptions.fro60.rawValue, forKey: "RateOption")
        }
    }
}

// MARK: - Call Model Methods

extension FCSDKCallService {
    
    /// Adds a call to the contact service.
    /// - Parameter fcsdkCall: The call to add.
    func addCall(fcsdkCall: FCSDKCall) async {
        do {
            try await self.contactService?.addCall(fcsdkCall.contact!, fcsdkCall: fcsdkCall)
        } catch {
            self.logger.error("Error adding call: \(error)")
        }
    }
    
    /// Removes a call from the contact service.
    /// - Parameter fcsdkCall: The call to remove.
    @MainActor
    func removeCall(fcsdkCall: FCSDKCall) async {
        var fcsdkCall = fcsdkCall
        fcsdkCall.activeCall = false
        await self.contactService?.editCall(fcsdkCall: fcsdkCall)
    }
    
    /// Removes all calls from the contact service.
    @MainActor
    func removeAllCalls() async {
        await self.contactService?.deleteCalls()
    }
    
    /// Removes the background image for the call.
    @available(iOS 15, *)
    func removeBackground() async {
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.backgroundImage = nil
            self.virtualBackgroundMode = .image
        }
        await fcsdkCall?.call?.removeBackgroundImage()
    }
    
    /// Sets the background image for the call.
    /// - Parameters:
    ///   - image: The image to set as the background.
    ///   - mode: The mode for the virtual background.
    @MainActor
    @available(iOS 15, *)
    func setBackgroundImage(_ image: UIImage? = nil, mode: VirtualBackgroundMode = .image) async {
        self.backgroundImage = image
        self.virtualBackgroundMode = mode
        await fcsdkCall?.call?.feedBackgroundImage(backgroundImage, mode: virtualBackgroundMode)
    }
}
