//
//  SettingsSheet.swift
//  SwiftFCSDKSample
//
//  Created by Cole M on 9/2/21.
//

import SwiftUI
import FCSDKiOS

struct SettingsSheet: View {

    @AppStorage("AudioOption") var selectedAudio = AudioOptions.ear
    @AppStorage("ResolutionOption") var selectedResolution = ResolutionOptions.auto
    @AppStorage("RateOption") var selectedFrameRate = FrameRateOptions.fro20
    @AppStorage("AutoAnswer") var autoAnswer = false

    
    enum AudioOptions: String, Equatable, CaseIterable {
        case ear = "Ear Piece"
        case speaker = "Speaker Phone"
    }
    
    enum ResolutionOptions: String, Equatable, CaseIterable {
        case auto = "auto"
        case res288p = "288p"
        case res480p = "480p"
        case res720p = "720p"
    }
    
    enum FrameRateOptions: String, Equatable, CaseIterable {
        case fro20 = "20fps"
        case fro30 = "30fps"
    }
    
    
    @EnvironmentObject private var authenticationService: AuthenticationService
    @Environment(\.presentationMode) var presentationMode
    @Binding var currentTabIndex: Int
    @Binding var showSubscriptionsSheet: Bool
    var parentTabIndex: Int
    
    var body: some View {
        GeometryReader { geometry in
        NavigationView {
            VStack(alignment: .leading, spacing: 5) {
                Group {
                Text("Audio Options")
                    .fontWeight(.light)
                    .multilineTextAlignment(.leading)
                Picker("", selection: $selectedAudio) {
                    ForEach(AudioOptions.allCases, id: \.self) { item in
                        Text(item.rawValue)
                    }
                }
                .onChange(of: self.selectedAudio, perform: { item in
                    self.selectAudio(audio: item)
                })
                        .pickerStyle(SegmentedPickerStyle())
                Divider()
                    .padding(.top)
                
                Text("Resolution Options")
                    .fontWeight(.light)
                    .multilineTextAlignment(.leading)
                Picker("", selection: $selectedResolution) {
                    ForEach(ResolutionOptions.allCases, id: \.self) { item in
                        Text(item.rawValue)
                    }
                }
                .onChange(of: self.selectedResolution, perform: { item in
                    self.selectResolution(res: item)
                })
                        .pickerStyle(SegmentedPickerStyle())
                Divider()
                    .padding(.top)
                
                Text("Frame Rate Options")
                    .fontWeight(.light)
                    .multilineTextAlignment(.leading)
                Picker("", selection: $selectedFrameRate) {
                    ForEach(FrameRateOptions.allCases, id: \.self) { item in
                        Text(item.rawValue)
                    }
                }
                .onChange(of: self.selectedFrameRate, perform: { item in
                    self.selectFramerate(rate: item)
                })
                        .pickerStyle(SegmentedPickerStyle())
                Divider()
                    .padding(.top)
                
                    Toggle("Auto-Answer", isOn: $autoAnswer)
                        .onAppear {
                          
                        }
                        .onChange(of: self.autoAnswer) { _ in
                            self.autoAnswerLogic()
                        }
            }
                Spacer()
                HStack {
                    VStack(alignment: .leading) {
                        Text("User: \(UserDefaults.standard.string(forKey: "Username") ?? "")").bold()
                        Text("App Version: \(Constants.SDK_VERSION_NUMBER)").fontWeight(.light)
                    }
                    Spacer()
                    Button {
                    Task {
                        await self.logout()
                    }
                } label: {
                    HStack {
                      Spacer()
                    Text("Logout")
                        .font(.title2)
                        .bold()
                    }
                }
                Spacer()
                }
            }
            .padding()
                .navigationBarTitle("Settings")
        }
        }
        .onAppear {
            self.currentTabIndex = self.parentTabIndex
        }
    }
    func logout() async {
        await authenticationService.logout()
    }
    
    
    func autoAnswerLogic() {
        if self.autoAnswer {
            
        } else {
        
        }
    }
    
    func selectAudio(audio: AudioOptions) {
        switch audio {
        case .ear:
            let ear = self.authenticationService.acbuc?.clientPhone.audioDeviceManager?.setAudioDevice(device: .earpiece)
            print("Is Ear", ear ?? false)
        case .speaker:
            let speaker = self.authenticationService.acbuc?.clientPhone.audioDeviceManager?.setAudioDevice(device: .speakerphone)
            print("Is Speaker:", speaker ?? false)
        }
    }
    
    func selectResolution(res: ResolutionOptions) {
        switch res {
        case .auto:
            self.authenticationService.acbuc?.clientPhone.preferredCaptureResolution = ACBVideoCapture.autoResolution;
        case .res288p:
            self.authenticationService.acbuc?.clientPhone.preferredCaptureResolution = ACBVideoCapture.resolution352x288;
        case .res480p:
            self.authenticationService.acbuc?.clientPhone.preferredCaptureResolution = ACBVideoCapture.resolution640x480;
        case .res720p:
            self.authenticationService.acbuc?.clientPhone.preferredCaptureResolution = ACBVideoCapture.resolution1280x720;
        }
    }

    func selectFramerate(rate: FrameRateOptions) {
        switch rate {
        case .fro20:
            self.authenticationService.acbuc?.clientPhone.preferredCaptureFrameRate = 20
        case .fro30:
            self.authenticationService.acbuc?.clientPhone.preferredCaptureFrameRate = 30
        }
    }
}

struct SettingsSheet_Previews: PreviewProvider {
    static var previews: some View {
        SettingsSheet(currentTabIndex: .constant(0), showSubscriptionsSheet: .constant(false), parentTabIndex: 0)
    }
}
