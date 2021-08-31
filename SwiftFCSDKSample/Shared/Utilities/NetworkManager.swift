//
//  NetworkManager.swift
//  SwiftFCSDKSample
//
//  Created by Cole M on 8/31/21.
//

import Foundation
import Combine

class NetworkManager: NSObject, ObservableObject, URLSessionDelegate {
    
    static let shared = NetworkManager()
    
    func codableNetworkWrapper<T: Codable>(
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
        
        let configuration = URLSessionConfiguration.default
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
