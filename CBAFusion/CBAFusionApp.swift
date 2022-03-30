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
struct CBAFusionApp: App {
    
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @Environment(\.scenePhase) var scenePhase
    @StateObject private var authenticationService = AuthenticationService()
    @StateObject private var fcsdkCallService = FCSDKCallService()
    @StateObject private var monitor = NetworkMonitor(type: .all)
    @StateObject private var callKitManager = CallKitManager()
    @StateObject private var contactService = ContactService()
    @StateObject private var aedService = AEDService()
    
    @State var providerDelegate: ProviderDelegate?
    @State var exists = SQLiteStore.exists()
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
            
                .onAppear {
                    fcsdkCallService.delegate = authenticationService
                    fcsdkCallService.appDelegate = delegate
                    fcsdkCallService.contactService = contactService
                    delegate.providerDelegate = ProviderDelegate(callKitManager: callKitManager, authenticationService: authenticationService, fcsdkCallService: fcsdkCallService)
                    AppSettings.registerDefaults()
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
                .onChange(of: scenePhase) { (phase) in
                    switch phase {
                    case .active:
                        self.logger.info("ScenePhase: active, Are we Connected to the Socket?: \(String(describing: self.authenticationService.acbuc?.connection))")
                        Task {
                            await self.requestMicrophoneAndCameraPermissionFromAppSettings()
                            if self.authenticationService.acbuc?.connection == false {
                                self.authenticationService.sessionExists = false
                            }
                            
                            // When our scene becomes active if we are not connected to the socket and we have a sessionID we want to connect back to the service, set the UC object and phone delegate
                            if !callIntent {
                                if self.authenticationService.acbuc == nil && !self.authenticationService.sessionID.isEmpty,
                                   servername != "" && username != "" {
                                    await reAuthFlow()
                                }
                                if self.authenticationService.acbuc?.connection != nil {
                                    self.authenticationService.sessionExists = true
                                }
                            }
                            self.logger.info("DO WE HAVE A SESSION? \(self.authenticationService.sessionExists)")
                            
                        }
                    case .background:
                        self.logger.info("ScenePhase: background, Are we Connected to the Socket?: \(String(describing: self.authenticationService.acbuc?.connection))")
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
        self.fcsdkCallService.acbuc = self.authenticationService.acbuc
        self.fcsdkCallService.setPhoneDelegate()
    }
    
    func reAuthFlowWithCallIntent() async {
        await reAuthFlow()
        repeat {
            Task {
                if self.authenticationService.acbuc?.connection != false {
                    await fcsdkCallService.presentCommunicationSheet()
                    callIntent = false
                }
            }
        } while (self.authenticationService.acbuc?.connection == false)  
    }
}
