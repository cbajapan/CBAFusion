//
//  Contacts.swift
//  SwiftFCSDKSample
//
//  Created by Cole M on 9/2/21.
//

import SwiftUI

struct AddButton<Destination : View>: View {
    
    var destination:  Destination
    
    var body: some View {
        NavigationLink(destination: self.destination) { Image(systemName: "phone.fill.arrow.up.right") }
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
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        AddButton(destination: CallSheet(destination: self.$destination, hasVideo: self.$hasVideo, isOutgoing: self.$isOutgoing, showCommunication: self.$showCommunication))
                    }
                }
            })
        }
        .alert("Do Not Disturb is On", isPresented: self.$fcsdkCallService.doNotDisturb, actions: {
            Button("OK", role: .cancel) { }
        })
        .fullScreenCover(isPresented: self.$showCommunication, content: {
            Communication(destination: self.$destination, hasVideo: self.$hasVideo, isOutgoing: self.$isOutgoing)
                .environmentObject(self.authenticationService)
                .environmentObject(self.fcsdkCallService)
                .environmentObject(self.callKitManager)
        })
        .sheet(isPresented: self.$contact.addSheet, content: {
            AddContact().environmentObject(self.contact)
        })
        .onAppear {
            Task {
                try? await self.contact.fetchContacts()
            }
            
            if !self.authenticationService.connectedToSocket {
                Task {
#if !DEBUG
                    await self.authenticationService.createSession(sessionid: KeychainItem.getSessionID, networkStatus: monitor.networkStatus())
#else
                    await self.authenticationService.createSession(sessionid: UserDefaults.standard.string(forKey: "SessionID") ?? "", networkStatus: monitor.networkStatus())
#endif
                }
                self.fcsdkCallService.acbuc = self.authenticationService.acbuc
                self.fcsdkCallService.setPhoneDelegate()
            } else {
                self.fcsdkCallService.acbuc = self.authenticationService.acbuc
                self.fcsdkCallService.setPhoneDelegate()
            }
        }
        .onChange(of: self.fcsdkCallService.presentCommunication) { newValue in
            self.showCommunication = newValue
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
