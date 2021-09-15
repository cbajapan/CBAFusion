//
//  CallKitManager.swift
//  SwiftFCSDKSample
//
//  Created by Cole M on 9/8/21.
//

import Foundation
import CallKit
import ACBClientSDK
import AVFAudio

enum CallKitErrors: Swift.Error {
    case failedRequestTransaction(String)
}

@MainActor
final class CallKitManager: NSObject, ObservableObject {
    
    let callController = CXCallController()
    @Published var calls = [FCSDKCall]()
    
    func makeCall(handle: String, hasVideo: Bool = false) async {
        let handle = CXHandle(type: .phoneNumber, value: handle)
        let startCallAction = CXStartCallAction(call: UUID(), handle: handle)
        startCallAction.isVideo = hasVideo
        let transaction = CXTransaction()
        transaction.addAction(startCallAction)
        
        try? await requestTransaction(transaction)
    }
    
    func finishEnd(call: FCSDKCall) async {
        let endCallAction = CXEndCallAction(call: call.uuid)
        let transaction = CXTransaction()
        transaction.addAction(endCallAction)
        
        try? await requestTransaction(transaction)
    }
    
    func setCallOnHold(call: FCSDKCall, onHold: Bool) async {
        let hold = CXSetHeldCallAction(call: call.uuid, onHold: onHold)
        let transaction = CXTransaction()
        transaction.addAction(hold)
        
        try? await requestTransaction(transaction)
    }
    
    
    
    private func requestTransaction(_ transaction: CXTransaction) async throws {
        do {
            try await callController.request(transaction)
        } catch {
            throw CallKitErrors.failedRequestTransaction("There was an error in \(#function) Error: \(error)")
        }
    }
    
    func callWithUUID(uuid: UUID) -> FCSDKCall? {
        guard let index = calls.firstIndex(where: { $0.uuid == uuid }) else { return nil }
        return calls[index]
    }
    
    func addCalls(call: FCSDKCall) {
        calls.append(call)
    }
    
    func removeCall(call: FCSDKCall) async {
        guard let index = calls.firstIndex(where: { $0 === call }) else { return }
        calls.remove(at: index)
    }
    
    func removeAllCalls() {
        calls.removeAll()
    }
    
}




final class FCSDKCall: NSObject, ObservableObject, ACBClientCallDelegate, ACBClientPhoneDelegate {
    
    var audioPlayer: AVAudioPlayer?
    var lastIncomingCall: ACBClientCall?
    var callIdentifier: UUID?
    
    @Published var uuid: UUID
    @Published var handle: String?
    @Published var isOutgoing: Bool
    @Published var previewView: ACBView?
    @Published var videoView: ACBView?
    
    var acbuc: ACBUC?
    var call: ACBClientCall?
    
    //Callbacks
    var stateDidChange: (() -> Void)?
    var hasStartedConnectingDidChange: (() -> Void)?
    var hasConnectedDidChange: (() -> Void)?
    var hasEndedDidChange: (() -> Void)?
    
    
    @Published var connectingDate: Date? {
        didSet {
            stateDidChange?()
            hasStartedConnectingDidChange?()
        }
    }
    
    @Published var connectDate: Date? {
        didSet {
            stateDidChange?()
            hasConnectedDidChange?()
        }
    }
    
    @Published var endDate: Date? {
        didSet {
            stateDidChange?()
            hasEndedDidChange?()
        }
    }
    
    @Published var isOnHold = false {
        didSet {
            stateDidChange?()
        }
    }
    
    //Derived properties
    
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
    
    init(uuid: UUID, isOutgoing: Bool = false) {
        self.uuid = uuid
        self.isOutgoing = isOutgoing
    }
    
    
    func startFCSDKCall() {
        let phone = AuthenticationService.shared.acbuc?.phone()
        phone?.delegate = self
        phone?.previewView = previewView
        
        
        self.requestMicrophoneAndCameraPermissionFromAppSettings()
        
        let outboundCall = AuthenticationService.shared.acbuc?.clientPhone?.createCall(
            toAddress: self.handle,
            withAudio: AppSettings.perferredAudioDirection(),
            video: AppSettings.perferredVideoDirection(),
            delegate: self
        )
        outboundCall?.videoView = videoView
        
        self.call = outboundCall
        
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


extension FCSDKCall {
    
    
    func callDidReceiveMediaChangeRequest(_ call: ACBClientCall?) {
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
    
    func stopRingingIfNoOtherCallIsRinging(call: ACBClientCall?) {
        if (self.lastIncomingCall != nil) && (self.lastIncomingCall != call) {
            return
        }
        
        let status = self.call?.status
        if (status == .ringing) || (status == .alerting) {
            return
        }
        
        stopRingtone()
    }
    
    func updateUIForEndedCall(call: ACBClientCall) {
        if call == self.lastIncomingCall {
            self.lastIncomingCall = nil
            //Need Alert View
            //            self.lastIncomingCallAlert
            //Need Local Notification Maybe???
            
            self.stopRingingIfNoOtherCallIsRinging(call: nil)
            self.switchToNotInCallUI()
            
        }
    }
    
    func switchToNotInCallUI() {
        //TODO: - Hide any UI that is needed
    }
    
    func call(_ call: ACBClientCall?, didChange status: ACBClientCallStatus) {
        switch status {
        case .setup:
            self.playRingtone()
        case .alerting:
            break
        case .ringing:
            break
        case .mediaPending:
            break
        case .inCall:
            guard let c = call else { return }
            self.stopRingingIfNoOtherCallIsRinging(call: c)
        case .timedOut:
            guard let c = call else { return }
            self.updateUIForEndedCall(call: c)
            if self.callIdentifier != nil {
                self.call?.end()
                self.lastIncomingCall?.end()
            }
            self.callIdentifier = nil
        case .busy:
            guard let c = call else { return }
            self.updateUIForEndedCall(call: c)
            if self.callIdentifier != nil {
                self.call?.end()
                self.lastIncomingCall?.end()
            }
            self.callIdentifier = nil
        case .notFound:
            break
        case .error:
            break
        case .ended:
            guard let c = call else { return }
            self.updateUIForEndedCall(call: c)
            if self.callIdentifier != nil {
                self.call?.end()
                self.lastIncomingCall?.end()
            }
            self.callIdentifier = nil
        }
    }
    
    
    
    //Receive calls with ACBClientSDK
    func phone(_ phone: ACBClientPhone?, didReceive call: ACBClientCall?) {
        
    }
    
    
    
    
}
