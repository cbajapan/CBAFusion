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
    
    @EnvironmentObject var authenticationService: AuthenticationService
    @EnvironmentObject var fcsdkCallService: FCSDKCallService
    @EnvironmentObject var monitor: NetworkMonitor
    @EnvironmentObject var contactService: ContactService
    @EnvironmentObject var callKitManager: CallKitManager
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            ZStack {
                List {
                    ForEach(self.contactService.contacts ?? [], id: \.id) { contact in
                       
                        NavigationLink(destination: ContactCard(destination: self.$fcsdkCallService.destination, hasVideo: self.$fcsdkCallService.hasVideo, isOutgoing: self.$fcsdkCallService.isOutgoing, contact: contact)) {
                            HStack {
                                ZStack{
                                    if #available(iOS 15.0, *) {
                                        Circle()
                                            .fill(Color.cyan)
                                            .frame(width: 30, height: 30, alignment: .leading)
                                    } else {
                                        Circle()
                                            .fill(Color.blue)
                                            .frame(width: 30, height: 30, alignment: .leading)
                                    }
                                }
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
                   if !self.authenticationService.sessionExists {
                    ProgressView()
                           .progressViewStyle(CircularProgressViewStyle(tint: colorScheme == .dark ? .white : .black))
                        .scaleEffect(1.5)
                }
            }
            .navigationBarTitleDisplayMode(.large)
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        if self.authenticationService.connectedToSocket,
                           self.authenticationService.sessionExists {
                            self.contactService.addSheet = true
                        }
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(.blue)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        PushDetail(destination: CallSheet(destination: self.$fcsdkCallService.destination, hasVideo: self.$fcsdkCallService.hasVideo, showCommunication: self.$fcsdkCallService.presentCommunication), image: "phone.fill.arrow.up.right")
                            .foregroundColor(.blue)
                    }
                }
            })
        }
        .alert("Do Not Disturb is On", isPresented: self.$fcsdkCallService.doNotDisturb, actions: {
            Button("OK", role: .cancel) { }
        })
        .fullScreenCover(isPresented: self.$fcsdkCallService.presentCommunication, content: {
            Communication(destination: self.$fcsdkCallService.destination, hasVideo: self.$fcsdkCallService.hasVideo)
//                .environmentObject(authenticationService)
//                .environmentObject(callKitManager)
//                .environmentObject(fcsdkCallService)
        })
        .sheet(isPresented: self.$contactService.addSheet, content: {
            AddContact()
                .environmentObject(self.contactService)
        })
    }
    
    func editContact(_ contact: ContactModel) {
        Task {
            await self.contactService.editContact(contact: contact, isEdit: true)
        }
    }
    
    func removeContact(_ contact: ContactModel) {
        Task {
            await self.contactService.deleteContact(contact: contact)
        }
    }
}
