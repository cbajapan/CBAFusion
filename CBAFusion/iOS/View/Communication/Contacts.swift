//
//  Contacts.swift
//  CBAFusion
//
//  Created by Cole M on 9/2/21.
//

import SwiftUI
import Combine

/// A view representing a list of contacts with options to add, edit, and delete contacts.
struct Contacts: View {
    
    @EnvironmentObject var authenticationService: AuthenticationService
    @EnvironmentObject var fcsdkCallService: FCSDKCallService
    @EnvironmentObject var contactService: ContactService
    @EnvironmentObject var callKitManager: CallKitManager
    @Environment(\.colorScheme) var colorScheme
    @State var newImage: Image?
    
    var body: some View {
        NavigationView {
            ZStack {
                content
                if let newImage = newImage {
                    newImage
                }
            }
            .navigationBarTitle("Contacts", displayMode: .large)
            .navigationBarItems(leading: leadingToolbarItem, trailing: trailingToolbarItem)
        }
        .alert(isPresented: self.$fcsdkCallService.doNotDisturb) {
            Alert(
                title: Text("Do Not Disturb is On"),
                message: Text(""),
                dismissButton: .cancel(Text("Okay"))
            )
        }
        .fullScreenSheet(isPresented: self.$fcsdkCallService.presentCommunication) {
            Communication(destination: self.$fcsdkCallService.destination, hasVideo: self.$fcsdkCallService.hasVideo)
                .environmentObject(authenticationService)
                .environmentObject(callKitManager)
                .environmentObject(fcsdkCallService)
                .environmentObject(contactService)
        }
        .sheet(isPresented: self.$contactService.addSheet) {
            AddContact()
                .environmentObject(self.contactService)
        }
    }
    
    /// Toolbar item for the leading side (add contact button).
    private var leadingToolbarItem: some View {
        Button(action: {
            if self.authenticationService.connectedToSocket,
               self.authenticationService.sessionExists {
                self.contactService.addSheet = true
            }
        }) {
            Image(systemName: "plus")
                .foregroundColor(.blue)
        }
    }
    
    /// Toolbar item for the trailing side (call button).
    private var trailingToolbarItem: some View {
        PushDetail(destination: CallSheet(destination: self.$fcsdkCallService.destination, hasVideo: self.$fcsdkCallService.hasVideo, showCommunication: self.$fcsdkCallService.presentCommunication), image: "phone.fill.arrow.up.right")
            .foregroundColor(.blue)
    }
    
    @ViewBuilder var content: some View {
        ZStack {
            List {
                ForEach(self.contactService.contacts ?? [], id: \.id) { contact in
                    NavigationLink(destination: ContactCard(destination: self.$fcsdkCallService.destination, hasVideo: self.$fcsdkCallService.hasVideo, isOutgoing: self.$fcsdkCallService.isOutgoing, contact: contact)) {
                        contactRow(for: contact)
                    }
                    .contextMenu {
                        Button("Delete") {
                            self.removeContact(contact)
                        }
                        Button("Edit") {
                            self.editContact(contact)
                        }
                    }
                }
            }
            .background(colorScheme == .dark ? Color.black : Color(uiColor: .systemGray2))
            
            if !self.authenticationService.sessionExists {
                loadingView
            }
        }
    }
    
    /// Creates a row for displaying a contact.
    /// - Parameter contact: The contact to display.
    private func contactRow(for contact: ContactModel) -> some View {
        HStack {
            Circle()
                .fill(colorScheme == .dark ? Color(uiColor: .cyan) : Color.blue)
                .frame(width: 30, height: 30)
            
            VStack(alignment: .leading, spacing: 0) {
                Text(contact.username)
                    .fontWeight(.bold)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                Text(contact.number)
                    .fontWeight(.light)
                    .padding(.leading, 10)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
            }
        }
    }
    
    /// A loading view displayed when the session does not exist.
    private var loadingView: some View {
        Text("Loading.....")
            .foregroundColor(colorScheme == .dark ? .white : .black)
            .padding()
    }
    
    /// Edits a contact.
    /// - Parameter contact: The contact to edit.
    func editContact(_ contact: ContactModel) {
        Task {
            await self.contactService.editContact(contact: contact, isEdit: true)
        }
    }
    
    /// Removes a contact.
    /// - Parameter contact: The contact to remove.
    func removeContact(_ contact: ContactModel) {
        Task {
            await self.contactService.deleteContact(contact: contact)
        }
    }
}

/// A view representing a navigation link with an image.
struct PushDetail<Destination: View>: View {
    var destination: Destination
    var image: String
    
    var body: some View {
        NavigationLink(destination: self.destination) {
            Image(systemName: self.image)
        }
    }
}
