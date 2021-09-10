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
    @State var pip: Bool = false
    @Binding var contact: Contact
    @Binding var showFullSheet: ActiveSheet?
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var callKitManager: CallKitManager
    @ObservedObject var call: FCSDKCall
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            if self.call.hasStartedConnecting {
                Text("Started Connecting")
            }
            if self.call.hasConnected {
                CommunicationViewControllerRepresenable(contact: self.$contact, pip: self.$pip)
                    .ignoresSafeArea(.all)
            }
            if self.call.isOutgoing {
                Text("Is Outgoing")
            }
            if self.call.isOnHold {
                Text("Is on Hold")
            }
            if self.call.hasEnded {
                Text("Has Ended")
            }
            if self.showDetails {
                Rectangle()
                    .fill(Color.black.opacity(0.3))
                    .animation(.easeInOut(duration: 1), value: 1)
                    .edgesIgnoringSafeArea(.all)
            }
            VStack(alignment: .trailing) {
                if self.showDetails {
                    HStack(alignment: .top) {
                        Button {
                            self.showSettings = true
                        } label: {
                            Image(systemName: "gear")
                                .resizable()
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(self.showSettings ? Color.white : Color.blue)
                                .frame(width: 25, height: 25)
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
                HStack(alignment: .center) {
                    Spacer()
                    Button {
                        self.pip.toggle()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(self.pip ? Color.white : Color.gray)
                                .frame(width: 50, height: 50)
                            Image(systemName:self.pip ? "pip.exit" : "pip.enter")
                                .resizable()
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(Color.black)
                                .frame(width: 25, height: 25)
                                .padding()
                        }
                    }
                    Button {
                        self.hold.toggle()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(self.hold ? Color.white : Color.gray)
                                .frame(width: 50, height: 50)
                            Image(systemName: "nosign")
                                .resizable()
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(self.hold ? Color.gray : Color.white)
                                .frame(width: 25, height: 25)
                                .padding()
                        }
                    }
                    Button {
                        self.muteAudio.toggle()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(self.muteAudio ? Color.white : Color.gray)
                                .frame(width: 50, height: 50)
                            Image(systemName: self.muteAudio ? "speaker.slash.fill" : "speaker.fill")
                                .resizable()
                                .frame(width: 25, height: 13)
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(self.muteAudio ? Color.gray : Color.yellow)
                                .padding()
                        }
                    }
                    Button {
                        self.muteVideo.toggle()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(self.muteVideo ? Color.white : Color.gray)
                                .frame(width: 50, height: 50)
                            Image(systemName: self.muteVideo ? "video.slash.fill" : "video.fill")
                                .resizable()
                                .frame(width: 25, height: 13)
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(self.muteVideo ? Color.gray : Color.blue)
                                .padding()
                        }
                    }
                    Button {
                        Task {
                            await self.callKitManager.finishEnd(call: self.call)
                            self.presentationMode.wrappedValue.dismiss()
                        }
                      
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 50, height: 50)
                            Image(systemName: "phone.down.fill")
                                .resizable()
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(Color.white)
                                .frame(width: 25, height: 13)
                                .padding()
                        }
                    }
                    Spacer()
                }
            }
            .animation(.easeInOut(duration: 1), value: 1)
            .frame(alignment: .trailing)
            .navigationBarHidden(true)
            
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
    
    func endCall() async {
        await self.callKitManager.finishEnd(call: self.call)
        
    }
}

struct Communication_Previews: PreviewProvider {
    static var previews: some View {
        Communication(contact: .constant(Contact(name: "", number: "", icon: "")), showFullSheet: .constant(.callSheet), call: FCSDKCall(handle: ""))
    }
}
