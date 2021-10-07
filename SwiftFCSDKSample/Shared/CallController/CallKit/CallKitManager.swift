//
//  CallKitManager.swift
//  SwiftFCSDKSample
//
//  Created by Cole M on 9/8/21.
//

import Foundation
import CallKit
import SwiftFCSDK
import AVFAudio

enum CallKitErrors: Swift.Error {
    case failedRequestTransaction(String)
}





@MainActor
final class CallKitManager: NSObject, ObservableObject {
    
    let callController = CXCallController()
    var calls = [FCSDKCall]()
    
    
    func initializeCall(call: FCSDKCall) async {
        await passCallToProvider(call: call)
        await makeCall(handle: call.handle, hasVideo: call.hasVideo)
    }

    func passCallToProvider(call: FCSDKCall) async {
        let call = ["call": call]
        NotificationCenter.default.post(name: NSNotification.Name("call"), object: call)
    }
    
    func makeCall(handle: String, hasVideo: Bool = false) async {
        let handle = CXHandle(type: .phoneNumber, value: handle)
        let startCallAction = CXStartCallAction(call: UUID(), handle: handle)
        startCallAction.isVideo = hasVideo
        let transaction = CXTransaction()
        transaction.addAction(startCallAction)
        
        //Pass call object to provider
        
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
