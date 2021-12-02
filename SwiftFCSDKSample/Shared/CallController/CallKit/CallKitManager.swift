//
//  CallKitManager.swift
//  SwiftFCSDKSample
//
//  Created by Cole M on 9/8/21.
//

import Foundation
import CallKit
import FCSDKiOS
import AVFAudio

enum CallKitErrors: Swift.Error {
    case failedRequestTransaction(String)
}



class CallKitManager: NSObject, ObservableObject {
    
    let callController = CXCallController()
    var calls = [FCSDKCall]()
    
    
    override init() {
        super.init()
    }

    
    func initializeCall(_ call: FCSDKCall) async {
        await self.makeCall(uuid: call.uuid, handle: call.handle, hasVideo: call.hasVideo)
    }
    func makeCall(uuid: UUID, handle: String, hasVideo: Bool = false) async {
        let handle = CXHandle(type: .phoneNumber, value: handle)
        let startCallAction = CXStartCallAction(call: uuid, handle: handle)
        startCallAction.isVideo = hasVideo
        let transaction = CXTransaction()
        transaction.addAction(startCallAction)
        await requestTransaction(transaction)
    }


    func finishEnd(call: FCSDKCall) async {
        let endCallAction = CXEndCallAction(call: call.uuid)
        let transaction = CXTransaction()
        transaction.addAction(endCallAction)
        await requestTransaction(transaction)
    }
    
    func setCallOnHold(call: FCSDKCall, onHold: Bool) async {
        let hold = CXSetHeldCallAction(call: call.uuid, onHold: onHold)
        let transaction = CXTransaction()
        transaction.addAction(hold)
         await requestTransaction(transaction)
    }
    
    func sendDTMF(uuid: UUID, digit: String) async {
        let action = CXPlayDTMFCallAction(call: uuid, digits: digit, type: .singleTone)
        let transaction = CXTransaction()
        transaction.addAction(action)
        await requestTransaction(transaction)
    }
    
    
    
    private func requestTransaction(_ transaction: CXTransaction) async {
        do {
            try await callController.request(transaction)
        } catch {
            print("Error requesting transaction:", error)
        }
    }
    
    func callWithUUID(uuid: UUID) async -> FCSDKCall? {
        guard let index = calls.firstIndex(where: { $0.uuid == uuid }) else { return nil }
        return calls[index]
    }
    func addCall(call: FCSDKCall) async {
        calls.append(call)
    }
    
    func removeCall(call: FCSDKCall) async {
        guard let index = calls.firstIndex(where: { $0 === call }) else { return }
        calls.remove(at: index)
    }
    
    func removeAllCalls() async {
        calls.removeAll()
    }
}
