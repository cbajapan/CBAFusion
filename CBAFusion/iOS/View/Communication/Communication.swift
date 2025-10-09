//
//  Communication.swift
//  CBAFusion
//
//  Created by Cole M on 8/31/21.
//

import SwiftUI
import FCSDKiOS
import AVKit

/// An `ObservableObject` for managing the Picture-in-Picture (PiP) state across the app.
final class PipStateObject: ObservableObject {
    @MainActor static let shared = PipStateObject()
    
    @Published var pip: Bool = false
    @Published var pipClickedID: UUID?
}

/// The view for managing and displaying a communication call interface.
struct Communication: View {
    
    @State private var inCall: Bool = true
    @State private var showDetails: Bool = false
    @State private var cameraFront: Bool = false
    @State private var muteAudio: Bool = false
    @State private var resumeAudio: Bool = false
    @State private var muteVideo: Bool = false
    @State private var resumeVideo: Bool = false
    @State private var hold: Bool = false
    @State private var resume: Bool = false
    @State private var removePip: Bool = false
    @State private var passDestination: String = ""
    @State private var passVideo: Bool = false
    @State private var currentTabIndex: Int = 0
    @State private var closeClickedID: UUID? = nil
    @State private var cameraFrontID: UUID? = nil
    @State private var cameraBackID: UUID? = nil
    @State private var holdID: UUID? = nil
    @State private var resumeID: UUID? = nil
    @State private var muteAudioID: UUID? = nil
    @State private var resumeAudioID: UUID? = nil
    @State private var muteVideoID: UUID? = nil
    @State private var resumeVideoID: UUID? = nil
    @State private var hasStartedConnectingID: UUID? = nil
    @State private var ringingID: UUID? = nil
    @State private var hasConnectedID: UUID? = nil
    @State private var formattedCallDuration: Text?
    @State private var tappedShowBackground = false
    @Binding var destination: String
    @Binding var hasVideo: Bool
    @EnvironmentObject var pipStateObject: PipStateObject
    
    /// User settings for audio, resolution, and frame rate.
    private var selectedAudio: String? {
        UserDefaults.standard.string(forKey: "AudioOption")
    }
    private var selectedResolution: String? {
        UserDefaults.standard.string(forKey: "ResolutionOption")
    }
    private var selectedFrameRate: String? {
        UserDefaults.standard.string(forKey: "RateOption")
    }
    
    /// Timer for updating call duration.
    private static let timer = Timer.publish(every: 0.2, on: .main, in: .common).autoconnect()
    
    /// Formatter for displaying the call duration.
    private static let callDurationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()
    
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authenticationService: AuthenticationService
    @EnvironmentObject var callKitManager: CallKitManager
    @EnvironmentObject var fcsdkCallService: FCSDKCallService
    @EnvironmentObject var contactService: ContactService
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topTrailing) {
                
                // Communication ViewController wrapper
                CommunicationViewControllerRepresentable(
                    removePip: $removePip,
                    destination: $passDestination,
                    hasVideo: $passVideo,
                    muteVideo: $muteVideo,
                    muteAudio: $muteAudio,
                    hold: $hold,
                    isOutgoing: $fcsdkCallService.isOutgoing,
                    fcsdkCall: $fcsdkCallService.fcsdkCall,
                    closeClickID: $closeClickedID,
                    cameraFrontID: $cameraFrontID,
                    cameraBackID: $cameraBackID,
                    holdID: $holdID,
                    resumeID: $resumeID,
                    muteAudioID: $muteAudioID,
                    resumeAudioID: $resumeAudioID,
                    muteVideoID: $muteVideoID,
                    resumeVideoID: $resumeVideoID,
                    hasStartedConnectingID: $hasStartedConnectingID,
                    ringingID: $ringingID,
                    hasConnectedID: $hasConnectedID
                )
                .edgesIgnoringSafeArea(.all)
                
                // Call duration display
                HStack {
                    Spacer()
                    formattedCallDuration
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(Color.white)
                        .padding()
                        .onReceive(Self.timer) { _ in
                            updateFormattedCallDuration()
                        }
                    Spacer()
                }
                
                // Control buttons and status indicators
                VStack(alignment: .trailing) {
                    HStack(alignment: .top) {
                        VStack {
                            HStack {
                                VStack {
                                    // Settings Button
                                    Button {
                                        authenticationService.showSettingsSheet = true
                                    } label: {
                                        Image(systemName: "gear")
                                            .resizable()
                                            .foregroundColor(authenticationService.showSettingsSheet ? Color.white : Color.blue)
                                            .frame(width: 25, height: 25)
                                            .padding()
                                    }
                                    
#if !targetEnvironment(simulator)
                                    // PiP Toggle Button (available from iOS 15 on iPads)
                                    if #available(iOS 15.0, *), fcsdkCallService.isBuffer, UIDevice.current.userInterfaceIdiom == .phone {
                                        Button {
                                            pipStateObject.pip.toggle()
                                            pipStateObject.pipClickedID = UUID()
                                        } label: {
                                            ZStack {
                                                Circle()
                                                    .fill(pipStateObject.pip ? Color.white : Color.gray)
                                                    .frame(width: 30, height: 30)
                                                Image(systemName: pipStateObject.pip ? "pip.exit" : "pip.enter")
                                                    .resizable()
                                                    .foregroundColor(Color.black)
                                                    .frame(width: 20, height: 20)
                                                    .padding()
                                            }
                                        }
                                    }
#endif
                                }
                                Spacer()
                            }
                            HStack {
                                statusText(authenticationService)
                                Spacer()
                            }
                            .padding()
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text(fcsdkCallService.fcsdkCall?.call?.remoteDisplayName ?? "")
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(Color.white)
                            Button {
                                if fcsdkCallService.hasConnected {
                                    fcsdkCallService.showDTMFSheet = true
                                }
                            } label: {
                                fcsdkCallService.hasConnected ? Text("Send DTMF") : Text("")
                                    .font(.title)
                                    .bold()
                            }
                            Text(fcsdkCallService.callStatus)
                                .font(.caption)
                                .padding(.top, 30)
                        }
                        .padding()
                    }
                    Spacer()
                    
                    // Main control buttons
                    HStack(alignment: .center) {
                        if fcsdkCallService.hasConnected {
                            Spacer()
#if !targetEnvironment(simulator)
                            // PiP Toggle Button (available from iOS 15 on iPads)
                            if #available(iOS 15.0, *), fcsdkCallService.isBuffer, UIDevice.current.userInterfaceIdiom == .pad {
                                Button {
                                    pipStateObject.pip.toggle()
                                    pipStateObject.pipClickedID = UUID()
                                } label: {
                                    ZStack {
                                        Circle()
                                            .fill(pipStateObject.pip ? Color.white : Color.gray)
                                            .frame(width: 50, height: 50)
                                        Image(systemName: pipStateObject.pip ? "pip.exit" : "pip.enter")
                                            .resizable()
                                            .foregroundColor(Color.black)
                                            .frame(width: 25, height: 25)
                                            .padding()
                                    }
                                }
                            }
#endif
                            
                            controlButton(
                                icon: "pause.circle",
                                secondaryColor: .white,
                                foregroundSize: .init(width: 50, height: 50),
                                imageSize: .init(width: 35, height: 35),
                                condition: hold,
                                action: {
                                    hold.toggle()
                                    hold ? (holdID = UUID()) : (resumeID = UUID())
                                })
                            controlButton(
                                icon: "mic.fill",
                                secondaryColor: .yellow,
                                foregroundSize: .init(width: 50, height: 50),
                                imageSize: .init(width: 18, height: 26),
                                condition: muteAudio,
                                action: {
                                    muteAudio.toggle()
                                    muteAudio ? (muteAudioID = UUID()) : (resumeAudioID = UUID())
                                })
                            controlButton(
                                icon: "video.fill",
                                secondaryColor: .blue,
                                foregroundSize: .init(width: 50, height: 50),
                                imageSize: .init(width: 33, height: 20),
                                condition: muteVideo,
                                action: {
                                    muteVideo.toggle()
                                    muteVideo ? (muteVideoID = UUID()) : (resumeVideoID = UUID())
                                })
                            controlButton(
                                icon: "arrow.triangle.2.circlepath.camera",
                                secondaryColor: .blue,
                                foregroundSize: .init(width: 50, height: 50),
                                imageSize: .init(width: 35, height: 25),
                                condition: cameraFront,
                                action: {
                                    cameraFront.toggle()
                                    cameraFront ? (cameraFrontID = UUID()) : (cameraBackID = UUID())
                                })
                        } else {
                            Spacer()
                        }
                        
                        endCallButton()
                        
                        if fcsdkCallService.hasConnected {
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
            initializeCall()
        }
        .onReceive(fcsdkCallService.$isStreaming) { output in
            if output {
                configureCallSettings()
            }
        }
        .onReceive(fcsdkCallService.$hasEnded) { output in
            if output {
                handleCallEnd()
            }
        }
        .onDisappear {
            Task {
                try await contactService.fetchContactCalls(destination)
            }
        }
        .sheet(isPresented: $authenticationService.showSettingsSheet, onDismiss: {
            if tappedShowBackground {
                fcsdkCallService.showBackgroundSelectorSheet = true
            }
        }, content: {
            SettingsSheet(tappedShowBackground: $tappedShowBackground)
                .environmentObject(authenticationService)
                .environmentObject(fcsdkCallService)
                .environmentObject(contactService)
        })
        .sheet(isPresented: $fcsdkCallService.showDTMFSheet) {
            if fcsdkCallService.showDTMFSheet {
                DTMFSheet()
            }
        }
        .fullScreenSheet(isPresented: $fcsdkCallService.showBackgroundSelectorSheet, onDismiss: {
            fcsdkCallService.showBackgroundSelectorSheet = false
            tappedShowBackground = false
        }, content: {
            if #available(iOS 15, *) {
                BackgroundSelector()
            }
        })
        .alert(isPresented: $fcsdkCallService.sendErrorMessage) {
            Alert(
                title: Text(fcsdkCallService.errorMessage),
                dismissButton: .cancel(Text("Okay"), action: {
                    fcsdkCallService.sendErrorMessage = false
                    fcsdkCallService.hasEnded = true
                })
            )
        }
    }
    
    /// Updates the formatted call duration display.
    private func updateFormattedCallDuration() {
        if fcsdkCallService.hasConnected, let formattedString = Self.callDurationFormatter.string(from: fcsdkCallService.duration) {
            formattedCallDuration = Text(formattedString)
        } else {
            formattedCallDuration = nil
        }
    }
    
    /// Initializes call state and starts audio session.
    @MainActor private func initializeCall() {
        hasStartedConnectingID = UUID()
        ringingID = UUID()
        hasConnectedID = UUID()
        passDestination = destination
        passVideo = hasVideo
        Task { @MainActor in
            await fcsdkCallService.startAudioSession()
        }
    }
    
    /// Configures call settings based on user preferences.
    private func configureCallSettings() {
        if let resolution = ResolutionOptions(rawValue: selectedResolution ?? ResolutionOptions.auto.rawValue) {
            fcsdkCallService.selectResolution(res: resolution)
        }
        if let frameRate = FrameRateOptions(rawValue: selectedFrameRate ?? FrameRateOptions.fro20.rawValue) {
            fcsdkCallService.selectFramerate(rate: frameRate)
        }
        if let audioOption = ACBAudioDevice(rawValue: selectedAudio ?? ACBAudioDevice.speakerphone.rawValue) {
            fcsdkCallService.selectAudio(audio: audioOption)
        }
    }
    
    /// Handles actions when the call ends.
    private func handleCallEnd() {
        authenticationService.showSettingsSheet = false
        closeClickedID = UUID()
    }
    
    /// Generates a control button with the specified icon, condition, and action.
    private func controlButton(
        icon: String,
        secondaryColor: Color,
        foregroundSize: CGSize,
        imageSize: CGSize,
        condition: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(condition ? .white : .gray)
                    .frame(width: foregroundSize.width, height: foregroundSize.height)
                Image(systemName: icon)
                    .resizable()
                    .foregroundColor(condition ? .gray : secondaryColor)
                    .frame(width: imageSize.width, height: imageSize.height)
                    .padding()
            }
        }
    }
    
    /// Generates the end call button.
    private func endCallButton() -> some View {
        Button {
            fcsdkCallService.endPressed = true
        } label: {
            ZStack {
                Circle()
                    .fill(Color.red)
                    .frame(width: 50, height: 50)
                Image(systemName: "phone.down.fill")
                    .resizable()
                    .foregroundColor(Color.white)
                    .frame(width: 25, height: 13)
                    .padding()
            }
        }
    }
    
    /// Creates a view displaying the status text based on the authentication service.
    private func statusText(_ service: AuthenticationService) -> some View {
        VStack {
            if service.showSystemFailed {
                Text("System Failed")
                    .font(.caption)
                    .foregroundColor(Color.red)
            }
            if service.showFailedSession {
                Text("Failed Session")
                    .font(.caption)
                    .foregroundColor(Color.red)
            }
            if service.showStartedSession {
                Text("Started Session")
                    .font(.caption)
                    .foregroundColor(Color.red)
            }
            if service.showReestablishedConnection {
                Text("Re-established Connection")
                    .font(.caption)
                    .foregroundColor(Color.red)
            }
            if service.showDidLoseConnection {
                Text("Did Lose Connection")
                    .font(.caption)
                    .foregroundColor(Color.red)
            }
        }
    }
}
