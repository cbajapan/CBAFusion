//
//  CallSheet.swift
//  CBAFusion
//
//  Created by Cole M on 9/8/21.
//

import SwiftUI
import FCSDKiOS

/// A view representing a call sheet for initiating a communication session.
struct CallSheet: View {
    
    @Binding var destination: String // The destination endpoint for the call
    @Binding var hasVideo: Bool // Indicates if the call will have video
    @Binding var showCommunication: Bool // Controls the visibility of the communication view
    @State private var notLoggedIn: Bool = false // State to track if the user is logged in
    @Environment(\.presentationMode) private var presentationMode // Environment variable to control the view's presentation
    @EnvironmentObject var authenticationService: AuthenticationService // Authentication service for managing user sessions
    @EnvironmentObject var callKitManager: CallKitManager // CallKit manager for handling calls
    @EnvironmentObject var fcsdkCallService: FCSDKCallService // SDK call service for managing calls
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack {
                    // Input field for the destination endpoint
                    HStack(alignment: .bottom) {
                        Text("End Point:")
                        TextField("Destination...", text: self.$destination)
                            .textFieldStyle(RoundedBorderTextFieldStyle()) // Apply a rounded border style to the text field
                    }
                    .padding()
                }
            }
        }
        .navigationBarBackButtonHidden(true) // Hide the default back button
        .navigationBarTitle("Let's Talk") // Set the navigation bar title
        .navigationBarItems(leading: cancelButton, trailing: callButtons) // Set custom navigation bar items
        .alert(isPresented: self.$notLoggedIn) { // Show an alert if the user is not logged in
            Alert(
                title: Text("We are sorry you don't seem to be logged in"),
                message: Text(""),
                dismissButton: .cancel(Text("Okay"), action: {
                    Task {
                        await processNotLoggedIn() // Process logout if the user is not logged in
                    }
                })
            )
        }
    }
    
    /// A button to cancel the call setup and dismiss the view.
    private var cancelButton: some View {
        Button(action: {
            if UIDevice.current.userInterfaceIdiom == .phone {
                self.presentationMode.wrappedValue.dismiss() // Dismiss the view on phone devices
            }
        }) {
            if UIDevice.current.userInterfaceIdiom == .phone {
                Text("Cancel")
                    .foregroundColor(Color.red) // Set the cancel button color to red
            }
        }
    }
    
    /// A view containing buttons to initiate a call with or without video.
    private var callButtons: some View {
        HStack {
            Button(action: {
                setupCall(hasVideo: true) // Setup a video call
            }) {
                Image(systemName: "video")
                    .foregroundColor(.blue) // Set the video button color to blue
            }
            // Additional buttons for audio calls can be added here
        }
    }
    
    /// Sets up the call with the specified video option.
    /// - Parameter hasVideo: A boolean indicating if the call should have video.
    private func setupCall(hasVideo: Bool) {
        self.fcsdkCallService.isOutgoing = true // Mark the call as outgoing
        self.fcsdkCallService.hasVideo = hasVideo // Set the video option
        self.showCommunication = true // Show the communication view
        self.presentationMode.wrappedValue.dismiss() // Dismiss the call sheet
    }
    
    /// Processes the logout when the user is not logged in.
    private func processNotLoggedIn() async {
        await self.authenticationService.logout() // Logout the user
        KeychainItem.deleteSessionID() // Delete the session ID from the keychain
        self.authenticationService.sessionID = KeychainItem.getSessionID // Reset the session ID
    }
}
