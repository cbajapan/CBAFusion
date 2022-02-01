//
//  NetworkManager.swift
//  CBAFusion
//
//  Created by Cole M on 8/31/21.
//

import Foundation
import Combine
import UIKit
import Logging


class NetworkManager: NSObject, URLSessionDelegate, URLSessionTaskDelegate {
    
    
    enum NetworkErrors: Swift.Error {
        case requestFailed(String)
        case responseUnsuccessful(String)
        case jsonConversionFailure(String)
    }
    
    var logger: Logger
    
    override init() {
        self.logger = Logger(label: "\(Constants.BUNDLE_IDENTIFIER) - Network Manager - ")
        super.init()
    }
    
    deinit {
        self.logger.info("Reclaiming memory in NetworkManager")
    }
    func asyncCodableNetworkWrapper<T: Codable>(
        type: T.Type,
        urlString: String,
        httpMethod: String,
        httpBody: Data? = nil,
        headerField: String? = "",
        headerValue: String? = ""
    ) async throws -> (Data, URLResponse) {
        
        guard let url = URL(string: urlString) else { throw OurErrors.nilURL }
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        
        if httpMethod == "POST" || httpMethod == "PUT" {
            request.httpBody = httpBody
        }
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let allCookies = HTTPCookieStorage.shared.cookies
        for cookie in allCookies ?? [] {
            HTTPCookieStorage.shared.deleteCookie(cookie)
        }
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        let (data, response) = try await session.data(for: request, delegate: self)
        session.finishTasksAndInvalidate()
        
        //If we have some json issue self.logger.info out the string to see the problem
#if DEBUG
        data.printJSON()
#endif
        return (data, response)
    }
    
    func asyncNetworkWrapper(
        urlString: String,
        httpMethod: String,
        httpBody: Data? = nil,
        headerField: String? = "",
        headerValue: String? = ""
    ) async throws -> URLResponse {
        
        guard let url = URL(string: urlString) else { throw OurErrors.nilURL }
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        
        if httpMethod == "POST" || httpMethod == "PUT" {
            request.httpBody = httpBody
        }
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let allCookies = HTTPCookieStorage.shared.cookies
        for cookie in allCookies ?? [] {
            HTTPCookieStorage.shared.deleteCookie(cookie)
        }
        
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        let (_, response) = try await session.data(for: request, delegate: self)
        session.finishTasksAndInvalidate()
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkErrors.requestFailed("unvalid response")
        }
        guard httpResponse.statusCode == 200 else {
            throw NetworkErrors.responseUnsuccessful("status code \(httpResponse.statusCode)")
        }
#if DEBUG
        self.logger.info("Response_______ \(response)")
#endif
        return response
    }
    
    
    func urlSession(
        _
        session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?
        ) -> Void) {
        
        if challenge.protectionSpace.serverTrust == nil {
            completionHandler(.useCredential, nil)
        } else {
            let trust: SecTrust = challenge.protectionSpace.serverTrust!
            let credential = URLCredential(trust: trust)
            completionHandler(.useCredential, credential)
        }
    }
}
extension Data {
    func printJSON() {
        if let JSONString = String(data: self, encoding: String.Encoding.utf8) {
            Logger(label: "\(Constants.BUNDLE_IDENTIFIER) - DATA Extension - ").info("\(JSONString)")
        }
    }
}
