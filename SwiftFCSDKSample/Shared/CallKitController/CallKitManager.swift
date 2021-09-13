//
//  CallKitManager.swift
//  SwiftFCSDKSample
//
//  Created by Cole M on 9/8/21.
//

import Foundation
import CallKit

enum CallKitErrors: Swift.Error {
    case failedRequestTransaction(String)
}

@MainActor
final class CallKitManager: NSObject, ObservableObject {
    
    let callController = CXCallController()
    @Published private(set) var calls = [FCSDKCall]()
    
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
    
    func addCalls(call: FCSDKCall) async {
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




final class FCSDKCall: ObservableObject {
    
    @Published var uuid = UUID()
    @Published var handle: String
    @Published var isOutgoing: Bool
    
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
    
    init(handle: String, isOutgoing: Bool = false) {
        self.handle = handle
        self.isOutgoing = isOutgoing
    }
    
    func startFCSDKCall(completion: ((_ success: Bool) -> Void)?) {
        completion?(true)
        
        
        //This is just a simulation of connection
        DispatchQueue.main.asyncAfter(wallDeadline: DispatchWallTime.now() + 3) {
            self.hasStartedConnecting = true
            
            DispatchQueue.main.asyncAfter(wallDeadline: DispatchWallTime.now() + 1.5) {
                self.hasConnected = true
            }
        }
    }
    
    func answerFCSDKCall() {
        hasConnected = true
    }
    
    func endFCSDKCall() {
        hasEnded = true
    }
    
}
