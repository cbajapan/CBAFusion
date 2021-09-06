//
//  SettingsSheet.swift
//  SwiftFCSDKSample
//
//  Created by Cole M on 9/2/21.
//

import SwiftUI

struct SettingsSheet: View {
    
    @State private var selectedAudio = "Ear Piece"
    @State private var selectedResoliution = "auto"
    @State private var selectedFrameRate = "20fps"
    @State private var autoAnswer: Bool = false
    var audioOptions = ["Ear Piece", "Speaker Phone"]
    var resolutionOptions = ["auto", "288p", "480p", "720p"]
    var frameRateOptions = ["20fps", "30fps"]
    
    
    var body: some View {
        GeometryReader { geometry in
        NavigationView {
            VStack(alignment: .leading, spacing: 5) {
                Text("Audio Options")
                    .fontWeight(.light)
                    .multilineTextAlignment(.leading)
                Picker("", selection: $selectedAudio) {
                    ForEach(audioOptions, id: \.self) {
                        Text($0)
                    }
                }
                        .pickerStyle(SegmentedPickerStyle())
                Divider()
                    .padding(.top)
                
                Text("Resoliution Options")
                    .fontWeight(.light)
                    .multilineTextAlignment(.leading)
                Picker("", selection: $selectedResoliution) {
                    ForEach(resolutionOptions, id: \.self) {
                        Text($0)
                    }
                }
                        .pickerStyle(SegmentedPickerStyle())
                Divider()
                    .padding(.top)
                
                Text("Frame Rate Options")
                    .fontWeight(.light)
                    .multilineTextAlignment(.leading)
                Picker("", selection: $selectedFrameRate) {
                    ForEach(frameRateOptions, id: \.self) {
                        Text($0)
                    }
                }
                        .pickerStyle(SegmentedPickerStyle())
                Divider()
                    .padding(.top)
                
                Toggle("Auto-Answer", isOn: $autoAnswer)
            }.padding()
                .navigationBarTitle("Settings")
        }
        .frame(height: geometry.size.height * 0.65)
        }
    }
}

struct SettingsSheet_Previews: PreviewProvider {
    static var previews: some View {
        SettingsSheet()
    }
}
