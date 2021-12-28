//
//  CallSheet.swift
//  CBAFusion
//
//  Created by Cole M on 9/8/21.
//

import SwiftUI

struct CallSheet: View {
    
    @Binding var destination: String
    @Binding var hasVideo: Bool
    @Binding var isOutgoing: Bool
    @Binding var showCommunication: Bool
    @State var notLoggedIn: Bool = false
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
//                    Toggle("Want Video?", isOn: self.$hasVideo)
                }
                .padding()
            }
        }
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
            if authenticationService.acbuc != nil {
                self.isOutgoing = true
                self.showCommunication = true
                self.presentationMode.wrappedValue.dismiss()
            } else {
                
            }
        }, label: {
            Text("Connect")
                .foregroundColor(Color.blue)
        }))
        .alert("We are sorry you don't seem to be logged in", isPresented: self.$notLoggedIn, actions: {
            Button("OK", role: .cancel) {
                processNotLoggedIn()
            }
        })
    }
    func processNotLoggedIn() {
        Task {
            await self.authenticationService.logout()
            KeychainItem.deleteSessionID()
            self.authenticationService.sessionID = KeychainItem.getSessionID
        }
    }
    
}