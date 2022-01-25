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
import Logging
import AVKit

class AppDelegate: NSObject, UIApplicationDelegate, ObservableObject {
    let pushRegistry = PKPushRegistry(queue: .main)
    let callKitManager = CallKitManager()
    var providerDelegate: ProviderDelegate?
    let window = UIWindow(frame: UIScreen.main.bounds)
    var logger = Logger(label: "\(Constants.BUNDLE_IDENTIFIER) - App Delegate - ")
    // MARK: - UIApplicationDelegate
    var audioPlayer: AVAudioPlayer?
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        self.registerForPushNotifications()
        self.voipRegistration()
        let hasLaunched = UserDefaults.standard.bool(forKey: "hasLaunched")
        if hasLaunched {
            self.logger.info("Not going to delete sessionID")
        } else {
            self.logger.info("We are going to delete sessionID")
            KeychainItem.deleteKeychainItems()
            UserDefaults.standard.set(true, forKey: "hasLaunched")
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(startRing), name: NSNotification.Name(rawValue: "startRing"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(stopRing), name: NSNotification.Name(rawValue: "stopRing"), object: nil)
        return true
    }
    
    // Unfortunately SwiftUI Has a weird bug where AVAudioPlayer wont loop. So we are going to use notification center to handle it
    // outside of SwiftUI
    @objc func startRing() {
        do {
                  try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .videoChat, options: .defaultToSpeaker)
                  try AVAudioSession.sharedInstance().setActive(true)
                  try AVAudioSession.sharedInstance().setPreferredSampleRate(44100.0)
                  try AVAudioSession.sharedInstance().setPreferredIOBufferDuration(0.005)
              } catch {
                  self.logger.error("Error Starting ACBAudioDeviceManager \(error)")
              }
        let path  = Bundle.main.path(forResource: "ringring", ofType: ".wav")
        let fileURL = URL(fileURLWithPath: path!)
        self.audioPlayer = try! AVAudioPlayer(contentsOf: fileURL)
//        self.providerDelegate?.fcsdkCallService.startAudioSession()
        self.audioPlayer?.volume = 1.0
        self.audioPlayer?.numberOfLoops = -1
        self.audioPlayer?.prepareToPlay()
        self.audioPlayer?.play()
    }
    
    @objc func stopRing() {
        self.audioPlayer?.stop()
        self.audioPlayer = nil
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        guard let handle = url.startCallHandle else {
            self.logger.error("Could not determine start call handle from URL: \(url)")
            return false
        }
        Task {
            await callKitManager.makeCall(uuid: UUID(), handle: handle)
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
        self.logger.info("didReceive ====== \(userInfo)")
        switch response.actionIdentifier {
        case "action1":
            self.logger.info("Action First Tapped")
        case "action2":
            self.logger.info("Action Second Tapped")
        default:
            break
        }
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        let userInfo = notification.request.content.userInfo
        self.logger.info("willPresent ====== \(userInfo)")
        completionHandler([.banner, .sound, .badge])
    }
}

// MARK: - PKPushRegistryDelegate
//TODO: Setup Push Kit for CallKit notifications while app is in the background
extension AppDelegate: PKPushRegistryDelegate {
    
    //     Handle updated push credentials
    func pushRegistry(_ registry: PKPushRegistry, didUpdate credentials: PKPushCredentials, for type: PKPushType) {
        //        self.logger.info(credentials.token)
        let deviceToken = credentials.token.map { String(format: "%02x", $0) }.joined()
        self.logger.info("pushRegistry -> deviceToken :\(deviceToken)")
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        self.logger.info("pushRegistry:didInvalidatePushTokenForType: \(type)")
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
            id: uuid,
            handle: handle,
            hasVideo: hasVideo,
            previewView: nil,
            remoteView: nil,
            acbuc: nil,
            call: nil
        )
        Task {
            await displayIncomingCall(fcsdkCall: receivedCall)
        }
    }
    
    // MARK: - PKPushRegistryDelegate Helper
    
    /// Display the incoming call to the user.
    func displayIncomingCall(fcsdkCall: FCSDKCall) async {
        await providerDelegate?.reportIncomingCall(fcsdkCall: fcsdkCall)
    }
}
