//
//  ContactCard.swift
//  CBAFusion
//
//  Created by Cole M on 1/5/22.
//

import SwiftUI
import FCSDKiOS
import AVKit

/// A view that displays the contents of a call, including missed, rejected, or outgoing calls.
struct ContactContents: View {
    
    @State var call: FCSDKCall
    
    var body: some View {
        HStack {
            // Determine the call status and display appropriate content
            if call.missed == true && call.outbound == false {
                callStatusView(imageName: "arrow.down.left.video", color: .red, status: "You Missed a call from")
            } else if call.rejected == true && call.outbound == false {
                callStatusView(imageName: "arrow.down.left.video.fill", color: .red, status: "You Rejected a call from")
            } else if call.outbound == false && call.rejected == false {
                callStatusView(imageName: "arrow.down.left.video.fill", color: .blue, status: "\(call.handle) called you")
            } else {
                callStatusView(imageName: "arrow.up.right.video", color: .blue, status: "You called \(call.handle)")
            }
        }
    }
    
    /// Helper function to create a view for the call status.
    private func callStatusView(imageName: String, color: Color, status: String) -> some View {
        VStack {
            Image(systemName: imageName)
                .foregroundColor(color)
            Text("\(status) \(call.handle) - \(formattedDate(call.createdAt))")
                .foregroundColor(color)
        }
    }
    
    /// Formats the date from the call.
    private func formattedDate(_ date: Date?) -> String {
        DateFormatter().getFormattedDateFromDate(currentFormat: "yyyy'-'MM'-'dd'T'HH':'mm':'ssZZZ", newFormat: "MMM d, h:mm a", date: date ?? Date())
    }
}

/// A view that represents a contact card, displaying call history and options to initiate a call.
struct ContactCard: View {
    
    @Binding var destination: String
    @Binding var hasVideo: Bool
    @Binding var isOutgoing: Bool
    var contact: ContactModel?
    
    @State private var notLoggedIn: Bool = false
    @State private var calls: [FCSDKCall] = []
    
    @EnvironmentObject var authenticationService: AuthenticationService
    @EnvironmentObject var fcsdkCallService: FCSDKCallService
    @EnvironmentObject var contactService: ContactService
    
    var body: some View {
        if #available(iOS 14, *) {
            content
                .navigationTitle(title: contactService.selectedContact?.username ?? "")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { setupCall(hasVideo: true) }) {
                            Image(systemName: "video")
                                .foregroundColor(.blue)
                        }
                    }
                }
                .alert(isPresented: $contactService.alert) {
                    Alert(
                        title: Text("We are sorry you don't seem to be logged in"),
                        dismissButton: .cancel(Text("Okay"), action: { Task { await processNotLoggedIn() } })
                    )
                }
                .onAppear {
                    loadContactCalls()
                }
                .valueChanged(value: contactService.calls) { newValue in
                    if !newValue.isEmpty {
                        calls = newValue
                    }
                }
        } else {
            HStack {
                Spacer()
                Button {
                    setupCall(hasVideo: true)
                } label: {
                    Image(systemName: "video")
                        .foregroundColor(.blue)
                }
                .padding()
            }
            HStack {
                Text(self.contactService.selectedContact?.username ?? "")
                    .font(.title)
                    .bold()
                    .padding()
                Spacer()
            }
            content
                .alert(isPresented: self.$contactService.alert, content: {
                    Alert(
                        title: Text("We are sorry you don't seem to be logged in"),
                        message: Text(""),
                        dismissButton: .cancel(Text("Okay"), action: {
                            Task {
                                await processNotLoggedIn()
                            }
                        })
                    )
                })
                .onAppear {
                    Task.detached {
                        try await self.contactService.fetchContactCalls(destination)
                    }
                    Task {
                        self.calls = self.contactService.calls
                        self.contactService.selectedContact = self.contact
                        self.fcsdkCallService.destination = self.contact?.number ?? ""
                        if let calls = contact?.calls {
                            self.contactService.calls = calls
                        }
                    }
                }
                .valueChanged(value: self.contactService.calls) { newValue in
                    if !newValue.isEmpty {
                        self.calls = newValue
                    }
                }
        }
    }
    
    /// The main content view displaying the call history.
    @ViewBuilder private var content: some View {
        VStack(alignment: .leading) {
            ScrollView {
                ForEach(calls.lazy.reversed(), id: \.id) { call in
                    ContactContents(call: call)
                        .font(.caption)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                        .padding([.leading, .trailing])
                        .padding(.bottom, 3)
                }
                Spacer()
            }
            .padding(.top)
        }
    }
    
    /// Sets up a call to the selected contact.
    private func setupCall(hasVideo: Bool) {
        guard authenticationService.connectedToSocket, authenticationService.sessionExists else {
            // Handle not logged in case
            return
        }
        fcsdkCallService.presentCommunication = true
        fcsdkCallService.destination = contactService.selectedContact?.number ?? ""
        fcsdkCallService.hasVideo = hasVideo
        fcsdkCallService.isOutgoing = true
    }
    
    /// Processes the case when the user is not logged in.
    private func processNotLoggedIn() async {
        await authenticationService.logout()
        KeychainItem.deleteSessionID()
        authenticationService.sessionID = KeychainItem.getSessionID
    }
    
    /// Loads the calls for the selected contact.
    private func loadContactCalls() {
        Task {
            do {
                try await contactService.fetchContactCalls(destination)
                calls = contactService.calls
                contactService.selectedContact = contact
                fcsdkCallService.destination = contact?.number ?? ""
                if let calls = contact?.calls {
                    self.contactService.calls = calls
                }
            } catch {
                // Handle error appropriately
            }
        }
    }
}
