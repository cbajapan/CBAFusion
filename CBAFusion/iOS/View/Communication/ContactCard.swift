//
//  ContactCard.swift
//  CBAFusion
//
//  Created by Cole M on 1/5/22.
//

import SwiftUI
import FCSDKiOS
import AVKit

struct ContactCard: View {
    
    
    @Binding var destination: String
    @Binding var hasVideo: Bool
    @Binding var isOutgoing: Bool
    var contact: ContactModel?
    @State var notLoggedIn: Bool = false
    @State var calls: [FCSDKCall]?
    @EnvironmentObject var authenticationService: AuthenticationService
    @EnvironmentObject var fcsdkCallService: FCSDKCallService
    @EnvironmentObject var contactService: ContactService
    
    var body: some View {
        ZStack {
            VStack(alignment: .leading) {
                ScrollView {
                    ForEach(self.calls ?? [], id: \.id) { call in
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
        .navigationTitle(self.contactService.selectedContact?.username ?? "")
        .toolbar(content: {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
//                    Button {
//                        setupCall(hasVideo: false)
//                    } label: {
//                        Image(systemName: "phone")
//                            .foregroundColor(.blue)
//                    }
                    Button {
                        setupCall(hasVideo: true)
                    } label: {
                        Image(systemName: "video")
                            .foregroundColor(.blue)
                    }
                }
            }
        })
        .alert("We are sorry you don't seem to be logged in", isPresented: self.$notLoggedIn, actions: {
            Button("OK", role: .cancel) {
                processNotLoggedIn()
            }
        })
        .onAppear {
            Task {
                try await self.contactService.fetchContactCalls(destination)
                self.calls = self.contactService.calls
                self.contactService.selectedContact = self.contact
                self.fcsdkCallService.destination = self.contact?.number ?? ""
                await self.contactService.setCallsForContact(self.contact!)
            }
        }
        .onChange(of: self.contactService.calls) { newValue in
            self.calls = newValue
        }
    }
    
    
    func setupCall(hasVideo: Bool) {
        if authenticationService.acbuc != nil,
           self.authenticationService.connectedToSocket,
           self.authenticationService.sessionExists {
            self.fcsdkCallService.presentCommunication = true
            self.fcsdkCallService.destination = self.contactService.selectedContact?.number ?? ""
            self.fcsdkCallService.hasVideo = hasVideo
            self.fcsdkCallService.isOutgoing = true
        } else {
            notLoggedIn = true
        }
    }
    
    func processNotLoggedIn() {
        Task {
            await self.authenticationService.logout()
            KeychainItem.deleteSessionID()
            self.authenticationService.sessionID = KeychainItem.getSessionID
        }
    }
}

