//
//  PushController.swift
//  SwiftFCSDKSample
//
//  Created by Cole M on 9/7/21.
//

import Foundation
import PushKit
import CallKit



final class PushController: NSObject, PKPushRegistryDelegate {
    
    var callkitController: CallKitController?
    let pushRegistry = PKPushRegistry(queue: DispatchQueue.main)
    
    
    override init() {
        self.callkitController = CallKitController()
        super.init()
        self.pushRegistry.delegate = self
        self.pushRegistry.desiredPushTypes = [.voIP]
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        
    }
    
    
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType) {
        if let uuidString = payload.dictionaryPayload["UUID"] as? String,
           let identifier = payload.dictionaryPayload["identifier"] as? String,
           let uuid = UUID(uuidString: uuidString) {
            let update = CXCallUpdate()
            update.remoteHandle = CXHandle(type: .generic, value: identifier)
            update.hasVideo = true
            update.localizedCallerName = identifier
            self.callkitController?.provider?.reportNewIncomingCall(with: uuid, update: update) { error in
                print(error, "ERROR")
            }
        }
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        print("token invalidated")
    }
    
    //    func reportIncomingCall(uuid: UUID, handle: Stirng, hasVideo: Bool, completion: ((NSError?) -> Void)? = nil) {
    //
    //    }
}
