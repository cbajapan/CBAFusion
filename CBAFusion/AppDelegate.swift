//
//  PushController.swift
//  CBAFusion
//
//  Created by Cole M on 9/7/21.
//

import Foundation
import PushKit
import CallKit
@preconcurrency import UIKit
import FCSDKiOS
import Logging
import AVKit


extension AppDelegate {
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        if #unavailable(iOS 14) {
            let sceneConfig = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
            sceneConfig.delegateClass = SceneDelegate.self // 👈🏻
            return sceneConfig
        } else {
            return .init()
        }
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }
}

class AppDelegate: UIResponder, UIApplicationDelegate {
    
    let pushRegistry = PKPushRegistry(queue: .main)
    var providerDelegate: ProviderDelegate?
    let window = UIWindow(frame: UIScreen.main.bounds)
    var logger = Logger(label: "\(Constants.BUNDLE_IDENTIFIER) - App Delegate - ")
    
    
    // MARK: - UIApplicationDelegate
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        UIApplication.shared.applicationIconBadgeNumber = 0
        
        self.registerForPushNotifications()
        let hasLaunched = UserDefaults.standard.bool(forKey: "hasLaunched")
        if hasLaunched {
            self.logger.info("Not going to delete sessionID")
        } else {
            self.logger.info("We are going to delete sessionID")
            KeychainItem.deleteKeychainItems()
            UserDefaults.standard.set(true, forKey: "hasLaunched")
        }
        return true
    }
    
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        guard let handle = url.startCallHandle else {
            self.logger.error("Could not determine start call handle from URL: \(url)")
            return false
        }
        Task {
            await CallKitManager.shared.makeCall(uuid: UUID(), handle: handle)
        }
        return true
    }
    
    @MainActor
    func getNotificationSettings() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        UNUserNotificationCenter.current().delegate = self
        guard settings.authorizationStatus == .authorized else { return }
        UIApplication.shared.registerForRemoteNotifications()
    }
    
    func registerForPushNotifications() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            if try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) {
                await getNotificationSettings()
            }
        }
    }
}

//// MARK:- UNUserNotificationCenterDelegate
extension AppDelegate : UNUserNotificationCenterDelegate {
    
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let userInfo = response.notification.request.content.userInfo
        print("didReceive ====== \(userInfo)")
        switch response.actionIdentifier {
        case "action1":
            print("Action First Tapped")
        case "action2":
            print("Action Second Tapped")
        default:
            break
        }
        completionHandler()
    }
    
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        let userInfo = notification.request.content.userInfo
        print("willPresent ====== \(userInfo)")
        if #available(iOS 14, *) {
            completionHandler([.banner, .sound, .badge])
        } else {
            completionHandler([.sound, .badge])
        }
    }
    /// Display the incoming call to the user.
    func displayIncomingCall(fcsdkCall: FCSDKCall) async {
        ACBAudioDeviceManager.useManualAudioForCallKit()
        await providerDelegate?.reportIncomingCall(fcsdkCall: fcsdkCall)
    }
}
