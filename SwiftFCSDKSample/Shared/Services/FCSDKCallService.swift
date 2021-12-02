//
//  FCSDKCallService.swift
//  SwiftFCSDKSample
//
//  Created by Cole M on 10/12/21.
//

import Foundation
import AVFoundation
import SwiftUI
import FCSDKiOS
import CallKit


class FCSDKCallService: NSObject, ObservableObject {
    
    var audioPlayer: AVAudioPlayer?
    var fcsdkCallViewModel: [ FCSDKCallViewModel ]?
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
    
    override init(){
        super.init()
    }
    
    
    deinit {
        self.fcsdkCall?.call?.delegate = nil
    }
    
    
    func setPhoneDelegate() {
        self.acbuc?.phone.delegate = self
    }
    
    
    func initializeCall(previewView: ACBView) async throws {
        await MainActor.run {
            self.hasStartedConnecting = true
            self.connectingDate = Date()
        }
        guard let uc = self.fcsdkCall?.acbuc else { throw OurErrors.nilACBUC }
        uc.phone.delegate = self
        try? uc.phone.setPreviewView(previewView)
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
        await MainActor.run {
            self.fcsdkCall?.call?.remoteView = self.fcsdkCall?.remoteView
            //        self.fcsdkCall?.call?.remoteBufferView = self.fcsdkCall?.remoteView
            self.fcsdkCall?.call?.enableLocalAudio(true)
            self.fcsdkCall?.call?.enableLocalVideo(true)
        }
        return self.fcsdkCall?.call
    }
    
    @MainActor
    func presentCommunicationSheet() async {
        self.presentCommunication = true
    }
    
    func answerFCSDKCall() async throws {
        try? await MainActor.run {
            self.hasConnected = true
            self.connectDate = Date()
            self.fcsdkCall?.call?.remoteView = self.fcsdkCall?.remoteView
            //        self.fcsdkCall?.call?.remoteBufferView = self.fcsdkCall?.remoteView
            guard let view = self.fcsdkCall?.previewView else { throw OurErrors.nilPreviewView }
            guard let uc = self.acbuc else { throw OurErrors.nilACBUC }
            try? uc.phone.setPreviewView(view)
        }
        
        do {
            try self.fcsdkCall?.call?.answer(withAudio: AppSettings.perferredAudioDirection(), andVideo: AppSettings.perferredVideoDirection())
        } catch {
            print("There was an error answering call Error: \(error)")
        }
    }
    
    
    func endFCSDKCall() async {
        self.fcsdkCall?.call?.end()
        self.fcsdkCall?.call?.end()
        await MainActor.run {
            self.hasEnded = true
            self.connectDate = nil
        }
    }
    
    func playRingtone() async {
        let path  = Bundle.main.path(forResource: "ringring", ofType: ".wav")
        let fileURL = URL(fileURLWithPath: path!)
        self.audioPlayer = try? AVAudioPlayer(contentsOf: fileURL)
        self.audioPlayer?.volume = 1.0
        self.audioPlayer?.numberOfLoops = -1
        self.audioPlayer?.prepareToPlay()
        self.audioPlayer?.play()
    }
    
    func stopRingtone() async {
        guard let player = self.audioPlayer else { return }
        player.stop()
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
}
