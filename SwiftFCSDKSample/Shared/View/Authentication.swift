//
//  Authentication.swift
//  SwiftFCSDKSample
//
//  Created by Cole M on 8/31/21.
//

import SwiftUI
import ACBClientSDK

struct Authentication: View {
    
    @State private var username = ""
    @State private var password = ""
    @State private var server = ""
    @State private var port = ""
    @State private var setSecurity = true
    @State private var setCookies = true
    @State private var setTrust = true
    
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var authenticationService: AuthenticationService
    @Binding var currentTabIndex: Int
    @Binding var showSubscriptionsSheet: Bool
    var parentTabIndex: Int
    
    var body: some View {
        NavigationView  {
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
                    print("Login")
                    self.login()
                } label: {
                        Text("Login")
                }
            }
            .navigationBarTitle("Authentication")
        }
        .onAppear {
            self.currentTabIndex = self.parentTabIndex
        }
    }
    
    private func login() {
        self.authenticationService.loginUser()
    }
}

struct Authentication_Previews: PreviewProvider {
    static var previews: some View {
        Authentication(currentTabIndex: .constant(0), showSubscriptionsSheet: .constant(false), parentTabIndex: 0)
    }
}
