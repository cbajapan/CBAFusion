//
//  AEDTopic.swift
//  CBAFusion
//
//  Created by Cole M on 12/6/21.
//

import SwiftUI
import FCSDKiOS

/// A view representing a topic in the AED system, allowing users to select and interact with it.
struct AEDTopic: View {
    
    @State var topic: ACBTopic
    @Binding var console: String
    @EnvironmentObject var authenticationService: AuthenticationService
    @EnvironmentObject var aedService: AEDService
    
    // State variable to track if the topic is checked
    @State private var isChecked: Bool = false
    
    var body: some View {
        HStack {
            topicNameView
            Spacer()
            checkmarkView
        }
        .onTapGesture {
            toggleCheckmark()
        }
        .onAppear {
            // Initialize the checked state based on the topic
            self.isChecked = false
        }
    }
    
    /// View for displaying the topic name.
    private var topicNameView: some View {
        Text(topic.name) // Directly use topic.name
            .onAppear {
                // This is not necessary since topic.name is already available
            }
    }
    
    /// View for displaying the checkmark if the topic is checked.
    private var checkmarkView: some View {
        Group {
            if isChecked {
                Image(systemName: "checkmark")
                    .foregroundColor(Color.green)
            } else {
                EmptyView() // Return an empty view if not checked
            }
        }
    }
    
    /// Toggles the checked state and performs actions based on the state.
    private func toggleCheckmark() {
        isChecked.toggle()
        if isChecked {
            Task {
                await didTapTopic(topic)
            }
        }
    }
    
    /// Handles the action when the topic is tapped.
    private func didTapTopic(_ topic: ACBTopic) async {
        guard !topic.name.isEmpty else {
            showError("Topic Name is empty")
            return
        }
        
        let uc = authenticationService.uc
        aedService.currentTopic = uc?.aed.createTopic(withName: topic.name, delegate: aedService)
        let msg = "Current topic is \(aedService.currentTopic?.name ?? "")."
        console += "\n\(msg)"
    }
    
    /// Displays an error message using the authentication service.
    private func showError(_ message: String) {
        Task {
            await MainActor.run {
                authenticationService.showErrorAlert = true
                authenticationService.errorMessage = message
            }
        }
    }
}
