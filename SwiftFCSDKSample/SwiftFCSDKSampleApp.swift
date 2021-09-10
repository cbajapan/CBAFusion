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
    
    
    @StateObject private var authenticationService = AuthenticationService()
    @StateObject private var monitor = NetworkMonitor(type: .all)
    @State var callKitController: CallKitController?
    @StateObject private var callKitManager = CallKitManager()
    
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
                    _ = PushController(callKitManager: callKitManager)
                    self.callKitController = CallKitController(callKitManager: callKitManager)
                }
        }
    }
}
