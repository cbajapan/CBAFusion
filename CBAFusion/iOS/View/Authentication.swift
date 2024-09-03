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
                                .disableAutocorrection(true)
                                .autocapitalization(.none)
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
                            Toggle("Force retry socket connection", isOn: $authenticationService.alwaysRetryConnection)
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
                    if #available(iOS 14, *) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                    } else {
                        Text("Loading.....")
                    }
                }
            }
            .navigationBarTitle("Authentication")
        }
        .onDisappear(perform: {
            self.loggingIn = false
        })
        .alert(isPresented: self.$authenticationService.showErrorAlert, content: {
            Alert(
                title: Text("\(self.authenticationService.errorMessage)"),
                message: Text(""),
                dismissButton: .cancel(Text("Okay"), action: {
                    self.authenticationService.showErrorAlert = false
                    self.loggingIn = false
                })
            )
        })
    }
    
    private func login() async {
        await self.authenticationService.loginUser(networkStatus: monitor.networkStatus())
        await self.fcsdkCallService.setPhoneDelegate()
    }
}
