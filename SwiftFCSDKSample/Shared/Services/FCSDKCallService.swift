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
    @Published var presentCommunication: ActiveSheet?
    
    override init(){
        super.init()
    }

    
    func setPhoneDelegate() {
        self.acbuc?.clientPhone.delegate = self
    }
    
    func initializeCall(previewView: ACBView) async throws {
        await self.requestMicrophoneAndCameraPermissionFromAppSettings()
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.hasStartedConnecting = true
        }
        guard let uc = self.fcsdkCall?.acbuc else { throw OurErrors.nilACBUC }
        uc.clientPhone.delegate = self
        try? uc.clientPhone.setPreviewView(previewView)
    }
    
    func startFCSDKCall() async throws -> ACBClientCall? {
        guard let uc = self.fcsdkCall?.acbuc else { throw OurErrors.nilACBUC }
        let outboundCall = uc.clientPhone.createCall(
            toAddress: self.fcsdkCall?.handle,
            withAudio: AppSettings.perferredAudioDirection(),
            video: AppSettings.perferredVideoDirection(),
            delegate: self
        )
        
        self.fcsdkCall?.call = outboundCall
        self.fcsdkCall?.call?.remoteView = self.fcsdkCall?.remoteView
        self.fcsdkCall?.call?.enableLocalAudio(true)
        self.fcsdkCall?.call?.enableLocalVideo(true)
        return self.fcsdkCall?.call
    }
    
    func presentCommunicationSheet() async {
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }
            if strongSelf.presentCommunication != .communincationSheet {
                strongSelf.presentCommunication = .communincationSheet
            }
        }
    }
    
    func answerFCSDKCall() async throws {
        await self.requestMicrophoneAndCameraPermissionFromAppSettings()
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.hasConnected = true
        }
        guard let uc = self.acbuc else { throw OurErrors.nilACBUC }
        
        //We pass our view Controllers view to the preview here
        self.fcsdkCall?.call?.remoteView = self.fcsdkCall?.remoteView
        guard let view = self.fcsdkCall?.previewView else { throw OurErrors.nilPreviewView }
        try? uc.clientPhone.setPreviewView(view)
        do {
            try  self.fcsdkCall?.call?.answer(withAudio: AppSettings.perferredAudioDirection(), andVideo: AppSettings.perferredVideoDirection())
        } catch {
            print(error)
        }
    }
    
    func endFCSDKCall() {
        self.fcsdkCall?.call?.end()
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.hasEnded = true
        }
    }
    
    func requestMicrophoneAndCameraPermissionFromAppSettings() async {
        let requestMic = AppSettings.perferredAudioDirection() == .sendOnly || AppSettings.perferredAudioDirection() == .sendAndReceive
        let requestCam = AppSettings.perferredVideoDirection() == .sendOnly || AppSettings.perferredVideoDirection() == .sendAndReceive
        ACBClientPhone.requestMicrophoneAndCameraPermission(requestMic, video: requestCam)
    }
    
    func playRingtone() {
        let path  = Bundle.main.path(forResource: "ringring", ofType: ".wav")
        let fileURL = URL(fileURLWithPath: path!)
        self.audioPlayer = try? AVAudioPlayer(contentsOf: fileURL)
        self.audioPlayer?.volume = 1.0
        self.audioPlayer?.numberOfLoops = -1
        self.audioPlayer?.prepareToPlay()
        self.audioPlayer?.play()
    }
    
    func stopRingtone() {
        guard let player = self.audioPlayer else { return }
        player.stop()
    }
    
    func hasStartedConnectingDidChange(provider: CXProvider, id: UUID, date: Date) async {
        provider.reportOutgoingCall(with: id, startedConnectingAt: date)
    }
    
    func hasConnectedDidChange(provider: CXProvider, id: UUID, date: Date) async {
        provider.reportOutgoingCall(with: id, connectedAt: date)
    }
}
