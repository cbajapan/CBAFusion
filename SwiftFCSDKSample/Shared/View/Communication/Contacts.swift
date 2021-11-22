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
    
    @Binding var presentCommunication: ActiveSheet?
    @State var showFullSheet: Bool = false
    @State var destination: String = ""
    @State var hasVideo: Bool = false
    @State var isOutgoing: Bool = false
    @EnvironmentObject var authenticationService: AuthenticationService
    @EnvironmentObject var fcsdkCallService: FCSDKCallService
    @EnvironmentObject var monitor: NetworkMonitor
    @EnvironmentObject var contact: ContactService
    
    
    var body: some View {
        NavigationView {
            
            List {
                ForEach(self.contact.contacts ?? [], id: \.id) { contact in
                    ContactsCell(contact: contact)
                        .onTapGesture {
                            self.showFullSheet = true
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
                        AddButton(destination: CallSheet(destination: self.$destination, hasVideo: self.$hasVideo))
                    }
                }
            })
        }
        .alert("Do Not Disturb is On", isPresented: self.$fcsdkCallService.doNotDisturb, actions: {
            Button("OK", role: .cancel) { }
        })
        .fullScreenCover(isPresented: self.$showFullSheet, content: {
            Communication(destination: self.$destination, hasVideo: self.$hasVideo, isOutgoing: self.$isOutgoing)
        })
        .sheet(isPresented: self.$contact.addSheet, content: {
            AddContact()
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
            self.showFullSheet = newValue
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


enum ActiveSheet: Identifiable {
    case communincationSheet
    
    var id: Int {
        hashValue
    }
}
