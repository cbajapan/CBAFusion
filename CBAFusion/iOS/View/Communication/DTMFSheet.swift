//
//  DTMFSheet.swift
//  CBAFusion
//
//  Created by Cole M on 11/4/21.
//

import SwiftUI

/// A view representing a DTMF input sheet for sending DTMF tones.
struct DTMFSheet: View {
    
    @State private var key = ""
    @State private var storedKey = ""
    @EnvironmentObject private var fcsdkCallService: FCSDKCallService
    @EnvironmentObject private var callKitManager: CallKitManager
    @Environment(\.presentationMode) private var presentationMode
    
    var body: some View {
        GeometryReader { geometry in
            NavigationView {
                VStack {
                    // Display the stored DTMF keys
                    Text(storedKey)
                        .font(.largeTitle)
                        .padding()
                    
                    // TextField for DTMF input
                    TextField("Press For DTMF", text: $key)
                        .keyboardType(.numberPad)
                        .padding()
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .navigationTitle(title: "DTMF Sheet")
                    
                    Spacer()
                }
                .padding()
            }
        }
        .onTapGesture {
            hideKeyboard() // Hide keyboard on tap
        }
        .onDisappear {
            // Hide the DTMF sheet when it disappears
            self.fcsdkCallService.showDTMFSheet = false
        }
        .valueChanged(value: key) { newValue in
            // Handle DTMF input
            if !key.isEmpty {
                Task {
                    if let call = self.fcsdkCallService.fcsdkCall {
                        await self.callKitManager.sendDTMF(uuid: call.id, digit: newValue)
                        storedKey += key // Append the pressed key to stored keys
                        key = "" // Clear the input field
                    }
                }
            }
        }
    }
}

/// Preview provider for DTMFSheet.
struct DTMFSheet_Previews: PreviewProvider {
    static var previews: some View {
        DTMFSheet()
            .environmentObject(FCSDKCallService()) // Provide a mock environment object
            .environmentObject(CallKitManager()) // Provide a mock environment object
    }
}
