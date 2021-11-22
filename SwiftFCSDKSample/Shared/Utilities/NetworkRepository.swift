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
    
    func login(loginReq: LoginViewModel) -> AnyPublisher<LoginResponse, Error> {
        let scheme = loginReq.secureSwitch ? "https" : "http"
        let url = "\(scheme)://\(loginReq.server):\(loginReq.port)/csdk-sample/SDK/login"
        print(url, "URL")
        let body = try? JSONEncoder().encode(loginReq.requestLoginObject())
        return NetworkManager.shared.combineCodableNetworkWrapper(urlString: url, httpMethod: "POST", httpBody: body)
    }
    
    func asyncLogin(loginReq: LoginViewModel) async throws -> (Data, URLResponse) {
        let scheme = loginReq.secureSwitch ? "https" : "http"
        let url = "\(scheme)://\(loginReq.server):\(loginReq.port)/csdk-sample/SDK/login"
        let body = try? JSONEncoder().encode(loginReq.requestLoginObject())
        return try await NetworkManager.shared.asyncCodableNetworkWrapper(type: LoginResponse.self, urlString: url, httpMethod: "POST", httpBody: body)
    }
    
    func asyncLogout(logoutReq: LoginViewModel, sessionid: String) async {
        let scheme = logoutReq.secureSwitch ? "https" : "http"
        let url = "\(scheme)://\(logoutReq.server):\(logoutReq.port)/csdk-sample/SDK/login/id/\(sessionid)"
        do {
            try await NetworkManager.shared.asyncNetworkWrapper(urlString: url, httpMethod: "DELETE")
        } catch {
            print(error)
        }
    }
    
    enum Errors: Swift.Error {
        case nilResponseError
    }
}
