//
//  CallSheet.swift
//  SwiftFCSDKSample
//
//  Created by Cole M on 9/8/21.
//

import SwiftUI

struct CallSheet: View {
    
//    @Binding var showSheet: Bool = false
    @Binding var destination: String
    @Binding var hasVideo: Bool
    @Binding var isOutgoing: Bool
    @Binding var showCommunication: Bool
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject var authenticationService: AuthenticationService
    @EnvironmentObject var callKitManager: CallKitManager
    @EnvironmentObject var fcsdkCallService: FCSDKCallService
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack {
                    HStack(alignment: .bottom) {
                        Text("End Point:")
                        TextField("Destination...", text: self.$destination)
                    }
                    Toggle("Want Video?", isOn: self.$hasVideo)
                }
                .padding()
            }
        }
//        .fullScreenCover(isPresented: self.$showSheet, content: {
//            Communication(destination: self.$destination, hasVideo: self.$hasVideo, isOutgoing: self.$isOutgoing)
//                .environmentObject(self.authenticationService)
//                .environmentObject(self.fcsdkCallService)
//                .environmentObject(self.callKitManager)
//        })
        .navigationBarBackButtonHidden(true)
        .navigationBarTitle("Let's Talk")
        .navigationBarItems(leading:
                                Button(action: {
            self.presentationMode.wrappedValue.dismiss()
        }, label: {
            Text("Cancel")
                .foregroundColor(Color.red)
        }
                                      ), trailing:
                                Button(action: {
//            self.showSheet = true
            self.isOutgoing = true
            self.showCommunication = true
            self.presentationMode.wrappedValue.dismiss()
        }, label: {
            Text("Connect")
                .foregroundColor(Color.blue)
        }))
    }
}
