//
//  Authentication.swift
//  CBAFusion
//
//  Created by Cole M on 8/31/21.
//

import SwiftUI
import FCSDKiOS

struct Authentication: View {
    
    @State private var username = ""
    @State private var password = ""
    @State private var server = ""
    @State private var port = ""
    @State private var setSecurity = true
    @State private var setCookies = true
    @State private var setTrust = true
    @State private var loggingIn = false
    @EnvironmentObject var monitor: NetworkMonitor
    @EnvironmentObject private var authenticationService: AuthenticationService
    @EnvironmentObject private var fcsdkCallService: FCSDKCallService
    
    var body: some View {
        NavigationView  {
            ZStack {
                Form {
                    Section(header: Text("Credentials")) {
                        VStack(alignment: .leading) {
                            Text("User")
                                .bold()
                            TextField("Enter Username...", text: $authenticationService.username)
                            Divider()
                            Text("Password")
                                .bold()
                            SecureField("Enter Password...", text: $authenticationService.password)
                            Text("Server")
                                .bold()
                            TextField("Enter Server Name...", text: $authenticationService.server)
                            Text("Port")
                                .bold()
                            TextField("8443...", text: $authenticationService.port)
                        }
                    }
                    Section {
                        VStack(alignment: .leading) {
                            Toggle("Security", isOn: $authenticationService.secureSwitch)
                            Toggle("Use Cookies", isOn: $authenticationService.useCookies)
                            Toggle("Trust All Certs.", isOn: $authenticationService.acceptUntrustedCertificates)
                        }
                    }
                    Button {
                        self.loggingIn = true
                        Task {
                            await self.login()
                        }
                    } label: {
                        Text("Login")
                    }
                    .buttonStyle(.borderless)
                }
                
                if self.loggingIn {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                }
            }
            .navigationBarTitle("Authentication")
        }
        .onDisappear(perform: {
            self.loggingIn = false
        })
        .alert(self.authenticationService.errorMessage, isPresented: self.$authenticationService.showErrorAlert, actions: {
            Button("OK", role: .cancel) {
                self.authenticationService.showErrorAlert = false
                self.loggingIn = false
            }
        })
    }
    
    private func login() async {
        await self.authenticationService.loginUser(networkStatus: monitor.networkStatus())
        self.fcsdkCallService.acbuc = self.authenticationService.acbuc
         self.fcsdkCallService.setPhoneDelegate()
    }
}
