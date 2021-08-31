//
//  SwiftFCSDKSampleApp.swift
//  SwiftFCSDKSample
//
//  Created by Cole M on 8/30/21.
//

import SwiftUI

@main
struct SwiftFCSDKSampleApp: App {
    
    
    @StateObject private var authenticationService = AuthenticationService()
    
    
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authenticationService)
        }
    }
}
