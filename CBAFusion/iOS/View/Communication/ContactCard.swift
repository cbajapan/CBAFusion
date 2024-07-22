//
//  ContactCard.swift
//  CBAFusion
//
//  Created by Cole M on 1/5/22.
//

import SwiftUI
import FCSDKiOS
import AVKit


struct ContactContents: View {
    
    @State var call: FCSDKCall
    
    var body: some View {
        
        HStack {
            if call.missed == true && call.outbound == false {
                Image(systemName: "arrow.down.left.video")
                    .foregroundColor(.red)
                Text("You Missed a call from \(call.handle) - " + DateFormatter().getFormattedDateFromDate(currentFormat: "yyyy'-'MM'-'dd'T'HH':'mm':'ssZZZ", newFormat: "MMM d, h:mm a", date: call.createdAt ?? Date()))
                    .foregroundColor(.red)
            } else if call.rejected == true && call.outbound == false {
                Image(systemName: "arrow.down.left.video.fill")
                    .foregroundColor(.red)
                Text("You Rejected a call from \(call.handle) - " + DateFormatter().getFormattedDateFromDate(currentFormat: "yyyy'-'MM'-'dd'T'HH':'mm':'ssZZZ", newFormat: "MMM d, h:mm a", date: call.createdAt ?? Date()))
                    .foregroundColor(.red)
            } else if call.outbound == false && call.rejected == false {
                Image(systemName: "arrow.down.left.video.fill")
                    .foregroundColor(.blue)
                Text("\(call.handle) called you - " + DateFormatter().getFormattedDateFromDate(currentFormat: "yyyy'-'MM'-'dd'T'HH':'mm':'ssZZZ", newFormat: "MMM d, h:mm a", date: call.createdAt ?? Date()))
                    .foregroundColor(.blue)
            } else {
                Image(systemName: "arrow.up.right.video")
                    .foregroundColor(.blue)
                Text("You called \(call.handle) - " + DateFormatter().getFormattedDateFromDate(currentFormat: "yyyy'-'MM'-'dd'T'HH':'mm':'ssZZZ", newFormat: "MMM d, h:mm a", date: call.createdAt ?? Date()))
                    .foregroundColor(.blue)
            }
        }
    }
}


struct ContactCard: View {
    
    
    @Binding var destination: String
    @Binding var hasVideo: Bool
    @Binding var isOutgoing: Bool
    var contact: ContactModel?
    @State var notLoggedIn: Bool = false
    @State var calls: [FCSDKCall] = []
    @EnvironmentObject var authenticationService: AuthenticationService
    @EnvironmentObject var fcsdkCallService: FCSDKCallService
    @EnvironmentObject var contactService: ContactService
    
    
    
    
    @ViewBuilder var content: some View {
        ZStack {
            VStack(alignment: .leading) {
                ScrollView {
                    ForEach(self.calls.lazy.reversed(), id: \.id) { call in
                        ContactContents(call: call)
                            .font(.caption)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                            .padding([.leading, .trailing])
                            .padding(.bottom, 3)
                    }
                    Spacer()
                }.padding(.top)
            }
        }
    }
    
    var body: some View {
        if #available(iOS 14, *) {
            content
                .navigationTitle(self.contactService.selectedContact?.username ?? "")
                .toolbar(content: {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack {
                            Button {
                                setupCall(hasVideo: true)
                            } label: {
                                Image(systemName: "video")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                })
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
                        await self.contactService.setCallsForContact(self.contact!)
                    }
                }
                .valueChanged(value: self.contactService.calls) { newValue in
                    if !newValue.isEmpty {
                        self.calls = newValue
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
                        await self.contactService.setCallsForContact(self.contact!)
                    }
                }
                .valueChanged(value: self.contactService.calls) { newValue in
                    if !newValue.isEmpty {
                        self.calls = newValue
                    }
                }
        }
    }
    
    func setupCall(hasVideo: Bool) {
        if self.authenticationService.connectedToSocket,
           self.authenticationService.sessionExists {
            self.fcsdkCallService.presentCommunication = true
            self.fcsdkCallService.destination = self.contactService.selectedContact?.number ?? ""
            self.fcsdkCallService.hasVideo = hasVideo
            self.fcsdkCallService.isOutgoing = true
        } else {
            //            notLoggedIn = true
        }
    }
    
    func processNotLoggedIn() async {
        await self.authenticationService.logout()
        KeychainItem.deleteSessionID()
        self.authenticationService.sessionID = KeychainItem.getSessionID
    }
}


