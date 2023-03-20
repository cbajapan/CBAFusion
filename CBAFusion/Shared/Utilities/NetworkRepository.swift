//
//  NetworkRepository.swift
//  CBAFusion
//
//  Created by Cole M on 8/31/21.
//

import Foundation

protocol NetworkRepositoryDelegate: AnyObject {
    func asyncLogin(loginReq: Login, reqObject: LoginRequest) async throws -> (Data, URLResponse)
    func asyncLogout(logoutReq: Login, sessionid: String) async throws -> URLResponse
}

class NetworkRepository: NetworkRepositoryDelegate {

    let networkManager = NetworkManager()
    weak var networkRepositoryDelegate: NetworkRepositoryDelegate?
    
    @available(iOS 14.0.0, *)
    func asyncLogin(loginReq: Login, reqObject: LoginRequest) async throws -> (Data, URLResponse) {
        let scheme = loginReq.secureSwitch ? "https" : "http"
        let url = "\(scheme)://\(loginReq.server):\(loginReq.port)/csdk-sample/SDK/login"
        let body = try? JSONEncoder().encode(reqObject)
        return try await networkManager.asyncCodableNetworkWrapper(type: LoginResponse.self, urlString: url, httpMethod: "POST", httpBody: body)
    }
    
    @available(iOS 14.0.0, *)
    func asyncLogout(logoutReq: Login, sessionid: String) async throws -> URLResponse {
        let scheme = logoutReq.secureSwitch ? "https" : "http"
        let url = "\(scheme)://\(logoutReq.server):\(logoutReq.port)/csdk-sample/SDK/login/id/\(sessionid)"
        return try await networkManager.asyncNetworkWrapper(urlString: url, httpMethod: "DELETE")
    }
    
    enum Errors: Swift.Error {
        case nilResponseError
    }
}
