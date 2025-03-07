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


import SwiftUI

import SwiftUI

/// A view that represents the settings sheet where users can configure various application settings.
struct SettingsSheet: View {
    
    // MARK: - State and Binding Properties
    
    @State private var switchedViewType: Bool = false
    @State private var switchedMirroredViewType: Bool = false
    @Binding var tappedShowBackground: Bool
    
    @State private var selectedAudio: String = UserDefaults.standard.string(forKey: "AudioOption") ?? ACBAudioDevice.speakerphone.rawValue
    @State private var selectedResolution: String = UserDefaults.standard.string(forKey: "ResolutionOption") ?? ResolutionOptions.auto.rawValue
    @State private var selectedFrameRate: String = UserDefaults.standard.string(forKey: "RateOption") ?? FrameRateOptions.fro20.rawValue
    @State private var selectedDefaultAudio: String = UserDefaults.standard.string(forKey: "DefaultAudio") ?? ACBAudioDevice.speakerphone.rawValue
    @State private var remoteScaleOption: String = UserDefaults.standard.string(forKey: "RemoteScale") ?? ScaleOptions.horizontal.rawValue
    @State private var localScaleOption: String = UserDefaults.standard.string(forKey: "LocalScale") ?? ScaleOptions.horizontal.rawValue
    @State private var scaleWithOrientation: Bool = UserDefaults.standard.bool(forKey: "ScaleWithOrientation")
    @State private var preferredAudio: String = UserDefaults.standard.string(forKey: MediaValue.keyAudioDirection.rawValue) ?? "SendAndReceive"
    @State private var preferredVideo: String = UserDefaults.standard.string(forKey: MediaValue.keyVideoDirection.rawValue) ?? "SendAndReceive"
    
    @EnvironmentObject private var authenticationService: AuthenticationService
    @EnvironmentObject private var contactService: ContactService
    @EnvironmentObject private var fcsdkCallService: FCSDKCallService
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        GeometryReader { geometry in
            NavigationView {
                ScrollView {
                    ZStack {
                        // Show progress indicator
                        if contactService.showProgress || authenticationService.showProgress {
                            if #available(iOS 14, *) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: colorScheme == .dark ? .white : .black))
                                    .scaleEffect(1.5)
                            } else {
                                Text("Loading.....")
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 5) {
                            // Video and Audio Direction
                            directionSettingsSection
                            
                            // Audio Options
                            audioOptionsSection
                            
                            // Scale Options
                            scaleOptionsSection
                            
                            // Resolution and Frame Rate Options
                            resolutionAndFrameRateSection
                            
                            // View Type Toggles
                            viewTypeTogglesSection
                            
                            // Call History and User Info
                            callHistoryAndUserInfoSection
                        }
                    }
                    .padding()
                    .onAppear {
                        Task {
                            await removeViewTypeMessage()
                        }
                        configureInitialSettings()
                    }
                    .onDisappear {
                        Task {
                            try await contactService.fetchContacts()
                        }
                    }
                    .navigationBarTitle("Settings")
                }
            }
            .alert(isPresented: $contactService.showError) {
                Alert(
                    title: Text("There was an error deleting Call History"),
                    dismissButton: .cancel(Text("Okay"))
                )
            }
        }
    }
    
    // MARK: - View Sections
    
    private var directionSettingsSection: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Preferred Video Direction")
                .fontWeight(.light)
            Picker("", selection: $preferredVideo) {
                ForEach(ACBMediaDirection.allCases, id: \.rawValue) { item in
                    Text(item.rawValue.capitalized)
                }
            }
            .valueChanged(value: preferredVideo) { item in
                UserDefaults.standard.setValue(item, forKey: MediaValue.keyVideoDirection.rawValue)
            }
            .pickerStyle(SegmentedPickerStyle())
            
            Text("Preferred Audio Direction")
                .fontWeight(.light)
            Picker("", selection: $preferredAudio) {
                ForEach(ACBMediaDirection.allCases, id: \.rawValue) { item in
                    Text(item.rawValue.capitalized)
                }
            }
            .valueChanged(value: preferredAudio) { item in
                UserDefaults.standard.setValue(item, forKey: MediaValue.keyAudioDirection.rawValue)
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }
    
    private var audioOptionsSection: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Audio Options")
                .fontWeight(.light)
            Picker("", selection: $selectedAudio) {
                ForEach(ACBAudioDevice.allCases, id: \.rawValue) { item in
                    Text(item.rawValue.capitalized)
                }
            }
            .valueChanged(value: selectedAudio) { item in
                fcsdkCallService.selectAudio(audio: ACBAudioDevice(rawValue: item)!)
            }
            .pickerStyle(SegmentedPickerStyle())
            
            Text("Default Audio")
                .fontWeight(.light)
            Picker("", selection: $selectedDefaultAudio) {
                ForEach(ACBAudioDevice.allCases, id: \.rawValue) { item in
                    Text(item.rawValue.capitalized)
                }
            }
            .valueChanged(value: selectedDefaultAudio) { item in
                fcsdkCallService.selectDefaultAudio(audio: ACBAudioDevice(rawValue: item)!)
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }
    
    private var scaleOptionsSection: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Local Scale Options")
                .fontWeight(.light)
            Picker("", selection: $localScaleOption) {
                ForEach(ScaleOptions.allCases, id: \.rawValue) { item in
                    Text(item.rawValue)
                }
            }
            .valueChanged(value: localScaleOption) { item in
                UserDefaults.standard.setValue(item, forKey: "LocalScale")
            }
            .pickerStyle(SegmentedPickerStyle())
            
            Text("Remote Scale Options")
                .fontWeight(.light)
            Picker("", selection: $remoteScaleOption) {
                ForEach(ScaleOptions.allCases, id: \.rawValue) { item in
                    Text(item.rawValue)
                }
            }
            .valueChanged(value: remoteScaleOption) { item in
                UserDefaults.standard.setValue(item, forKey: "RemoteScale")
            }
            .pickerStyle(SegmentedPickerStyle())
            
            HStack {
                Spacer()
                Toggle(
                    scaleWithOrientation ? "Scaling with orientation" : "Not scaling with orientation",
                    isOn: $scaleWithOrientation
                )
                .valueChanged(value: scaleWithOrientation) { newValue in
                    UserDefaults.standard.setValue(newValue, forKey: "ScaleWithOrientation")
                }
                .padding()
            }
        }
    }
    
    private var resolutionAndFrameRateSection: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Resolution Options")
                .fontWeight(.light)
            Picker("", selection: $selectedResolution) {
                ForEach(ResolutionOptions.allCases, id: \.rawValue) { item in
                    Text(item.rawValue)
                }
            }
            .valueChanged(value: selectedResolution) { item in
                fcsdkCallService.selectResolution(res: ResolutionOptions(rawValue: item)!)
            }
            .pickerStyle(SegmentedPickerStyle())
            
            Text("Frame Rate Options")
                .fontWeight(.light)
            Picker("", selection: $selectedFrameRate) {
                ForEach(FrameRateOptions.allCases, id: \.rawValue) { item in
                    Text(item.rawValue)
                }
            }
            .valueChanged(value: selectedFrameRate) { item in
                fcsdkCallService.selectFramerate(rate: FrameRateOptions(rawValue: item)!)
            }
            .pickerStyle(SegmentedPickerStyle())
            
            if fcsdkCallService.isBuffer {
                HStack {
                    Spacer()
                    Button("Choose Background") {
                        authenticationService.showSettingsSheet = false
                        tappedShowBackground = true
                        presentationMode.wrappedValue.dismiss()
                    }
                    .padding()
                }
            }
        }
    }
    
    private var viewTypeTogglesSection: some View {
        VStack(alignment: .leading, spacing: 5) {
            if #available(iOS 15.0, *) {
                HStack {
                    Spacer()
                    Toggle(
                        fcsdkCallService.isBuffer ? "Using Native Buffer Views/Layers" : "Using Provided Views",
                        isOn: $fcsdkCallService.isBuffer
                    )
                    .onChange(of: fcsdkCallService.isBuffer) { _ in
                        switchedViewType = true
                    }
                    .padding()
                }
            }
            Spacer()
            Toggle(
                fcsdkCallService.swapViews ? "Swapped views is used" : "Standard Views",
                isOn: $fcsdkCallService.swapViews
            )
            .valueChanged(value: fcsdkCallService.swapViews) { _ in
                switchedViewType = true
            }
            .padding()
            
            if switchedViewType {
                Text("Sorry you can't change the Views during the call, but we will change it automatically on the next call")
                    .onAppear {
                        Task {
                            await removeViewTypeMessage()
                        }
                    }
                    .animation(.easeInOut(duration: 20), value: 1)
                    .transition(.slide)
                    .foregroundColor(.red)
                    .font(.system(size: 12))
            }
            
            HStack {
                Spacer()
                Toggle(
                    fcsdkCallService.isMirroredFrontCamera ? "Mirroring Front Camera" : "Not Mirroring Front Camera",
                    isOn: $fcsdkCallService.isMirroredFrontCamera
                )
                .valueChanged(value: fcsdkCallService.isMirroredFrontCamera) { _ in
                    switchedMirroredViewType = true
                }
                .padding()
                
                if switchedMirroredViewType {
                    Text("Sorry you can't mirror the View during the call, but we will change it automatically on the next call")
                        .onAppear {
                            Task {
                                await removeMirroredViewTypeMessage()
                            }
                        }
                        .animation(.easeInOut(duration: 20), value: 1)
                        .transition(.slide)
                        .foregroundColor(.red)
                        .font(.system(size: 12))
                }
            }
        }
    }
    
    private var callHistoryAndUserInfoSection: some View {
        VStack(alignment: .leading, spacing: 5) {
//            if fcsdkCallService.fcsdkCall?.activeCall == false ||
//                fcsdkCallService.fcsdkCall?.activeCall == nil
//            {
                Button("Clear Call History") {
                    Task {
                        await fcsdkCallService.contactService?.deleteCalls()
                    }
                }
//            }
            
            Divider()
            
            HStack {
                VStack(alignment: .leading) {
                    Text("User: \(UserDefaults.standard.string(forKey: "Username") ?? "")")
                        .bold()
                    Text("App Version: \(UIApplication.appVersion ?? "")")
                        .fontWeight(.light)
                    Text("FCSDK Version: \(FCSDKiOS.Constants.SDK_VERSION_NUMBER)")
                        .fontWeight(.light)
                }
                Spacer()
                Button {
                    Task.detached {
                        await logout()
                    }
                } label: {
                    HStack {
                        Spacer()
                        Text("Logout")
                            .font(.title)
                            .bold()
                    }
                }
                Spacer()
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func configureInitialSettings() {
        fcsdkCallService.selectResolution(res: ResolutionOptions(rawValue: selectedResolution)!)
        fcsdkCallService.selectFramerate(rate: FrameRateOptions(rawValue: selectedFrameRate)!)
        fcsdkCallService.selectAudio(audio: ACBAudioDevice(rawValue: selectedAudio)!)
    }
    
    private func removeViewTypeMessage() async {
        try? await Task.sleep(nanoseconds: 5_500_000_000)
        switchedViewType = false
    }
    
    private func removeMirroredViewTypeMessage() async {
        try? await Task.sleep(nanoseconds: 5_500_000_000)
        switchedMirroredViewType = false
    }
    
    private func logout() async {
        await authenticationService.logout()
    }
}
