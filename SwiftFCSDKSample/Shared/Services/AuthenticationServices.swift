//
//  AuthenticationServices.swift
//  SwiftFCSDKSample
//
//  Created by Cole M on 8/31/21.
//

import Foundation
import Combine
import ACBClientSDK

class AuthenticationService: NSObject, ObservableObject {
    
    static let shared = AuthenticationService()
    
    override init(){}
    
    @Published var username = UserDefaults.standard.string(forKey: "Username") ?? ""
    @Published var password = KeychainItem.getPassword
    @Published var server = UserDefaults.standard.string(forKey: "Server") ?? ""
    @Published var port = UserDefaults.standard.string(forKey: "Port") ?? ""
    @Published var secureSwitch = UserDefaults.standard.bool(forKey: "Secure")
    @Published var useCookies = UserDefaults.standard.bool(forKey: "Cookies")
    @Published var acceptUntrustedCertificates = UserDefaults.standard.bool(forKey: "Trust")
    var subscriptions = Set<AnyCancellable>()
    var acbuc: ACBUC?
    
    func loginUser(networkStatus: Bool) {
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
        
        NetworkRepository.shared.login(loginReq: loginCredentials)
            .sink { completion in
                switch completion {
                case let .failure(error):
                    print("Couldn't Login user: \(error)")
                case .finished: break
                }
            } receiveValue: { [weak self] payload in
                guard let _ = self else { return }
                print(payload, "Payload")
                AuthenticationService.createSession(sessionid: payload.sessionid, networkStatus: networkStatus)
            }
            .store(in: &subscriptions)
    }

    class func createSession(sessionid: String, networkStatus: Bool) {
        AuthenticationService.shared.acbuc = ACBUC.uc(withConfiguration: sessionid, delegate: AuthenticationService.shared.self)
        AuthenticationService.shared.acbuc?.setNetworkReachable(networkStatus)
        let acceptUntrustedCertificates = UserDefaults.standard.bool(forKey: "Secure")
        AuthenticationService.shared.acbuc?.acceptAnyCertificate(acceptUntrustedCertificates)
        let useCookies = UserDefaults.standard.bool(forKey: "Cookies")
        AuthenticationService.shared.acbuc?.useCookies = useCookies
        AuthenticationService.shared.acbuc?.startSession()
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
