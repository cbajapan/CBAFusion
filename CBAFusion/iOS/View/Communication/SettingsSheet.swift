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
    case wiredHeadset = "Wired Headset"
    case bluetooth = "Bluetooth"
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
    case fro60 = "60fps"
}

enum ScaleOptions: String, Equatable, CaseIterable {
    case horizontal = "Horizontal"
    case vertical = "Vertical"
    case fill = "Fill"
    case none = "None"
}


struct SettingsSheet: View {
    
    
    @State var switchedViewType: Bool = false
    @State var switchedMirroredViewType: Bool = false
    @Binding var tappedShowBackground: Bool
    @State var selectedAudio = UserDefaults.standard.string(forKey: "AudioOption") ?? ACBAudioDevice.speakerphone.rawValue
    @State var selectedResolution = UserDefaults.standard.string(forKey: "ResolutionOption") ?? ResolutionOptions.auto.rawValue
    @State var selectedFrameRate = UserDefaults.standard.string(forKey: "RateOption") ?? FrameRateOptions.fro20.rawValue
    @State var selectedDefaultAudio = UserDefaults.standard.string(forKey: "DefaultAudio") ?? ACBAudioDevice.speakerphone.rawValue
    @State var remoteScaleOption = UserDefaults.standard.string(forKey: "RemoteScale") ?? ScaleOptions.horizontal.rawValue
    @State var localScaleOption = UserDefaults.standard.string(forKey: "LocalScale") ?? ScaleOptions.horizontal.rawValue
    @State var scaleWithOrientation = UserDefaults.standard.bool(forKey: "ScaleWithOrientation")
    @State var preferredAudio = UserDefaults.standard.string(forKey: MediaValue.keyAudioDirection.rawValue) ?? "SendAndReceive"
    @State var preferredVideo = UserDefaults.standard.string(forKey: MediaValue.keyVideoDirection.rawValue) ?? "SendAndReceive"
    
    @EnvironmentObject private var authenticationService: AuthenticationService
    @EnvironmentObject private var contactService: ContactService
    @EnvironmentObject private var fcsdkCallService: FCSDKCallService
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        GeometryReader { geometry in
            NavigationView {
                ScrollView {
                    ZStack {
                        
                        if self.contactService.showProgress || self.authenticationService.showProgress {
                            if #available(iOS 14, *) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: colorScheme == .dark ? .white : .black))
                                    .scaleEffect(1.5)
                            } else {
                                Text("Loading.....")
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Group {
                                if UIDevice.current.userInterfaceIdiom == .phone {
                                    Text("Preferred Video Direction")
                                        .fontWeight(.light)
                                        .multilineTextAlignment(.leading)
                                    Picker("", selection: $preferredVideo) {
                                        ForEach(ACBMediaDirection.allCases, id: \.rawValue) { item in
                                            Text(item.rawValue.capitalized)
                                        }
                                    }
                                    .valueChanged(value: preferredVideo) { item in
                                        UserDefaults.standard.setValue(item, forKey: "\(MediaValue.keyVideoDirection.rawValue)")
                                    }
                                    .pickerStyle(SegmentedPickerStyle())
                                    
                                    Text("Preferred Audio Direction")
                                        .fontWeight(.light)
                                        .multilineTextAlignment(.leading)
                                    Picker("", selection: $preferredAudio) {
                                        ForEach(ACBMediaDirection.allCases, id: \.rawValue) { item in
                                            Text(item.rawValue.capitalized)
                                        }
                                    }
                                    .valueChanged(value: self.preferredAudio) { item in
                                        UserDefaults.standard.setValue(item, forKey: "\(MediaValue.keyAudioDirection.rawValue)")
                                    }
                                    .pickerStyle(SegmentedPickerStyle())
                                    
                                    Text("Audio Options")
                                        .fontWeight(.light)
                                        .multilineTextAlignment(.leading)
                                    Picker("", selection: $selectedAudio) {
                                        ForEach(ACBAudioDevice.allCases, id: \.rawValue) { item in
                                            Text(item.rawValue.capitalized)
                                        }
                                    }
                                    .valueChanged(value: self.selectedAudio) { item in
                                        self.fcsdkCallService.selectAudio(audio: ACBAudioDevice(rawValue: item)!)
                                    }
                                    .pickerStyle(SegmentedPickerStyle())
                                    Divider()
                                        .padding(.top)
                                    Text("Default Audio")
                                        .fontWeight(.light)
                                        .multilineTextAlignment(.leading)
                                    if #available(iOS 15, *) {
                                        Picker("", selection: $selectedDefaultAudio) {
                                            ForEach(ACBAudioDevice.allCases, id: \.rawValue) { item in
                                                Text(item.rawValue.capitalized)
                                            }
                                        }
                                        .onAppear {
                                            self.fcsdkCallService.selectDefaultAudio(audio: ACBAudioDevice(rawValue: self.selectedDefaultAudio)!)
                                        }
                                        .valueChanged(value: self.selectedDefaultAudio) { item in
                                            self.fcsdkCallService.selectDefaultAudio(audio: ACBAudioDevice(rawValue: item)!)
                                        }
                                        .pickerStyle(SegmentedPickerStyle())
                                    } else {
                                        Picker("", selection: $selectedDefaultAudio) {
                                            ForEach(ACBAudioDevice.allCases, id: \.rawValue) { item in
                                                Text(item.rawValue.capitalized)
                                            }
                                        }
                                        .pickerStyle(SegmentedPickerStyle())
                                        .onAppear {
                                            self.fcsdkCallService.selectDefaultAudio(audio: ACBAudioDevice(rawValue: self.selectedDefaultAudio)!)
                                        }
                                        .valueChanged(value: self.selectedDefaultAudio) { item in
                                            self.fcsdkCallService.selectDefaultAudio(audio: ACBAudioDevice(rawValue: item)!)
                                        }
                                    }
                                    VStack {
                                        Text("Local Scale Options")
                                            .fontWeight(.light)
                                            .multilineTextAlignment(.leading)
                                        Picker("", selection: $localScaleOption) {
                                            ForEach(ScaleOptions.allCases, id: \.rawValue) { item in
                                                Text(item.rawValue)
                                            }
                                        }
                                        .valueChanged(value: self.localScaleOption) { item in
                                            UserDefaults.standard.setValue(item, forKey: "LocalScale")
                                        }
                                        .pickerStyle(SegmentedPickerStyle())
                                        Divider()
                                        
                                        Text("Remote Scale Options")
                                            .fontWeight(.light)
                                            .multilineTextAlignment(.leading)
                                        Picker("", selection: $remoteScaleOption) {
                                            ForEach(ScaleOptions.allCases, id: \.rawValue) { item in
                                                Text(item.rawValue)
                                            }
                                        }
                                        .valueChanged(value: self.remoteScaleOption) { item in
                                            UserDefaults.standard.setValue(item, forKey: "RemoteScale")
                                        }
                                        .pickerStyle(SegmentedPickerStyle())
                                        Divider()
                                        
                                        HStack {
                                            Spacer()
                                            Toggle(
                                                self.scaleWithOrientation ? "Scaling with orientation" : "Not scaling with orieintation",
                                                isOn: $scaleWithOrientation
                                            )
                                            .valueChanged(value: scaleWithOrientation) { newValue in
                                                UserDefaults.standard.setValue(newValue, forKey: "ScaleWithOrientation")
                                            }
                                            .padding()
                                        }
                                    }
                                    Text("Resolution Options")
                                        .fontWeight(.light)
                                        .multilineTextAlignment(.leading)
                                    Picker("", selection: $selectedResolution) {
                                        ForEach(ResolutionOptions.allCases, id: \.rawValue) { item in
                                            Text(item.rawValue)
                                        }
                                    }
                                    .valueChanged(value: self.selectedResolution) { item in
                                        self.fcsdkCallService.selectResolution(res: ResolutionOptions(rawValue: item)!)
                                    }
                                    .pickerStyle(SegmentedPickerStyle())
                                    Divider()
                                        .padding(.top)
                                    
                                    Text("Frame Rate Options")
                                        .fontWeight(.light)
                                        .multilineTextAlignment(.leading)
                                    Picker("", selection: $selectedFrameRate) {
                                        ForEach(FrameRateOptions.allCases, id: \.rawValue) { item in
                                            Text(item.rawValue)
                                        }
                                    }
                                    .valueChanged(value: self.selectedFrameRate) { item in
                                        self.fcsdkCallService.selectFramerate(rate: FrameRateOptions(rawValue: item)!)
                                    }
                                    .pickerStyle(SegmentedPickerStyle())
                                }
                                if fcsdkCallService.isBuffer {
                                    HStack {
                                        Spacer()
                                        Button("Choose Background", action: {
                                            self.authenticationService.showSettingsSheet = false
                                            tappedShowBackground = true
                                            presentationMode.wrappedValue.dismiss()
                                        }).padding()
                                    }
                                }
                                VStack {
                                    if #available(iOS 15.0, *) {
                                        HStack {
                                            Spacer()
                                            Toggle(
                                                fcsdkCallService.isBuffer ? "Using Native Buffer Views/Layers" : "Using Provided Views",
                                                isOn: $fcsdkCallService.isBuffer
                                            ).onChange(of: fcsdkCallService.isBuffer, perform: { newValue in
                                                switchedViewType = true
                                            })
                                            .padding()
                                        }
                                    }
                                    Spacer()
                                    Toggle(
                                        fcsdkCallService.swapViews ? "Swapped views is used" : "Standard Views",
                                        isOn: $fcsdkCallService.swapViews
                                    )
                                    .valueChanged(value: fcsdkCallService.swapViews) { newValue in
                                        switchedViewType = true
                                    }
                                    .padding()
                                }
                                if switchedViewType {
                                    if #available(iOS 15.0, *) {
                                        Text("Sorry you can't change the Views during the call, but we will change it automatically on the next call")
                                            .onAppear {
                                                Task {
                                                    await removeViewTypeMessage()
                                                }
                                            }
                                        
                                            .animation(.easeInOut(duration: 20), value: 1)
                                            .transition(.slide)
                                            .foregroundColor(.red)
                                            .font(Font.system(size: 12))
                                    } else {
                                        Text("Sorry you can't change the Views during the call, but we will change it automatically on the next call")
                                            .onAppear {
                                                Task {
                                                    await removeViewTypeMessage()
                                                }
                                            }
                                        
                                            .animation(.easeInOut(duration: 20), value: 1)
                                            .transition(.slide)
                                            .foregroundColor(.red)
                                            .font(Font.system(size: 12))
                                    }
                                }
                                HStack {
                                    Spacer()
                                    Toggle(
                                        fcsdkCallService.isMirroredFrontCamera ? "Mirroring Front Camera" : "Not Mirroring Front Camera",
                                        isOn: $fcsdkCallService.isMirroredFrontCamera
                                    )
                                    .valueChanged(value: fcsdkCallService.isMirroredFrontCamera) { newValue in
                                        fcsdkCallService.isMirroredFrontCamera = fcsdkCallService.isMirroredFrontCamera ? false : true
                                        switchedMirroredViewType = true
                                    }
                                    .padding()
                                    if switchedMirroredViewType {
                                        if #available(iOS 15.0, *) {
                                            Text("Sorry you can't mirror the View during the call, but we will change it automatically on the next call")
                                                .task {
                                                    await removeMirroredViewTypeMessage()
                                                }
                                                .animation(.easeInOut(duration: 20), value: 1)
                                                .transition(.slide)
                                                .foregroundColor(.red)
                                                .font(Font.system(size: 12))
                                        } else {
                                            Text("Sorry you can't mirror the View during the call, but we will change it automatically on the next call")
                                                .onAppear {
                                                    Task {
                                                        await removeMirroredViewTypeMessage()
                                                    }
                                                }
                                                .animation(.easeInOut(duration: 20), value: 1)
                                                .transition(.slide)
                                                .foregroundColor(.red)
                                                .font(Font.system(size: 12))
                                        }
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
                                        Text("User: \(UserDefaults.standard.string(forKey: "Username") ?? "")")
                                            .bold()
                                        Text("App Version: \(UIApplication.appVersion!)")
                                            .fontWeight(.light)
                                        Text("FCSDK Version: \(FCSDKiOS.Constants.SDK_VERSION_NUMBER)")
                                            .fontWeight(.light)
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
                                                    .font(.title)
                                                    .bold()
                                            }
                                        }
                                    }
                                    Spacer()
                                }
                            }
                        }
                    }
                    .padding()
                    .onAppear {
                        Task {
                            await removeViewTypeMessage()
                        }
                        self.fcsdkCallService.selectResolution(res: ResolutionOptions(rawValue: self.selectedResolution)!)
                        self.fcsdkCallService.selectFramerate(rate: FrameRateOptions(rawValue: self.selectedFrameRate)!)
                        self.fcsdkCallService.selectAudio(audio: ACBAudioDevice(rawValue: self.selectedAudio)!)
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
            .alert(isPresented: self.$contactService.showError, content: {
                Alert(
                    title: Text("There was an error deleting Call History"),
                    message: Text(""),
                    dismissButton: .cancel(Text("Okay"), action: {
                    })
                )
            })
        }
    }
    
    private func removeViewTypeMessage() async {
        try? await Task.sleep(nanoseconds: 5_500_000_000)
        switchedViewType = false
    }
    
    private func removeMirroredViewTypeMessage()  async {
        try? await Task.sleep(nanoseconds: 5_500_000_000)
        switchedMirroredViewType = false
    }
    func logout() async {
        await authenticationService.logout()
    }
}
