//
//  PushController.swift
//  CBAFusion
//
//  Created by Cole M on 9/7/21.
//

import Foundation
import PushKit
import CallKit
import UIKit
import FCSDKiOS

class AppDelegate: NSObject, UIApplicationDelegate, ObservableObject {
    let pushRegistry = PKPushRegistry(queue: .main)
    let callKitManager = CallKitManager()
    var providerDelegate: ProviderDelegate?
    let window = UIWindow(frame: UIScreen.main.bounds)
    
    // MARK: - UIApplicationDelegate
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        self.registerForPushNotifications()
        self.voipRegistration()
        let hasLaunched = UserDefaults.standard.bool(forKey: "hasLaunched")
        print("INIT \(hasLaunched)")
        if hasLaunched {
            print("Not going to delete sessionID")
        } else {
            print("We are going to delete sessionID")
            KeychainItem.deleteKeychainItems()
            UserDefaults.standard.set(true, forKey: "hasLaunched")
        }
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        guard let handle = url.startCallHandle else {
            print("Could not determine start call handle from URL: \(url)")
            return false
        }
        Task {
            await callKitManager.makeCall(uuid: UUID(), handle: handle)
        }
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
        Task {
            await callKitManager.makeCall(uuid: UUID(), handle: handle, hasVideo: video)
        }
        return true
    }
    
    
    //TODO: We are not using push kit yet for remote notifications
    // Register for VoIP notifications
    func voipRegistration() {
        
        // Create a push registry object
        let mainQueue = DispatchQueue.main
        let voipRegistry: PKPushRegistry = PKPushRegistry(queue: mainQueue)
        voipRegistry.delegate = self
        voipRegistry.desiredPushTypes = [PKPushType.voIP]
    }
    
    //TODO: We are not using push kit yet for remote notifications
    // Push notification setting
    func getNotificationSettings() {
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                UNUserNotificationCenter.current().delegate = self
                guard settings.authorizationStatus == .authorized else { return }
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        } else {
            let settings = UIUserNotificationSettings(types: [.sound, .alert, .badge], categories: nil)
            UIApplication.shared.registerUserNotificationSettings(settings)
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
    
    //TODO: We are not using push kit yet for remote notifications
    // Register push notification
    func registerForPushNotifications() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge]) {
                [weak self] granted, error in
                guard let _ = self else {return}
                guard granted else { return }
                self?.getNotificationSettings()
            }
    }
}

// MARK:- UNUserNotificationCenterDelegate
extension AppDelegate : UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let userInfo = response.notification.request.content.userInfo
        print("didReceive ======", userInfo)
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        let userInfo = notification.request.content.userInfo
        print("willPresent ======", userInfo)
        completionHandler([.list, .sound, .badge])
    }
}

// MARK: - PKPushRegistryDelegate
//TODO: Setup Push Kit for CallKit notifications while app is in the background
extension AppDelegate: PKPushRegistryDelegate {
    
    //     Handle updated push credentials
    func pushRegistry(_ registry: PKPushRegistry, didUpdate credentials: PKPushCredentials, for type: PKPushType) {
        print(credentials.token)
        let deviceToken = credentials.token.map { String(format: "%02x", $0) }.joined()
        print("pushRegistry -> deviceToken :\(deviceToken)")
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        print("pushRegistry:didInvalidatePushTokenForType:")
    }
    
    // Handle incoming pushes
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
        let receivedCall = FCSDKCall(
            handle: handle,
            hasVideo: hasVideo,
            previewView: nil,
            remoteView: nil,
            uuid: uuid,
            acbuc: nil,
            call: nil
        )
        Task {
            await displayIncomingCall(fcsdkCall: receivedCall, isAutoAnswer: UserDefaults.standard.bool(forKey: "AutoAnswer"))
            await self.callKitManager.addCall(call: receivedCall)
        }
    }
    
    // MARK: - PKPushRegistryDelegate Helper
    
    /// Display the incoming call to the user.
    func displayIncomingCall(fcsdkCall: FCSDKCall, isAutoAnswer: Bool) async {
        await providerDelegate?.reportIncomingCall(fcsdkCall: fcsdkCall, isAutoAnswer: isAutoAnswer)
    }
}
