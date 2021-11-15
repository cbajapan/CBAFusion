//
//  Communication.swift
//  SwiftFCSDKSample
//
//  Created by Cole M on 8/31/21.
//

import SwiftUI
import FCSDKiOS

struct Communication: View {
    
    @State var inCall: Bool = true
    @State var showDetails: Bool = false
    @State var showSettings: Bool = false
    @State var cameraFront: Bool = false
    @State var cameraBack: Bool = false
    @State var muteAudio: Bool = false
    @State var resumeAudio: Bool = false
    @State var muteVideo: Bool = false
    @State var resumeVideo: Bool = false
    @State var hold: Bool = false
    @State var resume: Bool = false
    @State var pip: Bool = false
    @State var removePip: Bool = false
    @State var endCall: Bool = false
    @Binding var destination: String
    @Binding var hasVideo: Bool
    @State var passDestination: String = ""
    @State var passVideo: Bool = false
    @Binding var isOutgoing: Bool
    @State var showSheet: CommunicationSheets?
    
    
    static let timer = Timer.publish(every: 0.2, on: .main, in: .common).autoconnect()
    static let callDurationFormatter: DateComponentsFormatter = {
        let dateFormatter: DateComponentsFormatter
        dateFormatter = DateComponentsFormatter()
        dateFormatter.unitsStyle = .positional
        dateFormatter.allowedUnits = [.minute, .second]
        dateFormatter.zeroFormattingBehavior = .pad

        return dateFormatter
    }()
    @State private var formattedCallDuration: Text?
    
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authenticationServices: AuthenticationService
    @EnvironmentObject var callKitManager: CallKitManager
    @EnvironmentObject var fcsdkCallService: FCSDKCallService
    @State var currentTabIndex = 0
    
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topTrailing) {
                CommunicationViewControllerRepresenable(
                    pip: self.$pip,
                    removePip: self.$removePip,
                    cameraFront: self.$cameraFront,
                    cameraBack: self.$cameraBack,
                    destination: self.$passDestination,
                    hasVideo: self.$passVideo,
                    endCall: self.$endCall,
                    muteVideo: self.$muteVideo,
                    resumeVideo: self.$resumeVideo,
                    muteAudio: self.$muteAudio,
                    resumeAudio: self.$resumeAudio,
                    hold: self.$hold,
                    resume: self.$resume,
                    acbuc: self.$authenticationServices.acbuc,
                    fcsdkCall: self.$fcsdkCallService.fcsdkCall,
                    isOutgoing: self.$isOutgoing
                )
                    .ignoresSafeArea(.all)
    
                VStack(alignment: .trailing) {
                        HStack(alignment: .top) {
                            Button {
                                self.showSheet = .settingsSheet
                            } label: {
                                Image(systemName: "gear")
                                    .resizable()
                                    .multilineTextAlignment(.trailing)
                                    .foregroundColor(self.showSettings ? Color.white : Color.blue)
                                    .frame(width: 25, height: 25)
                                    .padding()
                            }
                            Spacer()
                            self.formattedCallDuration
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(Color.white)
                                .padding()
                                .onReceive(Communication.timer) { _ in
                                    self.updateFormattedCallDuration()
                                }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text(self.fcsdkCallService.fcsdkCall?.call?.remoteDisplayName ?? "")
                                    .multilineTextAlignment(.trailing)
                                    .foregroundColor(Color.white)
                                    .padding()
                            }
                        }
                    Spacer()
                    HStack(alignment: .center) {
                        Spacer()
//                        Button {
//                            self.pip.toggle()
//                            if !self.pip {
//                                self.removePip = true
//                            } else if self.pip {
//                                self.removePip = false
//                            }
//                        } label: {
//                            ZStack {
//                                Circle()
//                                    .fill(self.pip ? Color.white : Color.gray)
//                                    .frame(width: 50, height: 50)
//                                Image(systemName:self.pip ? "pip.exit" : "pip.enter")
//                                    .resizable()
//                                    .multilineTextAlignment(.trailing)
//                                    .foregroundColor(Color.black)
//                                    .frame(width: 25, height: 25)
//                                    .padding()
//                            }
//                        }
                        Button {
                            self.hold.toggle()
                            if !self.hold {
                                self.resume = true
                            } else if self.hold {
                                self.resume = false
                            }
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
                            if !self.muteAudio {
                                self.resumeAudio = true
                            } else if self.muteAudio {
                                self.resumeAudio = false
                            }
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
                            if !self.muteVideo {
                                self.resumeVideo = true
                            } else if self.muteVideo {
                                self.resumeVideo = false
                            }
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
                            self.cameraFront.toggle()
                            if !self.cameraFront {
                                self.cameraBack = true
                            } else if self.cameraFront {
                                self.cameraBack = false
                            }
                        } label: {
                            ZStack {
                            Circle()
                                .fill(self.hold ? Color.white : Color.gray)
                                .frame(width: 50, height: 50)
                            Image(systemName: "arrow.triangle.2.circlepath.camera")
                                .resizable()
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(self.cameraFront ? Color.white : Color.blue)
                                .frame(width: 35, height: 25)
                                .padding()
                            }
                        }
                        Button {
                            self.endCall.toggle()
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
            }
        }
        .animation(.easeInOut(duration: 1), value: 1)
        .frame(alignment: .trailing)
        .navigationBarHidden(true)
        .onAppear {
            self.passDestination = self.destination
            self.passVideo = self.hasVideo
        }
        .onChange(of: self.fcsdkCallService.hasEnded) { newValue in
            if newValue {
                self.presentationMode.wrappedValue.dismiss()
            }
        }
        .onChange(of: self.fcsdkCallService.presentInCommunication) { newValue in
            self.showSheet = newValue
        }
        .onDisappear(perform: {
            self.fcsdkCallService.presentCommunication = false
            self.fcsdkCallService.hasEnded = false
        })
        .sheet(item: self.$showSheet) { sheet in
            switch sheet {
            case .settingsSheet:
                SettingsSheet(currentTabIndex: self.$currentTabIndex, parentTabIndex: 0)
            case .dtmfSheet:
                DTMFSheet()
            }
           
        }
        .sheet(isPresented: self.$fcsdkCallService.showDTMFSheet) {
            DTMFSheet()
        }
    }
    
    /// Updates the the formatted call duration Text view for an active call's current duration, otherwise sets it to `nil`.
    func updateFormattedCallDuration() {
        if self.fcsdkCallService.hasConnected, let formattedString = Communication.callDurationFormatter.string(from: self.fcsdkCallService.duration) {
            formattedCallDuration = Text(formattedString)
        } else {
            formattedCallDuration = nil
        }
    }
    

}

enum CommunicationSheets: Identifiable {
    case settingsSheet
    case dtmfSheet
    
    var id: Int {
        hashValue
    }
}
