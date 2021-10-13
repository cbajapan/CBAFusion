//
//  PushController.swift
//  SwiftFCSDKSample
//
//  Created by Cole M on 9/7/21.
//

import Foundation
import PushKit
import CallKit
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate, ObservableObject {
    let pushRegistry = PKPushRegistry(queue: .main)
    let callKitManager = CallKitManager()
    var providerDelegate: ProviderDelegate?

    // MARK: - UIApplicationDelegate

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        pushRegistry.delegate = self
        pushRegistry.desiredPushTypes = [.voIP]
        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        guard let handle = url.startCallHandle else {
            print("Could not determine start call handle from URL: \(url)")
            return false
        }

//        callManager.startCall(handle: handle)
        return true
    }

    private func application(_ application: UIApplication,
                             continue userActivity: NSUserActivity,
                             restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        guard let handle = userActivity.startCallHandle else {
            print("Could not determine start call handle from user activity: \(userActivity)")
            return false
        }

        guard let video = userActivity.video else {
            print("Could not determine video from user activity: \(userActivity)")
            return false
        }

//        callManager.startCall(handle: handle, video: video)
        return true
    }

    // MARK: - UISceneSession Lifecycle

    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

}

// MARK: - PKPushRegistryDelegate
extension AppDelegate: PKPushRegistryDelegate {

    func pushRegistry(_ registry: PKPushRegistry, didUpdate credentials: PKPushCredentials, for type: PKPushType) {
        /*
         Store push credentials on the server for the active user.
         For sample app purposes, do nothing, because everything is done locally.
         */
        print("Registry: \(registry.debugDescription)")
        print("Credentials: \(credentials.debugDescription)")
        print("Type: \(type.rawValue)")
    }

    func pushRegistry(_ registry: PKPushRegistry,
                      didReceiveIncomingPushWith payload: PKPushPayload,
                      for type: PKPushType, completion: @escaping () -> Void) {
        defer {
            completion()
        }

        guard type == .voIP,
            let uuidString = payload.dictionaryPayload["UUID"] as? String,
            let handle = payload.dictionaryPayload["handle"] as? String,
            let hasVideo = payload.dictionaryPayload["hasVideo"] as? Bool,
            let uuid = UUID(uuidString: uuidString)
            else {
                return
        }
//        let receivedCall = FCSDKCall(
//            handle: handle,
//            hasVideo: hasVideo,
//            previewView: fcsdkCall?.previewView ?? SamplePreviewVideoCallView(),
//            remoteView: fcsdkCall?.remoteView ?? SampleBufferVideoCallView(),
//            uuid: UUID(uuidString: uuidString) ?? UUID(),
//            acbuc: uc,
//            call: call!
//        )
//        displayIncomingCall(fcsdkCall: receivedCall)
    }

    // MARK: - PKPushRegistryDelegate Helper

    /// Display the incoming call to the user.
    func displayIncomingCall(fcsdkCall: FCSDKCall) async {
        await providerDelegate?.reportIncomingCall(fcsdkCall: fcsdkCall)
    }

}
