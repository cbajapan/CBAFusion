//
//  NetworkManager.swift
//  SwiftFCSDKSample
//
//  Created by Cole M on 8/31/21.
//

import Foundation
import Combine

class NetworkManager: NSObject, ObservableObject, URLSessionDelegate {
    
    
    enum NetworkErrors: Swift.Error {
        case requestFailed(String)
        case responseUnsuccessful(String)
        case jsonConversionFailure(String)
    }
    
    
    static let shared = NetworkManager()
    let configuration = URLSessionConfiguration.default
    
    func combineCodableNetworkWrapper<T: Codable>(
        urlString: String,
        httpMethod: String,
        httpBody: Data? = nil,
        headerField: String = "",
        headerValue: String = ""
    ) -> AnyPublisher<T, Error> {
        
        let url = URL(string: urlString)
        var request = URLRequest(url: url!)
        request.httpMethod = httpMethod
        
        if httpMethod == "POST" || httpMethod == "PUT" {
            request.httpBody = httpBody
        }
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let allCookies = HTTPCookieStorage.shared.cookies
        for cookie in allCookies ?? [] {
            HTTPCookieStorage.shared.deleteCookie(cookie)
        }
        
        let session = URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                return data
            }
            .flatMap { data in
                return Just(data)
                    .tryMap{ (data) -> T in
                        return try JSONDecoder().decode(T.self, from: data)
                    }
                    .receive(on: DispatchQueue.main)
            }
            .mapError { error in
                print("Error in Combine Codable Wrapper: \(error)")
                return error
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func asyncCodableNetworkWrapper<T: Codable>(
        type: T.Type,
        urlString: String,
        httpMethod: String,
        httpBody: Data? = nil,
        headerField: String = "",
        headerValue: String = ""
    ) async throws -> T {
        
        let url = URL(string: urlString)
        var request = URLRequest(url: url!)
        request.httpMethod = httpMethod
        
        if httpMethod == "POST" || httpMethod == "PUT" {
            request.httpBody = httpBody
        }
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let allCookies = HTTPCookieStorage.shared.cookies
        for cookie in allCookies ?? [] {
            HTTPCookieStorage.shared.deleteCookie(cookie)
        }
        
        
        let session = URLSession(configuration: self.configuration, delegate: self, delegateQueue: .main)
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkErrors.requestFailed("unvalid response")
        }
        guard httpResponse.statusCode == 200 else {
            throw NetworkErrors.responseUnsuccessful("status code \(httpResponse.statusCode)")
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkErrors.jsonConversionFailure(error.localizedDescription)
        }
    }
    
    func asyncNetworkWrapper(
        urlString: String,
        httpMethod: String,
        httpBody: Data? = nil,
        headerField: String = "",
        headerValue: String = ""
    ) async throws {
        
        let url = URL(string: urlString)
        var request = URLRequest(url: url!)
        request.httpMethod = httpMethod
        
        if httpMethod == "POST" || httpMethod == "PUT" {
            request.httpBody = httpBody
        }
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let allCookies = HTTPCookieStorage.shared.cookies
        for cookie in allCookies ?? [] {
            HTTPCookieStorage.shared.deleteCookie(cookie)
        }
    
        let session = URLSession(configuration: self.configuration, delegate: self, delegateQueue: .main)
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkErrors.requestFailed("unvalid response")
        }
        guard httpResponse.statusCode == 200 else {
            throw NetworkErrors.responseUnsuccessful("status code \(httpResponse.statusCode)")
        }
        print("Response_______", response)
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
