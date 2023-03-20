//
//  CallSheet.swift
//  CBAFusion
//
//  Created by Cole M on 9/8/21.
//

import SwiftUI
import FCSDKiOS

struct CallSheet: View {
    
    @Binding var destination: String
    @Binding var hasVideo: Bool
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
                }
                .padding()
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitle("Let's Talk")
        .navigationBarItems(leading:
                                Button(action: {
            if UIDevice.current.userInterfaceIdiom == .phone {
                self.presentationMode.wrappedValue.dismiss()
            }
        }, label: {
            if UIDevice.current.userInterfaceIdiom == .phone {
                Text("Cancel")
                    .foregroundColor(Color.red)
            }
        }), trailing:
                                HStack {
//            Button {
//                setupCall(hasVideo: false)
//            } label: {
//                Image(systemName: "phone")
//                    .foregroundColor(.blue)
//            }
            Button {
                setupCall(hasVideo: true)
            } label: {
                Image(systemName: "video")
                    .foregroundColor(.blue)
            }
        }
        )
        .alert(isPresented: self.$notLoggedIn, content: {
            Alert(
                title: Text("We are sorry you don't seem to be logged in"),
                message: Text(""),
                dismissButton: .cancel(Text("Okay"), action: {
                    Task {
                        await processNotLoggedIn()
                    }
                })
            )
        })
//        .alert("We are sorry you don't seem to be logged in", isPresented: self.$notLoggedIn, actions: {
//            Button("OK", role: .cancel) {
//                processNotLoggedIn()
//            }
//        })
    }
    
    func setupCall(hasVideo: Bool) {
//        if authenticationService.acbuc != nil {
            self.fcsdkCallService.isOutgoing = true
            self.fcsdkCallService.hasVideo = hasVideo
            self.showCommunication = true
            self.presentationMode.wrappedValue.dismiss()
//        } else {
//            
//        }
    }
    
    func processNotLoggedIn() async {
            await self.authenticationService.logout()
            KeychainItem.deleteSessionID()
            self.authenticationService.sessionID = KeychainItem.getSessionID
    }
    
}
