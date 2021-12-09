//
//  Contacts.swift
//  CBAFusion
//
//  Created by Cole M on 9/2/21.
//

import SwiftUI

struct PushDetail<Destination : View>: View {
    
    var destination:  Destination
    var image: String
    var body: some View {
        NavigationLink(destination: self.destination) { Image(systemName: self.image) }
    }
}

struct Contacts: View {
    
    @State var showCommunication: Bool = false
    @State var destination: String = ""
    @State var hasVideo: Bool = true
    @State var isOutgoing: Bool = false
    @EnvironmentObject var authenticationService: AuthenticationService
    @EnvironmentObject var fcsdkCallService: FCSDKCallService
    @EnvironmentObject var monitor: NetworkMonitor
    @EnvironmentObject var contact: ContactService
    @EnvironmentObject var callKitManager: CallKitManager
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            ZStack {
            List {
                ForEach(self.contact.contacts ?? [], id: \.id) { contact in
                    ContactsCell(contact: contact)
                        .onTapGesture {
                            self.showCommunication = true
                            self.destination = contact.number
                            self.hasVideo = true
                            self.isOutgoing = true
                        }
                        .swipeActions(edge: .trailing) {
                            Button("Delete") {
                                self.removeContact(contact)
                            }
                            .tint(.red)
                        }
                        .swipeActions(edge: .leading) {
                            Button("Edit") {
                                self.editContact(contact)
                            }
                            .tint(.green)
                        }
                }
                .navigationTitle("Contacts")
            }
            .background(colorScheme == .dark ? .black : Color(uiColor: .systemGray2))
                if !self.authenticationService.connectedToSocket {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                }
            }
            .navigationBarTitleDisplayMode(.large)
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        self.contact.addSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(.blue)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        PushDetail(destination: CallSheet(destination: self.$destination, hasVideo: self.$hasVideo, isOutgoing: self.$isOutgoing, showCommunication: self.$showCommunication), image: "phone.fill.arrow.up.right")
                            .foregroundColor(.blue)
                    }
                }
            })
        }
        .alert("Do Not Disturb is On", isPresented: self.$fcsdkCallService.doNotDisturb, actions: {
            Button("OK", role: .cancel) { }
        })
        .fullScreenCover(isPresented: self.$showCommunication, content: {
            Communication(destination: self.$destination, hasVideo: self.$hasVideo, isOutgoing: self.$isOutgoing)
                .environmentObject(authenticationService)
                .environmentObject(callKitManager)
                .environmentObject(fcsdkCallService)
        })
        .sheet(isPresented: self.$contact.addSheet, content: {
            AddContact()
                .environmentObject(self.contact)
        })
        .onChange(of: self.fcsdkCallService.presentCommunication) { newValue in
            self.showCommunication = newValue
        }
        .onChange(of: self.contact.contacts) { newValue in
            Task {
                try? await self.contact.fetchContacts()
            }
        }
    }
    
    func editContact(_ contact: ContactModel) {
        Task {
            await self.contact.editContact(contact: contact, isEdit: true)
        }
    }
    
    func removeContact(_ contact: ContactModel) {
        Task {
            await self.contact.deleteContact(contact: contact)
        }
    }
}
