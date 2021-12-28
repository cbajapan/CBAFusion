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
    
    @State var destination: String = ""
    @State var hasVideo: Bool = true
    @State var isOutgoing: Bool = false
    @State var notLoggedIn: Bool = false
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
                        
                        .onTapGesture {
                            if authenticationService.acbuc != nil,
                               self.authenticationService.connectedToSocket,
                               self.authenticationService.sessionExists {
                                self.fcsdkCallService.presentCommunication = true
                                self.destination = contact.number
                                self.hasVideo = true
                                self.isOutgoing = true
                            } else {
                                notLoggedIn = true
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
                            self.contact.addSheet = true
                        }
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(.blue)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        PushDetail(destination: CallSheet(destination: self.$destination, hasVideo: self.$hasVideo, isOutgoing: self.$isOutgoing, showCommunication: self.$fcsdkCallService.presentCommunication), image: "phone.fill.arrow.up.right")
                            .foregroundColor(.blue)
                    }
                }
            })
        }
        .alert("Do Not Disturb is On", isPresented: self.$fcsdkCallService.doNotDisturb, actions: {
            Button("OK", role: .cancel) { }
        })
        .fullScreenCover(isPresented: self.$fcsdkCallService.presentCommunication, content: {
            Communication(destination: self.$destination, hasVideo: self.$hasVideo, isOutgoing: self.$isOutgoing)
                .environmentObject(authenticationService)
                .environmentObject(callKitManager)
                .environmentObject(fcsdkCallService)
        })
        .sheet(isPresented: self.$contact.addSheet, content: {
            AddContact()
                .environmentObject(self.contact)
        })
        .alert("We are sorry you don't seem to be logged in", isPresented: self.$notLoggedIn, actions: {
            Button("OK", role: .cancel) {
                processNotLoggedIn()
            }
        })
    }
    
    func processNotLoggedIn() {
        Task {
            await self.authenticationService.logout()
            KeychainItem.deleteSessionID()
            self.authenticationService.sessionID = KeychainItem.getSessionID
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
