//
//  CallKitManager.swift
//  CBAFusion
//
//  Created by Cole M on 9/8/21.
//

import Foundation
import CallKit
import FCSDKiOS
import AVFAudio
import Logging

enum CallKitErrors: Swift.Error {
    case failedRequestTransaction(String)
}

class CallKitManager: NSObject, ObservableObject {
    
    let callController = CXCallController()
    var logger: Logger
    
    override init() {
        self.logger = Logger(label: "\(Constants.BUNDLE_IDENTIFIER) - CallKitManager - ")
        super.init()
    }


    func initializeCall(_ call: FCSDKCall) async {
        await self.makeCall(uuid: call.id, handle: call.handle, hasVideo: call.hasVideo)
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
        let endCallAction = CXEndCallAction(call: call.id)
        let transaction = CXTransaction()
        transaction.addAction(endCallAction)
        await requestTransaction(transaction)
    }
    
    func setCallOnHold(call: FCSDKCall, onHold: Bool) async {
        let hold = CXSetHeldCallAction(call: call.id, onHold: onHold)
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
    
    
    ///CallKit Transaction Request Error Codes
    ///case unknown = 0
    ///case unentitled = 1
    ///case unknownCallProvider = 2
    ///case emptyTransaction = 3
    ///case unknownCallUUID = 4
    ///case callUUIDAlreadyExists = 5
    ///case invalidActions = 6
    ///case maximunCallGroupsReached = 7
    private func requestTransaction(_ transaction: CXTransaction) async {
        do {
            try await callController.request(transaction)
        } catch {
            self.logger.error("Error requesting transaction: \(error.localizedDescription)")
        }
    }
}
