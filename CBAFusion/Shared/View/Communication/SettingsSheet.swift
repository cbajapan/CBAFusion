//
//  SettingsSheet.swift
//  CBAFusion
//
//  Created by Cole M on 9/2/21.
//

import SwiftUI
import FCSDKiOS


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


struct SettingsSheet: View {
    
    @AppStorage("AudioOption") var selectedAudio = AudioOptions.ear
    @AppStorage("ResolutionOption") var selectedResolution = ResolutionOptions.auto
    @AppStorage("RateOption") var selectedFrameRate = FrameRateOptions.fro20
    @AppStorage("AutoAnswer") var autoAnswer = false
    
    
    @EnvironmentObject private var authenticationService: AuthenticationService
    @EnvironmentObject private var fcsdkCallService: FCSDKCallService
    @Environment(\.presentationMode) var presentationMode
    @Binding var currentTabIndex: Int
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
                        .onAppear {
                            self.authenticationService.selectAudio(audio: self.selectedAudio)
                        }
                        .onChange(of: self.selectedAudio, perform: { item in
                            self.authenticationService.selectAudio(audio: item)
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
                        .onAppear {
                            self.authenticationService.selectResolution(res: self.selectedResolution)
                        }
                        .onChange(of: self.selectedResolution, perform: { item in
                            self.authenticationService.selectResolution(res: item)
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
                        .onAppear {
                            self.authenticationService.selectFramerate(rate: self.selectedFrameRate)
                        }
                        .onChange(of: self.selectedFrameRate, perform: { item in
                            self.authenticationService.selectFramerate(rate: item)
                        })
                        .pickerStyle(SegmentedPickerStyle())
                        Divider()
                            .padding(.top)
                        
                        Toggle("Auto-Answer", isOn: $autoAnswer)
                            .onChange(of: self.autoAnswer) { _ in
                                self.autoAnswerLogic()
                            }
                    }
                    Divider()
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
}

struct SettingsSheet_Previews: PreviewProvider {
    static var previews: some View {
        SettingsSheet(currentTabIndex: .constant(0), parentTabIndex: 0)
    }
}
