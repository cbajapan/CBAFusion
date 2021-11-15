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
        NavigationLink(destination: self.destination) { Image(systemName: "plus") }
    }
}

struct Contacts: View {
    
    @Binding var presentCommunication: ActiveSheet?
//    @State var showFullSheet: ActiveSheet?
    @State var showFullSheet: Bool = false
//    @State var callSheet: Bool = false
    @State var destination: String = ""
    @State var hasVideo: Bool = false
    @State var isOutgoing: Bool = false
    @EnvironmentObject var authenticationService: AuthenticationService
    @EnvironmentObject var fcsdkCallService: FCSDKCallService
    @EnvironmentObject var monitor: NetworkMonitor
    
    let contacts = [
        Contact(id: UUID(), name: "User1", number: "1001", icon: ""),
        Contact(id: UUID(), name: "User2", number: "1002", icon: ""),
        Contact(id: UUID(), name: "User3", number: "1003", icon: ""),
        Contact(id: UUID(), name: "User4", number: "1004", icon: ""),
        Contact(id: UUID(), name: "User5", number: "1005", icon: ""),
        Contact(id: UUID(), name: "User6", number: "1006", icon: "")
    ]
    
    
    var body: some View {
        NavigationView {
            List {
                ForEach(self.contacts, id: \.self) { contact in
                    ContactsCell(contact: contact)
                        .onTapGesture {
//                            self.showFullSheet = .communincationSheet
                            self.showFullSheet = true
                            self.destination = contact.number
                            self.hasVideo = true
                            self.isOutgoing = true
                        }
                }
                    .navigationTitle("Contacts")
            }
            .navigationBarTitleDisplayMode(.large)
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack { AddButton(destination: CallSheet(destination: self.$destination, hasVideo: self.$hasVideo)) }
                }
            })
        }
        .fullScreenCover(isPresented: self.$showFullSheet, onDismiss: {
            
        }, content: {
            Communication(destination: self.$destination, hasVideo: self.$hasVideo, isOutgoing: self.$isOutgoing)
        })
//        .fullScreenCover(item: self.$showFullSheet) { sheet in
//            switch sheet {
//            case .communincationSheet:
                //We need to pass whether or not this is an inbound or outbound call via isOutgoing rather than an arbitrarry load
//                Communication(destination: self.$destination, hasVideo: self.$hasVideo, isOutgoing: self.$isOutgoing)
                
//            }
//        }
        .onAppear {
            if !self.authenticationService.connectedToSocket {
                Task {
#if !DEBUG
                    await self.authenticationService.createSession(sessionid: KeychainItem.getSessionID, networkStatus: monitor.networkStatus())
#else
                    await self.authenticationService.createSession(sessionid: UserDefaults.standard.string(forKey: "SessionID") ?? "", networkStatus: monitor.networkStatus())
#endif
                }
                //                                 self.fcsdkCallService.connectedToSocket = self.fcsdkCallService.acbuc?.connection != nil
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
}

enum ActiveSheet: Identifiable {
    case communincationSheet
    
    var id: Int {
        hashValue
    }
}
