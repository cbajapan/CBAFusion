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
    
    
    @State var selectedResolutionDuringCall: Bool = false
    @State var selectedFrameRateDuringCall: Bool = false
    
    @AppStorage("AudioOption") var selectedAudio = AudioOptions.ear
    @AppStorage("ResolutionOption") var selectedResolution = ResolutionOptions.auto
    @AppStorage("RateOption") var selectedFrameRate = FrameRateOptions.fro20
    
    
    @EnvironmentObject private var authenticationService: AuthenticationService
    @EnvironmentObject private var contactService: ContactService
    @EnvironmentObject private var fcsdkCallService: FCSDKCallService
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        GeometryReader { geometry in
            NavigationView {
                ZStack {
                    
                    if self.contactService.showProgress || self.authenticationService.showProgress {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: colorScheme == .dark ? .white : .black))
                            .scaleEffect(1.5)
                    }
                    
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Group {
                            if UIDevice.current.userInterfaceIdiom == .phone {
                                Text("Audio Options")
                                    .fontWeight(.light)
                                    .multilineTextAlignment(.leading)
                                Picker("", selection: $selectedAudio) {
                                    ForEach(AudioOptions.allCases, id: \.self) { item in
                                        Text(item.rawValue)
                                    }
                                }
                                .onChange(of: self.selectedAudio, perform: { item in
                                    self.fcsdkCallService.selectAudio(audio: item)
                                })
                                .pickerStyle(SegmentedPickerStyle())
                                Divider()
                                    .padding(.top)
                            }
                            
                            Text("Resolution Options")
                                .fontWeight(.light)
                                .multilineTextAlignment(.leading)
                            Picker("", selection: $selectedResolution) {
                                ForEach(ResolutionOptions.allCases, id: \.self) { item in
                                    Text(item.rawValue)
                                }
                            }
                            .onChange(of: self.selectedResolution, perform: { item in
                                self.fcsdkCallService.selectResolution(res: item)
                                if self.fcsdkCallService.presentCommunication {
                                selectedResolutionDuringCall = true
                                }
                            })
                            .pickerStyle(SegmentedPickerStyle())
                            if selectedResolutionDuringCall {
                                Text("Sorry you can't change the resolution during calls, but we will change it automatically on the next call")
                                    .animation(.easeInOut(duration: 20), value: 1)
                                    .transition(.slide)
                                    .task {
                                        await removeResolutionMessage()
                                    }
                                    .foregroundColor(.red)
                                    .font(Font.system(size: 12))
                            }
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
                                self.fcsdkCallService.selectFramerate(rate: item)
                                if self.fcsdkCallService.presentCommunication {
                                selectedFrameRateDuringCall = true
                                }
                            })
                            .pickerStyle(SegmentedPickerStyle())
                            if selectedFrameRateDuringCall {
                                Text("Sorry you can't change the frame rate during calls, but we will change it automatically on the next call")
                                    .task {
                                        await removeFrameRateMessage()
                                    }
                                    .animation(.easeInOut(duration: 20), value: 1)
                                    .transition(.slide)
                                    .foregroundColor(.red)
                                    .font(Font.system(size: 12))
                            }
                        }
                        Divider()
                        Spacer()
                        if self.fcsdkCallService.fcsdkCall?.activeCall == false ||
                           self.fcsdkCallService.fcsdkCall?.activeCall == nil
                        {
                        Button("Clear Call History", action: {
                            Task {
                                await self.fcsdkCallService.contactService?.deleteCalls()
                            }
                        })
                        }
                        Divider()
                        HStack {
                            VStack(alignment: .leading) {
                                Text("User: \(UserDefaults.standard.string(forKey: "Username") ?? "")").bold()
                                Text("App Version: \(UIApplication.appVersion!)").fontWeight(.light)
                                Text("FCSDK Version: \(FCSDKiOS.Constants.SDK_VERSION_NUMBER)").fontWeight(.light)
                            }
                            Spacer()
                            if self.fcsdkCallService.fcsdkCall?.activeCall == false ||
                               self.fcsdkCallService.fcsdkCall?.activeCall == nil
                            {
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
                            }
                            Spacer()
                        }
                    }
                }
                .padding()
                .onAppear {
                    self.fcsdkCallService.selectResolution(res: self.selectedResolution)
                    self.fcsdkCallService.selectFramerate(rate: self.selectedFrameRate)
                    self.fcsdkCallService.selectAudio(audio: self.selectedAudio)
                }
                .onDisappear {
                    Task {
                    try await self.contactService.fetchContacts()
                    }
                }
                .padding()
                .navigationBarTitle("Settings")
            }
        }
        .alert("There was an error deleting Call History", isPresented: self.$contactService.showError) {
            Button("OK", role: .cancel) {
            }
        }
    }
    
    private func removeResolutionMessage() async {
        try? await Task.sleep(nanoseconds: 5_500_000_000)
        selectedResolutionDuringCall = false
    }
    
    private func removeFrameRateMessage() async {
        try? await Task.sleep(nanoseconds: 5_500_000_000)
        selectedFrameRateDuringCall = false
    }
    
    func logout() async {
        await authenticationService.logout()
    }
}

