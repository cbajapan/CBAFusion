//
//  DTMFSheet.swift
//  CBAFusion
//
//  Created by Cole M on 11/4/21.
//

import SwiftUI

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
                    Text(self.storedKey)
                    TextField("Press For DTMF", text: self.$key)
                        .keyboardType(.numberPad)
                        .navigationTitle(title: "DTMF Sheet")
                    Spacer()
                }
            }.padding()
        }
        .onTapGesture {
            hideKeyboard()
        }
        .onDisappear {
            self.fcsdkCallService.showDTMFSheet = false
        }
        .valueChanged(value: key) { newValue in
            if key != "" {
                Task {
                    if self.fcsdkCallService.fcsdkCall?.call != nil {
                        await self.callKitManager.sendDTMF(uuid: self.fcsdkCallService.fcsdkCall!.id, digit: newValue)
                        storedKey += key
                        key = ""
                    }
                }
            }
        }
    }
}

struct DTMFSheet_Previews: PreviewProvider {
    static var previews: some View {
        DTMFSheet()
    }
}
