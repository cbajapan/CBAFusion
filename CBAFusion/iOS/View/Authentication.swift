//
//  Authentication.swift
//  CBAFusion
//
//  Created by Cole M on 8/31/21.
//

import SwiftUI
import FCSDKiOS

/// A view for user authentication, allowing users to log in with their credentials.
struct Authentication: View {
    
    // State variables for managing the login process
    @State private var loggingIn = false
    
    // Environment objects for managing authentication and network state
    @EnvironmentObject private var authenticationService: AuthenticationService
    @EnvironmentObject private var fcsdkCallService: FCSDKCallService
    @EnvironmentObject private var pathState: NWPathState
    
    var body: some View {
        NavigationView {
            ZStack {
                Form {
                    credentialsSection
                    settingsSection
                    loginButton
                }
                
                // Show loading indicator while logging in
                if loggingIn {
                    loadingIndicator
                }
            }
            .navigationBarTitle("Authentication")
            .onDisappear(perform: {
                self.loggingIn = false
            })
            .alert(isPresented: self.$authenticationService.showErrorAlert) {
                Alert(
                    title: Text(authenticationService.errorMessage),
                    dismissButton: .cancel(Text("Okay"), action: {
                        self.authenticationService.showErrorAlert = false
                        self.loggingIn = false
                    })
                )
            }
        }
    }
    
    /// Section for entering user credentials.
    private var credentialsSection: some View {
        Section(header: Text("Credentials")) {
            VStack(alignment: .leading) {
                Text("User").bold()
                TextField("Enter Username...", text: $authenticationService.username)
                Divider()
                Text("Password").bold()
                SecureField("Enter Password...", text: $authenticationService.password)
                Text("Server").bold()
                TextField("Enter Server Name...", text: $authenticationService.server)
                    .disableAutocorrection(true)
                    .autocapitalization(.none)
                Text("Port").bold()
                TextField("8443...", text: $authenticationService.port)
                    .keyboardType(.numberPad) // Set keyboard type for port input
            }
        }
    }
    
    /// Section for additional settings related to the connection.
    private var settingsSection: some View {
        Section {
            VStack(alignment: .leading) {
                Toggle("Security", isOn: $authenticationService.secureSwitch)
                Toggle("Use Cookies", isOn: $authenticationService.useCookies)
                Toggle("Trust All Certs.", isOn: $authenticationService.acceptUntrustedCertificates)
                Toggle("Force retry socket connection", isOn: $authenticationService.alwaysRetryConnection)
            }
        }
    }
    
    /// Button for logging in.
    private var loginButton: some View {
        Button {
            self.loggingIn = true
            Task.detached {
                await self.login()
            }
        } label: {
            Text("Login")
        }
        .buttonStyle(.borderless)
    }
    
    /// Loading indicator shown during the login process.
    private var loadingIndicator: some View {
        Group {
            if #available(iOS 14, *) {
                AnyView(
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                )
            } else {
                AnyView(
                    Text("Loading.....")
                )
            }
        }
    }

    /// Asynchronous function to handle user login.
    private func login() async {
            await self.authenticationService.loginUser(networkStatus: true)
            await self.fcsdkCallService.setPhoneDelegate()
    }
}
