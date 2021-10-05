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
    @State var endCall: Bool = false
    @Binding var destination: String
    @Binding var hasVideo: Bool
    @State var passDestination: String = ""
    @State var passVideo: Bool = false
    @Binding var showFullSheet: ActiveSheet?
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authenticationServices: AuthenticationService
    @State var currentTabIndex = 0
    
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            CommunicationViewControllerRepresenable(pip: self.$pip, acbuc: self.$authenticationServices.acbuc, destination: self.$passDestination, hasVideo: self.$passVideo, endCall: self.$endCall)
                    .ignoresSafeArea(.all)

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
                            Text("1002 | 1002@la-latest-qa.cbaqa.com")
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
                            self.endCall = true
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
        .onAppear {
            self.passDestination = self.destination
            self.passVideo = self.hasVideo
        }
        .onTapGesture {
            self.showDetails = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: {
                self.showDetails = false
            })
        }

        .sheet(isPresented: self.$showSettings) {
            SettingsSheet(currentTabIndex: self.$currentTabIndex, showSubscriptionsSheet: self.$showSettings, parentTabIndex: 0)
        }
    }
}
