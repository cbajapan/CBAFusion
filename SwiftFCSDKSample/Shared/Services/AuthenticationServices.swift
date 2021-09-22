//
//  AuthenticationServices.swift
//  SwiftFCSDKSample
//
//  Created by Cole M on 8/31/21.
//

import Foundation
import Combine
import SwiftFCSDK
import SwiftUI


class AuthenticationService: NSObject, ObservableObject {
    
    override init(){}
    
    @Published var username = UserDefaults.standard.string(forKey: "Username") ?? ""
    @Published var password = KeychainItem.getPassword
    @Published var server = UserDefaults.standard.string(forKey: "Server") ?? ""
    @Published var port = UserDefaults.standard.string(forKey: "Port") ?? ""
    @Published var secureSwitch = UserDefaults.standard.bool(forKey: "Secure")
    @Published var useCookies = UserDefaults.standard.bool(forKey: "Cookies")
    @Published var acceptUntrustedCertificates = UserDefaults.standard.bool(forKey: "Trust")
    @Published var sessionID = ""
    @Published var connectedToSocket = false
    var subscriptions = Set<AnyCancellable>()
    @Published var acbuc: ACBUC?
    
    
    
    /// Authenticate the User
    @MainActor
    func loginUser(networkStatus: Bool) async {
        let loginCredentials = LoginViewModel(login:
                                                Login(
                                                    username: username,
                                                    password: password,
                                                    server: server,
                                                    port: port,
                                                    secureSwitch: secureSwitch,
                                                    useCookies: useCookies,
                                                    acceptUntrustedCertificates: acceptUntrustedCertificates
                                                ))
        
        
        UserDefaults.standard.set(username, forKey: "Username")
        KeychainItem.savePassword(password: password)
        UserDefaults.standard.set(server, forKey: "Server")
        UserDefaults.standard.set(port, forKey: "Port")
        UserDefaults.standard.set(secureSwitch, forKey: "Secure")
        UserDefaults.standard.set(useCookies, forKey: "Cookies")
        UserDefaults.standard.set(acceptUntrustedCertificates, forKey: "Trust")
        
        let payload = try? await NetworkRepository.shared.asyncLogin(loginReq: loginCredentials)
        self.sessionID = payload?.sessionid ?? ""
        await self.createSession(sessionid: payload?.sessionid ?? "", networkStatus: networkStatus)
        self.connectedToSocket = self.acbuc?.connection != nil
     
        /// Combine Stuff if you would like 
        //        else {
        //            NetworkRepository.shared.login(loginReq: loginCredentials)
        //                .sink { completion in
        //                    switch completion {
        //                    case let .failure(error):
        //                        print("Couldn't Login user: \(error)")
        //                    case .finished: break
        //                    }
        //                } receiveValue: { [weak self] payload in
        //                    guard let strongSelf = self else { return }
        //                    print(payload, "Payload")
        //                    await AuthenticationService.createSession(sessionid: payload.sessionid, networkStatus: networkStatus)
        //                    strongSelf.connectedToSocket = ((AuthenticationService.shared.acbuc?.isConnectedToSocket) != nil)
        //                }
        //                .store(in: &subscriptions)
        //        }
    }
    
    
    /// Create the Session
     func createSession(sessionid: String, networkStatus: Bool) async {
        self.acbuc = ACBUC.uc(withConfiguration: sessionid, delegate: self)
         self.acbuc?.setNetworkReachable(networkStatus)
        let acceptUntrustedCertificates = UserDefaults.standard.bool(forKey: "Secure")
         self.acbuc?.acceptAnyCertificate(acceptUntrustedCertificates)
        let useCookies = UserDefaults.standard.bool(forKey: "Cookies")
         self.acbuc?.useCookies = useCookies
         self.acbuc?.startSession()
    }
    
    
    /// Logout and stop the session
    @MainActor
    func logout() async {
        print("Logging out of server: \(server) with: \(username)")
        let loginCredentials = LoginViewModel(login:
                                                Login(
                                                    username: username,
                                                    password: password,
                                                    server: server,
                                                    port: port,
                                                    secureSwitch: secureSwitch,
                                                    useCookies: useCookies,
                                                    acceptUntrustedCertificates: acceptUntrustedCertificates
                                                ))
        await stopSession()
        await NetworkRepository.shared.asyncLogout(logoutReq: loginCredentials, sessionid: self.sessionID)
        
        //for now just mark false for user experience
//        = AuthenticationService.shared.acbuc?.connection != nil
        self.connectedToSocket = self.acbuc?.connection != nil
    }
    
    /// Stop the Session
    func stopSession() async {
        self.acbuc?.stopSession()
    }
}


extension AuthenticationService: ACBUCDelegate {
    
    func ucDidStartSession(_ uc: ACBUC?) {
        print("Started Session \(String(describing: uc))")
    }
    
    func ucDidFail(toStartSession uc: ACBUC?) {
        print("Failed to start Session \(String(describing: uc))")
    }
    
    func ucDidReceiveSystemFailure(_ uc: ACBUC?) {
        print("Received system failure \(String(describing: uc))")
    }
    
    func ucDidLoseConnection(_ uc: ACBUC?) {
        print("Did lose connection \(String(describing: uc))")
    }
    
}
