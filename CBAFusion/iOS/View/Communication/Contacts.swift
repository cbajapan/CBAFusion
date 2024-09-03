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
    @State var newImage: Image?
    
    var body: some View {
        NavigationView {
            if #available(iOS 14, *) {
                ZStack {
                    content
                    if let newImage = newImage {
                        newImage
                    }
                }
                .navigationTitle(title: "Contacts")
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
            } else {
                VStack {
                    HStack {
                        Button {
                            if self.authenticationService.connectedToSocket,
                               self.authenticationService.sessionExists {
                                self.contactService.addSheet = true
                            }
                        } label: {
                            Image(systemName: "plus")
                                .foregroundColor(.blue)
                        }
                        Spacer()
                        HStack {
                            PushDetail(destination: CallSheet(destination: self.$fcsdkCallService.destination, hasVideo: self.$fcsdkCallService.hasVideo, showCommunication: self.$fcsdkCallService.presentCommunication), image: "phone.fill.arrow.up.right")
                                .foregroundColor(.blue)
                        }
                    }.padding()
                    HStack {
                        Text("Contacts")
                            .font(.title)
                            .bold()
                            .padding()
                        Spacer()
                    }
                    content
                }
            }
        }
        .alert(isPresented: self.$fcsdkCallService.doNotDisturb, content: {
            Alert(
                title: Text("Do Not Disturb is On"),
                message: Text(""),
                dismissButton: .cancel(Text("Okay"), action: {
                })
            )
        })
        .fullScreenSheet(isPresented: self.$fcsdkCallService.presentCommunication, content: {
            Communication(destination: self.$fcsdkCallService.destination, hasVideo: self.$fcsdkCallService.hasVideo)
                .environmentObject(authenticationService)
                .environmentObject(callKitManager)
                .environmentObject(fcsdkCallService)
                .environmentObject(contactService)
        })
        .sheet(isPresented: self.$contactService.addSheet, content: {
            AddContact()
                .environmentObject(self.contactService)
        })
    }
    
    @ViewBuilder @MainActor var content: some View {
        
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
            .background(colorScheme == .dark ? .black : Color(uiColor: .systemGray2))
            if !self.authenticationService.sessionExists {
                if #available(iOS 14, *) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: colorScheme == .dark ? .white : .black))
                        .scaleEffect(1.5)
                } else {
                    Text("Loading.....")
                }
            }
        }
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
