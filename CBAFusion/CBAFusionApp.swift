//
//  CBAFusion.swift
//  CBAFusion
//
//  Created by Cole M on 8/30/21.
//

import SwiftUI
import UIKit
import AVKit
import FCSDKiOS
import Intents
import Logging



@main
struct CBAFusionApp {
    static func main() {
        if #available(iOS 14.0, *) {
            CBAFusion.main()
        } else {
            UIApplicationMain(
                CommandLine.argc,
                CommandLine.unsafeArgv,
                nil,
                NSStringFromClass(AppDelegate.self))
        }
    }
}

@available(iOS 14.0, *)
struct CBAFusion: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @Environment(\.scenePhase) var scenePhase
    @StateObject private var authenticationService = AuthenticationService()
    @StateObject private var fcsdkCallService = FCSDKCallService.shared
    @StateObject private var monitor = NetworkMonitor(type: .all)
    @StateObject private var callKitManager = CallKitManager.shared
    @StateObject private var contactService = ContactService()
    @StateObject private var aedService = AEDService()
    @StateObject private var backgrounds = Backgrounds.shared
    @StateObject private var pipStateObject = PipStateObject.shared
    
    @State var providerDelegate: ProviderDelegate?
    @State var callIntent = false
    @AppStorage("Server") var servername = ""
    @AppStorage("Username") var username = ""
    var logger: Logger
    
    init() {
        self.logger = Logger(label: "\(Constants.BUNDLE_IDENTIFIER) - Main App - ")
    }
    
    func requestMicrophoneAndCameraPermissionFromAppSettings() async {
        let requestMic = AppSettings.perferredAudioDirection() == .sendOnly || AppSettings.perferredAudioDirection() == .sendAndReceive
        let requestCam = AppSettings.perferredVideoDirection() == .sendOnly || AppSettings.perferredVideoDirection() == .sendAndReceive
        await ACBClientPhone.requestMicrophoneAndCameraPermission(requestMic, video: requestCam)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(monitor)
                .environmentObject(authenticationService)
                .environmentObject(callKitManager)
                .environmentObject(fcsdkCallService)
                .environmentObject(contactService)
                .environmentObject(aedService)
                .environmentObject(backgrounds)
                .environmentObject(pipStateObject)
                .onAppear {
                    fcsdkCallService.delegate = authenticationService
                    fcsdkCallService.appDelegate = delegate
                    fcsdkCallService.contactService = contactService
                    delegate.providerDelegate = ProviderDelegate(callKitManager: callKitManager, authenticationService: authenticationService, fcsdkCallService: fcsdkCallService)
                    if (UserDefaults.standard.string(forKey: MediaValue.keyAudioDirection.rawValue) == nil), (UserDefaults.standard.string(forKey: MediaValue.keyVideoDirection.rawValue) == nil) {
                        AppSettings.registerDefaults(.sendAndReceive, audio: .sendAndReceive)
                    }
                }
                .onContinueUserActivity(String(describing: INStartCallIntent.self)) { activity in
                    
                    callIntent = true
                    guard let handle = activity.startCallHandle else {
                        self.logger.error("Could not determine start call handle from user activity: \(activity)")
                        return
                    }
                    Task {
                        self.fcsdkCallService.destination = handle
                        self.fcsdkCallService.isOutgoing = true
                        self.fcsdkCallService.hasVideo = true
                        await reAuthFlowWithCallIntent()
                    }
                }
                .valueChanged(value: scenePhase) { phase in
                    switch phase {
                    case .active:
                        Task { @MainActor in
                            await self.requestMicrophoneAndCameraPermissionFromAppSettings()
                            if self.authenticationService.uc?.connection == false {
                                self.authenticationService.sessionExists = false
                            }
                            
                            if !callIntent {
                                if self.authenticationService.uc == nil && !self.authenticationService.sessionID.isEmpty,
                                   servername != "" && username != "" {
                                    await reAuthFlow()
                                }
                                if self.authenticationService.uc?.connection != nil {
                                    self.authenticationService.sessionExists = true
                                }
                            }
                            self.logger.info("DO WE HAVE A SESSION? \(self.authenticationService.sessionExists)")
                            
                        }
                    case .background:
                        break
                    case .inactive:
                        self.logger.info("ScenePhase: inactive")
                    @unknown default:
                        self.logger.info("ScenePhase: unexpected state")
                    }
                }
        }
    }
    func reAuthFlow() async {
        await self.authenticationService.loginUser(networkStatus: monitor.networkStatus())
        await self.fcsdkCallService.setPhoneDelegate()
    }
    
    func reAuthFlowWithCallIntent() async {
        await reAuthFlow()
        repeat {
            Task {
                if self.authenticationService.uc?.connection != false {
                    await fcsdkCallService.presentCommunicationSheet()
                    callIntent = false
                }
            }
        } while (self.authenticationService.uc?.connection == false)  
    }
}

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    private var authenticationService = AuthenticationService()
    private var fcsdkCallService = FCSDKCallService.shared
    private var monitor = NetworkMonitor(type: .all)
    private var callKitManager = CallKitManager.shared
    private var contactService = ContactService()
    private var aedService = AEDService()
    private var backgrounds = Backgrounds.shared
    private var pipStateObject = PipStateObject.shared
    var providerDelegate: ProviderDelegate?
    
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Add another view with content Text("From iOS 13") to test both block runs
        let contentView = ContentView()
            .environmentObject(monitor)
            .environmentObject(authenticationService)
            .environmentObject(callKitManager)
            .environmentObject(fcsdkCallService)
            .environmentObject(contactService)
            .environmentObject(aedService)
            .environmentObject(backgrounds)
            .environmentObject(pipStateObject)
            .onAppear {
                self.fcsdkCallService.delegate = self.authenticationService
                self.fcsdkCallService.contactService = self.contactService
                self.providerDelegate = ProviderDelegate(callKitManager: self.callKitManager, authenticationService: self.authenticationService, fcsdkCallService: self.fcsdkCallService)
                if (UserDefaults.standard.string(forKey: MediaValue.keyAudioDirection.rawValue) == nil), (UserDefaults.standard.string(forKey: MediaValue.keyVideoDirection.rawValue) == nil) {
                    AppSettings.registerDefaults(.sendAndReceive, audio: .sendAndReceive)
                }
            }
        
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = UIHostingController(rootView: contentView)
            self.window = window
            window.makeKeyAndVisible()
        }
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        //
    }
    
    func requestMicrophoneAndCameraPermissionFromAppSettings() async {
        let requestMic = AppSettings.perferredAudioDirection() == .sendOnly || AppSettings.perferredAudioDirection() == .sendAndReceive
        let requestCam = AppSettings.perferredVideoDirection() == .sendOnly || AppSettings.perferredVideoDirection() == .sendAndReceive
        await ACBClientPhone.requestMicrophoneAndCameraPermission(requestMic, video: requestCam)
    }
    
    func reAuthFlow() async {
        await self.authenticationService.loginUser(networkStatus: monitor.networkStatus())
        await self.fcsdkCallService.setPhoneDelegate()
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        Task { @MainActor in
            await self.requestMicrophoneAndCameraPermissionFromAppSettings()
            if self.authenticationService.uc?.connection == false {
                self.authenticationService.sessionExists = false
            }
            let servername = UserDefaults.standard.string(forKey: "Server")
            let username  = UserDefaults.standard.string(forKey: "Username")
            if self.authenticationService.uc == nil && !self.authenticationService.sessionID.isEmpty,
               servername != "" && username != "" {
                await reAuthFlow()
            }
            if self.authenticationService.uc?.connection != nil {
                self.authenticationService.sessionExists = true
            }
        }
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        //
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        //
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        //
    }
}

extension SceneDelegate : UNUserNotificationCenterDelegate {
    
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
