//
//  NetworkRepository.swift
//  CBAFusion
//
//  Created by Cole M on 8/31/21.
//

import Foundation
import Combine

class NetworkRepository: NSObject {
    
    static let shared = NetworkRepository()
    
    func asyncLogin(loginReq: Login, reqObject: LoginRequest) async throws -> (Data, URLResponse) {
        let scheme = loginReq.secureSwitch ? "https" : "http"
        let url = "\(scheme)://\(loginReq.server):\(loginReq.port)/csdk-sample/SDK/login"
        let body = try? JSONEncoder().encode(reqObject)
        return try await NetworkManager.shared.asyncCodableNetworkWrapper(type: LoginResponse.self, urlString: url, httpMethod: "POST", httpBody: body)
    }
    
    func asyncLogout(logoutReq: Login, sessionid: String) async throws -> URLResponse {
        let scheme = logoutReq.secureSwitch ? "https" : "http"
        let url = "\(scheme)://\(logoutReq.server):\(logoutReq.port)/csdk-sample/SDK/login/id/\(sessionid)"
           return try await NetworkManager.shared.asyncNetworkWrapper(urlString: url, httpMethod: "DELETE")
    }
    
    enum Errors: Swift.Error {
        case nilResponseError
    }
}
