//
//  console.swift
//  CBAFusion
//
//  Created by Cole M on 12/2/21.
//

import SwiftUI
import FCSDKiOS

/// A view that provides a console interface for publishing, deleting, and sending messages.
struct Console: View {
    
    @Binding var topicName: String
    @Binding var expiry: String
    @State private var console = ""
    @State private var messageHeight: CGFloat = 0
    @State private var key = ""
    @State private var value = ""
    @State private var messageText = ""
    @State private var placeholder = ""
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var aedService: AEDService
    @EnvironmentObject var authenticationService: AuthenticationService
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                dataInputSection(geometry: geometry)
                Divider()
                consoleOutputSection
            }
        }
        .onAppear {
            Task {
                await self.connectToTopic()
            }
        }
        .valueChanged(value: self.aedService.consoleMessage) { newValue in
            self.console += "\n\(newValue)"
        }
    }
    
    /// Section for inputting data (key-value pairs) and sending messages.
    private func dataInputSection(geometry: GeometryProxy) -> some View {
        HStack(alignment: .top) {
            Form {
                Section(header: Text("Data")) {
                    TextField("Key", text: $key)
                    TextField("Value", text: $value)
                    publishButton
                    deleteButton
                }
                Section(header: Text("Message")) {
                    TextField("Your message", text: $messageText)
                    sendButton
                }
            }
            Spacer()
                .frame(width: geometry.size.width / 2, alignment: .topLeading)
        }
        .background(colorScheme == .dark ? Color(uiColor: .systemBackground) : Color(uiColor: .secondarySystemBackground))
        .frame(height: geometry.size.height / 2)
    }
    
    /// Button for publishing data.
    private var publishButton: some View {
        Button("Publish") {
            Task {
                await self.publishData()
            }
        }
    }
    
    /// Button for deleting data.
    private var deleteButton: some View {
        Button("Delete") {
            Task {
                await self.deleteData()
            }
        }
    }
    
    /// Button for sending messages.
    private var sendButton: some View {
        Button("Send") {
            Task {
                await self.sendMessage()
            }
        }
    }
    
    /// Section for displaying console output.
    private var consoleOutputSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Console")
                .foregroundColor(.gray)
                .background(Color.black)
                .padding()
            AutoSizingTextView(text: self.$console, height: self.$messageHeight, placeholder: self.$placeholder)
                .padding()
                .foregroundColor(Color.white)
                .background(Color.black)
                .font(.body)
        }
        .background(Color.black)
    }
    
    /// Connects to the specified topic when the view appears.
    @MainActor
    private func connectToTopic() async {
        guard !topicName.isEmpty else {
            showError("Please enter a Topic Name")
            return
        }
        
        let expiry = Int(expiry) ?? 0
        aedService.currentTopic = authenticationService.uc?.aed.createTopic(withName: topicName, expiryTime: expiry, delegate: aedService)
        topicName = ""
        self.expiry = ""
    }
    
    /// Publishes data to the current topic.
    @MainActor
    private func publishData() async {
        guard !key.isEmpty, !value.isEmpty else {
            showError("Please enter a Key Value Pair")
            return
        }
        
        await aedService.currentTopic?.submitData(withKey: key, value: value)
        key = ""
        value = ""
    }
    
    /// Deletes data from the current topic.
    @MainActor
    private func deleteData() async {
        guard !key.isEmpty else {
            showError("Please enter a Key to delete")
            return
        }
        
        await aedService.currentTopic?.deleteData(withKey: key)
        key = ""
        value = ""
    }
    
    /// Sends a message to the current topic.
    @MainActor
    private func sendMessage() async {
        guard !messageText.isEmpty else {
            showError("Please enter a Message")
            return
        }
        
        await aedService.currentTopic?.sendAedMessage(messageText)
        messageText = ""
    }
    
    /// Displays an error message using the authentication service.
    private func showError(_ message: String) {
        authenticationService.showErrorAlert = true
        authenticationService.errorMessage = message
    }
}
