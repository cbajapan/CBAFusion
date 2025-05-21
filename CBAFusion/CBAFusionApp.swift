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

/// The main application struct for the CBAFusion app.
@available(iOS 14.0, *)
struct CBAFusion: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @Environment(\.scenePhase) var scenePhase
    
    // State objects for managing application state and services
    @StateObject private var authenticationService = AuthenticationService()
    @ObservedObject private var fcsdkCallService = FCSDKCallService.shared
    @ObservedObject private var callKitManager = CallKitManager.shared
    @StateObject private var contactService = ContactService()
    @StateObject private var aedService = AEDService()
    @StateObject private var backgroundObserver = BackgroundObserver()
    @ObservedObject private var pipStateObject = PipStateObject.shared
    @MainActor @StateObject private var pathState = NWPathState()
    
    @State private var providerDelegate: ProviderDelegate?
    @State private var callIntent = false
    
    // AppStorage properties for persistent user settings
    @AppStorage("Server") var servername = ""
    @AppStorage("Username") var username = ""
    
    // Logger for tracking application events
    var logger: Logger
    
    /// Initializes the CBAFusion app and sets up the logger.
    init() {
        self.logger = Logger(label: "\(Constants.BUNDLE_IDENTIFIER) - Main App - ")
    }
    
    /// Requests microphone and camera permissions based on app settings.
    /// - Returns: An asynchronous task that requests permissions.
    func requestMicrophoneAndCameraPermissionFromAppSettings() async {
        let requestMic = AppSettings.perferredAudioDirection() != .receiveOnly
        let requestCam = AppSettings.perferredVideoDirection() != .receiveOnly
        await ACBClientPhone.requestMicrophoneAndCameraPermission(requestMic, video: requestCam)
    }
    
    /// The main body of the app, defining the app's scenes and views.
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authenticationService)
                .environmentObject(callKitManager)
                .environmentObject(fcsdkCallService)
                .environmentObject(contactService)
                .environmentObject(aedService)
                .environmentObject(backgroundObserver)
                .environmentObject(pipStateObject)
                .environmentObject(pathState)
                .onAppear(perform: setup)
                .onContinueUserActivity(String(describing: INStartCallIntent.self), perform: handleCallIntent)
                .onChange(of: scenePhase, perform: handleScenePhaseChange)
        }
    }
    let monitor = NetworkMonitor()
    /// Sets up the initial state of the app when it appears.
    private func setup() {
        monitor.startMonitor(type: .all, pathState: self.pathState)
        // Configure services and defaults
        fcsdkCallService.delegate = authenticationService
        fcsdkCallService.appDelegate = delegate
        fcsdkCallService.contactService = contactService
        
        delegate.providerDelegate = ProviderDelegate(callKitManager: callKitManager, authenticationService: authenticationService, fcsdkCallService: fcsdkCallService)
        
        // Register default audio and video settings if not already set
        if UserDefaults.standard.string(forKey: MediaValue.keyAudioDirection.rawValue) == nil,
           UserDefaults.standard.string(forKey: MediaValue.keyVideoDirection.rawValue) == nil {
            AppSettings.registerDefaults(.sendAndReceive, audio: .sendAndReceive)
        }
    }
    
    /// Handles the incoming call intent from user activity.
    /// - Parameter activity: The user activity containing call information.
    private func handleCallIntent(activity: NSUserActivity) {
        callIntent = true
        guard let handle = activity.startCallHandle else {
            logger.error("Could not determine start call handle from user activity: \(activity)")
            return
        }
        
        Task {
            fcsdkCallService.destination = handle
            fcsdkCallService.isOutgoing = true
            fcsdkCallService.hasVideo = true
            await reAuthFlowWithCallIntent()
        }
    }
    
    /// Handles changes in the app's scene phase.
    /// - Parameter phase: The current scene phase.
    private func handleScenePhaseChange(phase: ScenePhase) {
        switch phase {
        case .active:
            Task { @MainActor in
                await requestMicrophoneAndCameraPermissionFromAppSettings()
                if authenticationService.uc?.connection == false {
                    authenticationService.sessionExists = false
                }
                
                if !callIntent {
                    if authenticationService.uc == nil && !authenticationService.sessionID.isEmpty,
                       !servername.isEmpty && !username.isEmpty {
                        await reAuthFlow()
                    }
                    if authenticationService.uc?.connection != nil {
                        authenticationService.sessionExists = true
                    }
                }
                logger.info("DO WE HAVE A SESSION? \(authenticationService.sessionExists)")
            }
        case .background:
            logger.info("ScenePhase: background")
        case .inactive:
            logger.info("ScenePhase: inactive")
        @unknown default:
            logger.info("ScenePhase: unexpected state")
        }
    }
    
    /// Re-authenticates the user and sets the phone delegate.
    /// - Returns: An asynchronous task that performs the re-authentication.
    func reAuthFlow() async {
        await authenticationService.loginUser(networkStatus: true)
        await fcsdkCallService.setPhoneDelegate()
    }
    
    /// Re-authenticates the user when a call intent is received.
    /// - Returns: An asynchronous task that performs the re-authentication and presents the communication sheet.
    func reAuthFlowWithCallIntent() async {
        await reAuthFlow()
        var attempts = 0
        let maxAttempts = 5
        
        while attempts < maxAttempts {
            if authenticationService.uc?.connection != false {
                await fcsdkCallService.presentCommunicationSheet()
                callIntent = false
                break
            }
            attempts += 1
            try? await Task.sleep(nanoseconds: 1_000_000_000) // Wait for 1 second before retrying
        }
    }
}


class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    private var authenticationService = AuthenticationService()
    private var fcsdkCallService = FCSDKCallService.shared
    private let monitor = NetworkMonitor()
    private let pathState = NWPathState()
    private var callKitManager = CallKitManager.shared
    private var contactService = ContactService()
    private var aedService = AEDService()
    private var backgroundObserver = BackgroundObserver()
    private var pipStateObject = PipStateObject.shared
    var providerDelegate: ProviderDelegate?
    
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Add another view with content Text("From iOS 13") to test both block runs
        let contentView = ContentView()
            .environmentObject(authenticationService)
            .environmentObject(callKitManager)
            .environmentObject(fcsdkCallService)
            .environmentObject(contactService)
            .environmentObject(aedService)
            .environmentObject(backgroundObserver)
            .environmentObject(pipStateObject)
            .environmentObject(pathState)
            .onAppear {
                self.monitor.startMonitor(type: .all, pathState: self.pathState)
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
        await self.authenticationService.loginUser(networkStatus: pathState.pathStatus == .satisfied ? true : false)
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
