//
//  LoginViewModel.swift
//  SwiftFCSDKSample
//
//  Created by Cole M on 8/31/21.
//

import Foundation

class LoginViewModel {

    var login: Login
    
    init(login: Login) {
        self.login = login
    }
    var username: String {
        return self.login.username
    }
    
    var password: String {
        return self.login.password
    }
    
    var server: String {
        return self.login.server
    }
    
    var port: String {
        return self.login.port
    }
    
    var secureSwitch: Bool {
        return self.login.secureSwitch
    }
    
    var useCookies: Bool {
        return self.login.useCookies
    }
    
    var acceptUntrustedCertificates: Bool {
        return self.login.acceptUntrustedCertificates
    }
    
    func requestLoginObject() -> LoginRequest {
        return LoginRequest(username: self.username, password: self.password)
    }
}
