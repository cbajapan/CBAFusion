//
//  DTMFSheet.swift
//  SwiftFCSDKSample
//
//  Created by Cole M on 11/4/21.
//

import SwiftUI

struct DTMFSheet: View {
    
    @State private var string = ""
    @EnvironmentObject private var fcsdkCallService: FCSDKCallService
    @Environment(\.presentationMode) private var presentationMode
    
    var body: some View {
        GeometryReader { geometry in
            NavigationView {
                DialPad(string: self.$string, legacyDTMF: .constant(false))
                    .padding()
                    .frame(width: geometry.size.width * 0.8, height: geometry.size.height * 0.6)
                    .navigationTitle("DTMF Sheet")
            }
        }
        .onDisappear {
            self.fcsdkCallService.showDTMFSheet = false
        }
    }
}

struct DTMFSheet_Previews: PreviewProvider {
    static var previews: some View {
        DTMFSheet()
    }
}
