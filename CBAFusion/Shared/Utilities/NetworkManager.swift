//
//  NetworkManager.swift
//  CBAFusion
//
//  Created by Cole M on 8/31/21.
//

import Foundation
import Combine
import UIKit
import OSLog

final class NetworkManager: NSObject, URLSessionDelegate, URLSessionTaskDelegate, @unchecked Sendable {
    
    
    enum NetworkErrors: Swift.Error, Sendable {
        case requestFailed(String)
        case responseUnsuccessful(String)
        case jsonConversionFailure(String)
    }
    
    
    override init() {
        super.init()
    }
    
    deinit {
         print("Reclaiming memory in NetworkManager")
    }
    
    func asyncCodableNetworkWrapper<T: Codable>(
        type: T.Type,
        urlString: String,
        httpMethod: String,
        httpBody: Data? = nil,
        headerField: String? = "",
        headerValue: String? = ""
    ) async throws -> (Data, URLResponse) {
        
        //Strip port for ATS when pointing at the reverse proxy
        if urlString.contains(":8443") {
            var urlString = urlString
            let stripped = urlString.components(separatedBy: ":8443")
            urlString = stripped[0] + stripped[1]
        }
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
        var setData: Data?
        var setResponse: URLResponse?
        if #available(iOS 15.0, *) {
            let (data, response) = try await session.data(for: request, delegate: self)
            setData = data
            setResponse = response
        } else {
            // Fallback on earlier versions
            let responseObject: ResponseObject = try await withCheckedThrowingContinuation { continuation in
                session.dataTask(with: request) { data, response, error in
                    if data != nil && response != nil {
                        guard let data = data else { return }
                        guard let response = response as? HTTPURLResponse else {
                            return
                        }
                        guard response.statusCode == 200 else {
                            return
                        }
                        let responseObject = ResponseObject(data: data, response: response)
                        continuation.resume(returning: responseObject)
                    } else {
                        continuation.resume(throwing: error!)
                    }
                }.resume()
                
            }
            setResponse = responseObject.response
            setData = responseObject.data
        }
        session.finishTasksAndInvalidate()
        guard let setData = setData else { throw NetworkErrors.requestFailed("invalid data") }
        guard let setResponse = setResponse else { throw NetworkErrors.requestFailed("invalid response") }
        
        //If we have some json issue self.logger.info out the string to see the problem
#if DEBUG
        setData.printJSON()
#endif
        return (setData, setResponse)
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
        var setResponse: URLResponse?
        if #available(iOS 15.0, *) {
            let (_, response) = try await session.data(for: request, delegate: self)
            setResponse = response
        } else {
            // Fallback on earlier versions
            let responseObject: ResponseObject = try await withCheckedThrowingContinuation { continuation in
                session.dataTask(with: request) { data, response, error in
                    if data != nil && response != nil {
                        guard let data = data else { return }
                        guard let response = response as? HTTPURLResponse else {
                            return
                        }
                        guard response.statusCode == 200 else {
                            return
                        }
                        let responseObject = ResponseObject(data: data, response: response)
                        continuation.resume(returning: responseObject)
                    } else {
                        continuation.resume(throwing: error!)
                    }
                }.resume()
                
            }
            setResponse = responseObject.response
        }
        session.finishTasksAndInvalidate()
        
        guard let httpResponse = setResponse as? HTTPURLResponse else {
            throw NetworkErrors.requestFailed("invalid response")
        }
        guard httpResponse.statusCode == 200 else {
            throw NetworkErrors.responseUnsuccessful("status code \(httpResponse.statusCode)")
        }
#if DEBUG
        print("Response_______ \(httpResponse)")
#endif
        return httpResponse
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
            print("\(JSONString)")
        }
    }
}

public struct ResponseObject: Sendable {
    public let data: Data
    public let response: HTTPURLResponse
}
