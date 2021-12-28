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

class FCSDKCallService: NSObject, ObservableObject {
    
    var appDelegate: AppDelegate?
    @Published var hasVideo: Bool = false
    @Published var acbuc: ACBUC?
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
    @Published var audioDeviceManager: ACBAudioDeviceManager?
    
    deinit {
        self.fcsdkCall?.call?.delegate = nil
    }
    
    
    func setPhoneDelegate() {
        self.acbuc?.phone.delegate = self
    }
    
    
    func initializeCall(previewView: SamplePreviewVideoCallView) async throws {
        await MainActor.run {
            self.hasStartedConnecting = true
            self.connectingDate = Date()
        }
        guard let uc = self.fcsdkCall?.acbuc else { throw OurErrors.nilACBUC }
        uc.phone.delegate = self
        uc.phone.previewView = previewView
    }
    
    
    func startFCSDKCall() async throws -> ACBClientCall? {
        guard let uc = self.fcsdkCall?.acbuc else { throw OurErrors.nilACBUC }
        let outboundCall = uc.phone.createCall(
            toAddress: self.fcsdkCall?.handle,
            withAudio: AppSettings.perferredAudioDirection(),
            video: AppSettings.perferredVideoDirection(),
            delegate: self
        )
        
        self.fcsdkCall?.call = outboundCall
        self.fcsdkCall?.call?.enableLocalAudio(true)
        self.fcsdkCall?.call?.enableLocalVideo(true)
        await MainActor.run {
            self.fcsdkCall?.call?.remoteView = self.fcsdkCall?.remoteView
            //            self.fcsdkCall?.call?.remoteBufferView = self.fcsdkCall?.remoteView
        }
        return self.fcsdkCall?.call
    }
    
    @MainActor
    func presentCommunicationSheet() async {
        self.presentCommunication = true
    }
    
    func answerFCSDKCall() async throws {
        await MainActor.run {
            self.hasConnected = true
            self.connectDate = Date()
        }
        self.fcsdkCall?.call?.remoteView = self.fcsdkCall?.remoteView
        //            self.fcsdkCall?.call?.remoteBufferView = self.fcsdkCall?.remoteView
        guard let view = self.fcsdkCall?.previewView else { throw OurErrors.nilPreviewView }
        guard let uc = self.acbuc else { throw OurErrors.nilACBUC }
        uc.phone.previewView = view
        do {
            try self.fcsdkCall?.call?.answer(withAudio: AppSettings.perferredAudioDirection(), andVideo: AppSettings.perferredVideoDirection())
        } catch {
            print("There was an error answering call Error: \(error)")
        }
    }
    
    
    func endFCSDKCall() async {
        self.fcsdkCall?.call?.end()
        self.fcsdkCall?.call = nil
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
            self.audioDeviceManager?.setAudioDevice(device: .earpiece)
        case .speaker:
            self.audioDeviceManager?.setAudioDevice(device: .speakerphone)
        }
    }
    
    func selectResolution(res: ResolutionOptions) {
        switch res {
        case .auto:
            self.acbuc?.phone.preferredCaptureResolution = ACBVideoCapture.autoResolution;
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
