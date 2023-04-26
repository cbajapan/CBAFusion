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
    @StateObject private var backgrounds = Backgrounds()
    @StateObject private var pipStateObject = PipStateObject.shared
    
    @State var providerDelegate: ProviderDelegate?
//    @State var exists = SQLiteStore.exists()
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
                .task {
                    
                    async let image1 = backgrounds.addImage("bedroom1", size: CGSize(width: 1280, height: 720), thumbnail: CGSize(width: 300, height: 225))
                    async let image2 = backgrounds.addImage("bedroom2", size: CGSize(width: 1280, height: 720), thumbnail: CGSize(width: 300, height: 225))
                    async let image3 = backgrounds.addImage("dining_room11", size: CGSize(width: 1280, height: 720), thumbnail: CGSize(width: 300, height: 225))
                    async let image4 = backgrounds.addImage("entrance1", size: CGSize(width: 1280, height: 720), thumbnail: CGSize(width: 300, height: 225))
                    async let image5 = backgrounds.addImage("garden", size: CGSize(width: 1280, height: 720), thumbnail: CGSize(width: 300, height: 225))
                    async let image6 = backgrounds.addImage("guest_room1", size: CGSize(width: 1280, height: 720), thumbnail: CGSize(width: 300, height: 225))
                    async let image7 = backgrounds.addImage("guest_room8", size: CGSize(width: 1280, height: 720), thumbnail: CGSize(width: 300, height: 225))
                    async let image8 = backgrounds.addImage("lounge", size: CGSize(width: 1280, height: 720), thumbnail: CGSize(width: 300, height: 225))
                    async let image9 = backgrounds.addImage("porch", size: CGSize(width: 1280, height: 720), thumbnail: CGSize(width: 300, height: 225))
                    async let image10 = backgrounds.addImage("remove", size: CGSize(width: 1280, height: 720), thumbnail: CGSize(width: 300, height: 225))
                    async let image11 = backgrounds.addImage("blur", size: CGSize(width: 1280, height: 720), thumbnail: CGSize(width: 300, height: 225))
                    _ = await [
                        image1,
                        image2,
                        image3,
                        image4,
                        image5,
                        image6,
                        image7,
                        image8,
                        image9,
                        image10,
                        image11
                    ]
                    backgrounds.displayImage = await image1
                }
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
                        Task {
                            await self.requestMicrophoneAndCameraPermissionFromAppSettings()
                            if self.authenticationService.acbuc?.connection == false {
                                self.authenticationService.sessionExists = false
                            }
                            
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
        self.fcsdkCallService.acbuc = self.authenticationService.acbuc
        guard let uc = self.fcsdkCallService.acbuc else { return }
        await self.fcsdkCallService.setPhoneDelegate(uc)
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
