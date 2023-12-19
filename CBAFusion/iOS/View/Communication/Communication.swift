//
//  Communication.swift
//  CBAFusion
//
//  Created by Cole M on 8/31/21.
//

import SwiftUI
import FCSDKiOS
import AVKit

final class PipStateObject: ObservableObject {
    static let shared = PipStateObject()
    
    @Published var pip: Bool = false
    @Published var pipClickedID: UUID?
}

struct Communication: View {
    
    @State var inCall: Bool = true
    @State var showDetails: Bool = false
    @State var cameraFront: Bool = false
    @State var muteAudio: Bool = false
    @State var resumeAudio: Bool = false
    @State var muteVideo: Bool = false
    @State var resumeVideo: Bool = false
    @State var hold: Bool = false
    @State var resume: Bool = false
    @State var removePip: Bool = false
    @State var passDestination: String = ""
    @State var passVideo: Bool = false
    @State var currentTabIndex = 0
    @State var closeClickedID: UUID? = nil
    @State var cameraFrontID: UUID? = nil
    @State var cameraBackID: UUID? = nil
    @State var holdID: UUID? = nil
    @State var resumeID: UUID? = nil
    @State var muteAudioID: UUID? = nil
    @State var resumeAudioID: UUID? = nil
    @State var muteVideoID: UUID? = nil
    @State var resumeVideoID: UUID? = nil
    @State var hasStartedConnectingID: UUID? = nil
    @State var ringingID: UUID? = nil
    @State var hasConnectedID: UUID? = nil
    @State private var formattedCallDuration: Text?
    @State private var tappedShowBackground = false
    @Binding var destination: String
    @Binding var hasVideo: Bool
    @EnvironmentObject var pipStateObject: PipStateObject
    
    var selectedAudio = UserDefaults.standard.string(forKey: "AudioOption")
    var selectedResolution = UserDefaults.standard.string(forKey: "ResolutionOption")
    var selectedFrameRate = UserDefaults.standard.string(forKey: "RateOption")
    //    @AppStorage("AudioOption") var selectedAudio = ACBAudioDevice.earpiece
    //    @AppStorage("ResolutionOption") var selectedResolution = ResolutionOptions.auto
    //    @AppStorage("RateOption") var selectedFrameRate = FrameRateOptions.fro20
    
    static let timer = Timer.publish(every: 0.2, on: .main, in: .common).autoconnect()
    static let callDurationFormatter: DateComponentsFormatter = {
        let dateFormatter: DateComponentsFormatter
        dateFormatter = DateComponentsFormatter()
        dateFormatter.unitsStyle = .positional
        dateFormatter.allowedUnits = [.minute, .second]
        dateFormatter.zeroFormattingBehavior = .pad
        return dateFormatter
    }()
    
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authenticationService: AuthenticationService
    @EnvironmentObject var callKitManager: CallKitManager
    @EnvironmentObject var fcsdkCallService: FCSDKCallService
    @EnvironmentObject var contactService: ContactService
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topTrailing) {
                if #available(iOS 14, *) {
                    CommunicationViewControllerRepresentable(
                        removePip: self.$removePip,
                        destination: self.$passDestination,
                        hasVideo: self.$passVideo,
                        muteVideo: self.$muteVideo,
                        muteAudio: self.$muteAudio,
                        hold: self.$hold,
                        isOutgoing: self.$fcsdkCallService.isOutgoing,
                        fcsdkCall: self.$fcsdkCallService.fcsdkCall,
                        closeClickID: self.$closeClickedID,
                        cameraFrontID: self.$cameraFrontID,
                        cameraBackID: self.$cameraBackID,
                        holdID: self.$holdID,
                        resumeID: self.$resumeID,
                        muteAudioID: self.$muteAudioID,
                        resumeAudioID: self.$resumeAudioID,
                        muteVideoID: self.$muteVideoID,
                        resumeVideoID: self.$resumeVideoID,
                        hasStartedConnectingID: self.$hasStartedConnectingID,
                        ringingID: self.$ringingID,
                        hasConnectedID: self.$hasConnectedID
                    )
                    .ignoresSafeArea(.all)
                } else {
                    CommunicationViewControllerRepresentable(
                        removePip: self.$removePip,
                        destination: self.$passDestination,
                        hasVideo: self.$passVideo,
                        muteVideo: self.$muteVideo,
                        muteAudio: self.$muteAudio,
                        hold: self.$hold,
                        isOutgoing: self.$fcsdkCallService.isOutgoing,
                        fcsdkCall: self.$fcsdkCallService.fcsdkCall,
                        closeClickID: self.$closeClickedID,
                        cameraFrontID: self.$cameraFrontID,
                        cameraBackID: self.$cameraBackID,
                        holdID: self.$holdID,
                        resumeID: self.$resumeID,
                        muteAudioID: self.$muteAudioID,
                        resumeAudioID: self.$resumeAudioID,
                        muteVideoID: self.$muteVideoID,
                        resumeVideoID: self.$resumeVideoID,
                        hasStartedConnectingID: self.$hasStartedConnectingID,
                        ringingID: self.$ringingID,
                        hasConnectedID: self.$hasConnectedID
                    )
                }
                ZStack {
                    HStack {
                        Spacer()
                        self.formattedCallDuration
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(Color.white)
                            .padding()
                            .onReceive(Communication.timer) { _ in
                                self.updateFormattedCallDuration()
                            }
                        Spacer()
                    }
                }
                VStack(alignment: .trailing) {
                    HStack(alignment: .top) {
                        VStack {
                            HStack {
                                VStack {
                                    Button {
                                        self.authenticationService.showSettingsSheet = true
                                    } label: {
                                        Image(systemName: "gear")
                                            .resizable()
                                            .multilineTextAlignment(.trailing)
                                            .foregroundColor(self.authenticationService.showSettingsSheet ? Color.white : Color.blue)
                                            .frame(width: 25, height: 25)
                                            .padding()
                                    }
#if !targetEnvironment(simulator)
                                    if #available(iOS 15.0.0, *), fcsdkCallService.isBuffer {
                                        if UIDevice.current.userInterfaceIdiom == .phone {
                                            Button {
                                                self.pipStateObject.pip.toggle()
                                                self.pipStateObject.pipClickedID = UUID()
                                            } label: {
                                                ZStack {
                                                    Circle()
                                                        .fill(self.pipStateObject.pip ? Color.white : Color.gray)
                                                        .frame(width: 30, height: 30)
                                                    Image(systemName:self.pipStateObject.pip ? "pip.exit" : "pip.enter")
                                                        .resizable()
                                                        .multilineTextAlignment(.trailing)
                                                        .foregroundColor(Color.black)
                                                        .frame(width: 20, height: 20)
                                                        .padding()
                                                }
                                            }
                                        }
                                    }
#endif
                                }
                                Spacer()
                            }
                            HStack {
                                if authenticationService.showSystemFailed {
                                    Text("System Failed")
                                        .font(.caption)
                                        .foregroundColor(Color.red)
                                }
                                if authenticationService.showFailedSession {
                                    Text("Failed Session")
                                        .font(.caption)
                                        .foregroundColor(Color.red)
                                }
                                if authenticationService.showStartedSession {
                                    Text("Started Session")
                                        .font(.caption)
                                        .foregroundColor(Color.red)
                                }
                                if authenticationService.showReestablishedConnection {
                                    Text("Re-established Connection")
                                        .font(.caption)
                                        .foregroundColor(Color.red)
                                }
                                if authenticationService.showDidLoseConnection {
                                    Text("Did Lose Connection")
                                        .font(.caption)
                                        .foregroundColor(Color.red)
                                }
                                Spacer()
                            }
                            .padding()
                        }
                        
                        
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text(self.fcsdkCallService.fcsdkCall?.call?.remoteDisplayName ?? "")
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(Color.white)
                            Button {
                                if self.fcsdkCallService.hasConnected {
                                    self.fcsdkCallService.showDTMFSheet = true
                                }
                            } label: {
                                self.fcsdkCallService.hasConnected ? Text("Send DTMF") : Text("")
                                    .font(.title)
                                    .bold()
                            }
                            if #available(iOS 14, *) {
                                Text(fcsdkCallService.callStatus)
                                    .font(.caption)
                            } else {
                                Text(fcsdkCallService.callStatus)
                                    .font(.caption)
                                    .padding(EdgeInsets(top: 30, leading: 0, bottom: 0, trailing: 0))
                            }
                        }
                        .padding()
                    }
                    Spacer()
                    HStack(alignment: .center) {
                        if self.fcsdkCallService.hasConnected {
                            Spacer()
#if !targetEnvironment(simulator)
                            if #available(iOS 15.0.0, *), fcsdkCallService.isBuffer {
                                if UIDevice.current.userInterfaceIdiom == .pad {
                                    Button {
                                        self.pipStateObject.pip.toggle()
                                        self.pipStateObject.pipClickedID = UUID()
                                    } label: {
                                        ZStack {
                                            Circle()
                                                .fill(self.pipStateObject.pip ? Color.white : Color.gray)
                                                .frame(width: 50, height: 50)
                                            Image(systemName:self.pipStateObject.pip ? "pip.exit" : "pip.enter")
                                                .resizable()
                                                .multilineTextAlignment(.trailing)
                                                .foregroundColor(Color.black)
                                                .frame(width: 25, height: 25)
                                                .padding()
                                        }
                                    }
                                }
                            }
#endif
                            Button {
                                self.hold.toggle()
                                if self.hold {
                                    self.holdID = UUID()
                                } else {
                                    self.resumeID = UUID()
                                }
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(self.hold ? Color.white : Color.gray)
                                        .frame(width: 50, height: 50)
                                    Image(systemName: "pause.circle")
                                        .resizable()
                                        .multilineTextAlignment(.trailing)
                                        .foregroundColor(self.hold ? Color.gray : Color.white)
                                        .frame(width: 35, height: 35)
                                        .padding()
                                }
                            }
                            Button {
                                self.muteAudio.toggle()
                                if self.muteAudio {
                                    self.muteAudioID = UUID()
                                } else {
                                    self.resumeAudioID = UUID()
                                }
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(self.muteAudio ? Color.white : Color.gray)
                                        .frame(width: 50, height: 50)
                                    Image(systemName: self.muteAudio ? "mic.slash.fill" : "mic.fill")
                                        .resizable()
                                        .frame(width: 18, height: 26)
                                        .multilineTextAlignment(.trailing)
                                        .foregroundColor(self.muteAudio ? Color.gray : Color.yellow)
                                        .padding()
                                }
                            }
                            Button {
                                self.muteVideo.toggle()
                                if self.muteVideo {
                                    self.muteVideoID = UUID()
                                } else {
                                    self.resumeVideoID = UUID()
                                }
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(self.muteVideo ? Color.white : Color.gray)
                                        .frame(width: 50, height: 50)
                                    Image(systemName: self.muteVideo ? "video.slash.fill" : "video.fill")
                                        .resizable()
                                        .frame(width: 33, height: 20)
                                        .multilineTextAlignment(.trailing)
                                        .foregroundColor(self.muteVideo ? Color.gray : Color.blue)
                                        .padding()
                                }
                            }
                            Button {
                                self.cameraFront.toggle()
                                if self.cameraFront {
                                    self.cameraFrontID = UUID()
                                } else {
                                    self.cameraBackID = UUID()
                                }
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(self.cameraFront ? Color.white : Color.gray)
                                        .frame(width: 50, height: 50)
                                    Image(systemName: "arrow.triangle.2.circlepath.camera")
                                        .resizable()
                                        .multilineTextAlignment(.trailing)
                                        .foregroundColor(self.cameraFront ? Color.gray : Color.blue)
                                        .frame(width: 35, height: 25)
                                        .padding()
                                }
                            }
                        } else {
                            Spacer()
                        }
                        
                        Button {
                            self.fcsdkCallService.endPressed = true
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
                        if self.fcsdkCallService.hasConnected {
                            Spacer()
                        }
                        
                    }
                    HStack {
                        InCallQualityView()
                        Spacer()
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 1), value: 1)
        .frame(alignment: .trailing)
        .navigationBarHidden(true)
        .onAppear {
            self.hasStartedConnectingID = UUID()
            self.ringingID = UUID()
            self.hasConnectedID = UUID()
            self.passDestination = self.destination
            self.passVideo = self.hasVideo
            Task {
                await self.fcsdkCallService.startAudioSession()
            }
        }
        
        .onReceive(self.fcsdkCallService.$isStreaming, perform: { output in
            if output {
                self.fcsdkCallService.selectResolution(res: ResolutionOptions(rawValue: self.selectedResolution ?? ResolutionOptions.auto.rawValue)!)
                self.fcsdkCallService.selectFramerate(rate: FrameRateOptions(rawValue: self.selectedFrameRate ?? FrameRateOptions.fro20.rawValue)!)
                self.fcsdkCallService.selectAudio(audio: ACBAudioDevice(rawValue: self.selectedAudio ?? ACBAudioDevice.speakerphone.rawValue)!)
            }
        })
        .onReceive(self.fcsdkCallService.$hasEnded, perform: { output in
            if output {
                self.authenticationService.showSettingsSheet = false
                self.closeClickedID = UUID()
            }
        })
        .onDisappear(perform: {
            Task {
                try await self.contactService.fetchContactCalls(self.destination)
            }
        })
        .sheet(isPresented: self.$authenticationService.showSettingsSheet, onDismiss:  {
            if tappedShowBackground {
                self.fcsdkCallService.showBackgroundSelectorSheet = true
            }
        }, content: {
            SettingsSheet(tappedShowBackground: $tappedShowBackground)
                .environmentObject(authenticationService)
                .environmentObject(fcsdkCallService)
                .environmentObject(contactService)
        })
        .sheet(isPresented: self.$fcsdkCallService.showDTMFSheet) {
            if self.fcsdkCallService.showDTMFSheet {
                DTMFSheet()
            }
        }
        .fullScreenSheet(isPresented: self.$fcsdkCallService.showBackgroundSelectorSheet, onDismiss: {
            self.fcsdkCallService.showBackgroundSelectorSheet = false
            self.tappedShowBackground = false
        }, content: {
            if #available(iOS 15, *) {
                BackgroundSelector()
            }
        })
        .alert(isPresented: self.$fcsdkCallService.sendErrorMessage, content: {
            Alert(
                title: Text("\(self.fcsdkCallService.errorMessage)"),
                message: Text(""),
                dismissButton: .cancel(Text("Okay"), action: {
                    self.fcsdkCallService.sendErrorMessage = false
                    self.fcsdkCallService.hasEnded = true
                })
            )
        })
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
