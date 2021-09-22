//
//  SwiftFCSDKSampleApp.swift
//  SwiftFCSDKSample
//
//  Created by Cole M on 8/30/21.
//

import SwiftUI
import AVKit


@main
struct SwiftFCSDKSampleApp: App {
    
    @Environment(\.scenePhase) var scenePhase
    @StateObject private var authenticationService = AuthenticationService()
    @StateObject private var monitor = NetworkMonitor(type: .all)
    @StateObject private var callKitManager = CallKitManager()
    @State var callKitController: CallKitController?
    
    init() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback, mode: .moviePlayback)
        } catch {
            print("Failed to set audioSession category to playback")
        }
    }
    
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(monitor)
                .environmentObject(authenticationService)
                .environmentObject(callKitManager)
                .onAppear {
                    _ = PushController(callKitManager: callKitManager, authenticationServices: authenticationService)
                    self.callKitController = CallKitController(callKitManager: callKitManager, authenticationServices: authenticationService)
                    AppSettings.registerDefaults()
                }
        }
        .onChange(of: scenePhase) { (phase) in
            switch phase {
            case .active:
                print("ScenePhase: active")
            case .background:
                print("ScenePhase: background")
            case .inactive:
                print("ScenePhase: inactive")
            @unknown default:
                print("ScenePhase: unexpected state")
            }
        }
    }
}
