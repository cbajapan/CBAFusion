//
//  Communication.swift
//  SwiftFCSDKSample
//
//  Created by Cole M on 8/31/21.
//

import SwiftUI

struct Communication: View {
    
    @State var inCall: Bool = true
    @State var showDetails: Bool = false
    @State var showSettings: Bool = false
    @State var muteAudio: Bool = false
    @State var muteVideo: Bool = false
    @State var hold: Bool = false
    @Binding var contact: Contact
    @Binding var callStarted: Bool
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
                if self.inCall {
                    CommunicationViewControllerRepresenable(contact: self.$contact)
                      .ignoresSafeArea(.all)
                    if self.showDetails {
                        Rectangle()
                            .fill(Color.black.opacity(0.3))
                            .animation(.easeInOut(duration: 1))
                            .edgesIgnoringSafeArea(.all)
                    }
                    VStack(alignment: .trailing) {
                        if self.showDetails {
                            HStack(alignment: .top) {
                                Button {
                                    self.showSettings = true
                                } label: {
                                    Text("Settings")
                                        .fontWeight(.bold)
                                        .multilineTextAlignment(.leading)
                                        .foregroundColor(Color.blue)
                                        .padding()
                                }
                                Spacer()
                                VStack(alignment: .trailing) {
                                    Text(self.contact.name)
                                        .multilineTextAlignment(.trailing)
                                        .foregroundColor(Color.white)
                                        .padding()
                                }
                            }
                        }
                        Spacer()
                        HStack {
                            Button {
                                self.hold.toggle()
                            } label: {
                                Text( self.hold ? "On Hold" : "Hold Call")
                                    .bold()
                                    .multilineTextAlignment(.trailing)
                                    .foregroundColor(self.hold ? Color.gray : Color.green)
                                    .padding()
                            }
                            Button {
                                self.muteAudio.toggle()
                            } label: {
                                Image(systemName: self.muteAudio ? "speaker.slash.fill" : "speaker.fill")
                                    .resizable()
                                    .frame(width: 40, height: 30)
                                    .multilineTextAlignment(.trailing)
                                    .foregroundColor(self.muteAudio ? Color.gray : Color.yellow)
                                    .padding()
                            }
                            Button {
                                self.muteVideo.toggle()
                            } label: {
                                Image(systemName: self.muteVideo ? "video.slash.fill" : "video.fill")
                                    .resizable()
                                    .frame(width: 40, height: 30)
                                    .multilineTextAlignment(.trailing)
                                    .foregroundColor(self.muteVideo ? Color.gray : Color.blue)
                                    .padding()
                            }
                            Button {
                                self.callStarted = false
                            } label: {
                                Image(systemName: "phone.down.fill")
                                    .resizable()
                                    .frame(width: 50, height: 20)
                                    .multilineTextAlignment(.trailing)
                                    .foregroundColor(Color.red)
                                    .padding()
                            }
                        }
                    }
                    .animation(.easeInOut(duration: 1))
                    .frame(alignment: .trailing)
                    .navigationBarHidden(true)
                }
        }
        .onTapGesture {
            self.showDetails = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: {
                self.showDetails = false
            })
        }
        .sheet(isPresented: self.$showSettings) {
            SettingsSheet()
        }
    }
}

struct Communication_Previews: PreviewProvider {
    static var previews: some View {
        Communication(contact: .constant(Contact(name: "", number: "", icon: "")), callStarted: .constant(true))
    }
}
