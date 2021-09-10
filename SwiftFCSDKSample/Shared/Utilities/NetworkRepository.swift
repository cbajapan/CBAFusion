//
//  NetworkRepository.swift
//  SwiftFCSDKSample
//
//  Created by Cole M on 8/31/21.
//

import Foundation
import Combine

class NetworkRepository: NSObject {
    
    static let shared = NetworkRepository()
    private var authenticationService = AuthenticationService()
    
    
    func login(loginReq: LoginViewModel) -> AnyPublisher<LoginResponse, Error> {
        let scheme = loginReq.secureSwitch ? "https" : "http"
        let url = "\(scheme)://\(loginReq.server):\(loginReq.port)/csdk-sample/SDK/login"
        print(url, "URL")
        let body = try? JSONEncoder().encode(loginReq.requestLoginObject())
        return NetworkManager.shared.combineCodableNetworkWrapper(urlString: url, httpMethod: "POST", httpBody: body)
    }
    
    func asyncLogin(loginReq: LoginViewModel) async -> LoginResponse {
        let scheme = loginReq.secureSwitch ? "https" : "http"
        let url = "\(scheme)://\(loginReq.server):\(loginReq.port)/csdk-sample/SDK/login"
        print(url, "URL")
        let body = try? JSONEncoder().encode(loginReq.requestLoginObject())
        let data = try! await NetworkManager.shared.asyncCodableNetworkWrapper(type: LoginResponse.self, urlString: url, httpMethod: "POST", httpBody: body)
        return data
    }
    
    
}
