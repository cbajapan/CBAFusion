//
//  AuthenticationServices.swift
//  CBAFusion
//
//  Created by Cole M on 8/31/21.
//

import Foundation
import SwiftUI
import FCSDKiOS
import Logging


protocol AuthenticationProtocol: AnyObject {
    var acbuc: ACBUC? { get set }
    func loginUser(networkStatus: Bool) async
}

class AuthenticationService: NSObject, ObservableObject, AuthenticationProtocol {
    
    var logger: Logger
    var networkRepository: NetworkRepository
    
    override init() {
        self.networkRepository = NetworkRepository()
        self.networkRepository.networkRepositoryDelegate = networkRepository
        self.logger = Logger(label: "\(Constants.BUNDLE_IDENTIFIER) - Authentication Service - ")
    }
    
    deinit {
    }
    
    func requestLoginObject() -> LoginRequest {
        return LoginRequest(username: self.username, password: self.password)
    }
    
    @Published var username = UserDefaults.standard.string(forKey: "Username") ?? ""
    @Published var password = KeychainItem.getPassword
    @Published var server = UserDefaults.standard.string(forKey: "Server") ?? ""
    @Published var port = UserDefaults.standard.string(forKey: "Port") ?? ""
    @Published var secureSwitch = UserDefaults.standard.bool(forKey: "Secure")
    @Published var useCookies = UserDefaults.standard.bool(forKey: "Cookies")
    @Published var acceptUntrustedCertificates = UserDefaults.standard.bool(forKey: "Trust")
    @Published var sessionID = KeychainItem.getSessionID
    @Published var connectedToSocket = false
//   @FCSDKTransportActor
    var connection = false {
        didSet {
            Task { @MainActor [weak self] in
                self?.connectedToSocket = connection
            }
        }
    }
    @Published var sessionExists = false
    @Published var acbuc: ACBUC?
//   @FCSDKTransportActor
    var uc: ACBUC? {
        didSet {
            Task { @MainActor [weak self] in
                self?.acbuc = uc
            }
        }
    }
    @Published var showErrorAlert: Bool = false
    @Published var errorMessage: String = ""
    @Published var showSettingsSheet = false
    @Published var selectedParentIndex: Int = 0
    @Published var currentTabIndex = 0
    @Published var showProgress: Bool = false

    /// Authenticate the User
    @MainActor
    func loginUser(networkStatus: Bool) async {
        let loginCredentials = Login(
            username: username,
            password: password,
            server: server,
            port: port,
            secureSwitch: secureSwitch,
            useCookies: useCookies,
            acceptUntrustedCertificates: acceptUntrustedCertificates
        )
        
        UserDefaults.standard.set(username, forKey: "Username")
        KeychainItem.savePassword(password: password)
        UserDefaults.standard.set(server, forKey: "Server")
        UserDefaults.standard.set(port, forKey: "Port")
        UserDefaults.standard.set(secureSwitch, forKey: "Secure")
        UserDefaults.standard.set(useCookies, forKey: "Cookies")
        UserDefaults.standard.set(acceptUntrustedCertificates, forKey: "Trust")
        
        do {
            print(loginCredentials)
            guard let repository = networkRepository.networkRepositoryDelegate else {return}
            let (data, response) = try await repository.asyncLogin(loginReq: loginCredentials, reqObject: requestLoginObject())
            let payload = try JSONDecoder().decode(LoginResponse.self, from: data)
            
            await fireStatus(response: response)
            
            self.sessionID = payload.sessionid
            await self.createSession(sessionid: payload.sessionid, networkStatus: networkStatus)
        
            if KeychainItem.getSessionID == "" {
                KeychainItem.saveSessionID(sessionid: sessionID)
            }
            
        } catch {
            await errorCaught(error: error)
            self.logger.error("Error Logging in Error: \(error.localizedDescription)")
        }
    }
    
    func errorCaught(error: Error) async {
        await showAlert(error: error)
    }
    
    @MainActor
    func fireStatus(response: URLResponse) async {
        guard let httpResponse = response as? HTTPURLResponse else {return}
        switch httpResponse.statusCode {
        case 200...299:
            self.logger.info("success")
            self.showProgress = false
            self.showSettingsSheet = false
        case 401:
            await showAlert(response: httpResponse)
        case 402...500:
            await showAlert(response: httpResponse)
        case 501...599:
            await showAlert(response: httpResponse)
        case 600:
            await showAlert(response: httpResponse)
        default:
            await showAlert(response: httpResponse)
        }
    }
    
    @MainActor
    func showAlert(response: HTTPURLResponse? = nil, error: Error? = nil) async {
        var message: String = "No Message"
        if response == nil {
            message = error?.localizedDescription ?? "Error string empty"
        } else {
            message = "\(String(describing: response))"
        }
        self.errorMessage = message
        self.showErrorAlert = true
    }
    
    /// Create the Session
//   @FCSDKTransportActor
    func createSession(sessionid: String, networkStatus: Bool) async {
        self.uc = await ACBUC.uc(withConfiguration: sessionid, delegate: self)
        await self.uc?.setNetworkReachable(networkStatus)
        let acceptUntrustedCertificates = UserDefaults.standard.bool(forKey: "Secure")
        self.uc?.acceptAnyCertificate(acceptUntrustedCertificates)
        let useCookies = UserDefaults.standard.bool(forKey: "Cookies")
        self.uc?.useCookies = useCookies
        await self.uc?.startSession()
        self.connection = self.uc?.connection != nil
        await MainActor.run {
            self.sessionExists = true
        }
    }

    
    /// Logout and stop the session
    func logout() async {
        self.logger.info("Logging out of server: \(server) with: \(username)")
        await MainActor.run {
        self.showProgress = true
        }
        let loginCredentials = Login(
            username: username,
            password: password,
            server: server,
            port: port,
            secureSwitch: secureSwitch,
            useCookies: useCookies,
            acceptUntrustedCertificates: acceptUntrustedCertificates
        )
        await stopSession()
        do {
            guard let repository = networkRepository.networkRepositoryDelegate else {return}
            let response = try await repository.asyncLogout(logoutReq: loginCredentials, sessionid: self.sessionID)
            await setSessionID(id: sessionID)
            
            await fireStatus(response: response)
            await MainActor.run {
                self.sessionExists = false
                self.acbuc = nil
            }
        } catch {
            await errorCaught(error: error)
            self.logger.error("\(error.localizedDescription)")
            await MainActor.run {
                self.showProgress = false
            }
        }
    }
    
    @MainActor
    func setSessionID(id: String) async {
        self.connectedToSocket = self.uc?.connection != nil
        KeychainItem.deleteSessionID()
        sessionID = KeychainItem.getSessionID
    }
    
    /// Stop the Session
    func stopSession() async {
        await self.uc?.stopSession()
    }
}


extension AuthenticationService: ACBUCDelegate {
    
    func ucDidStartSession(_ uc: ACBUC) {
        self.logger.info("Started Session \(String(describing: uc))")
    }
    
    func ucDidFail(toStartSession uc: ACBUC) {
        self.logger.info("Failed to start Session \(String(describing: uc))")
    }
    
    func ucDidReceiveSystemFailure(_ uc: ACBUC) {
        self.logger.info("Received system failure \(String(describing: uc))")
    }
    
    func ucDidLoseConnection(_ uc: ACBUC) {
        self.logger.info("Did lose connection \(String(describing: uc))")
    }
    
    func uc(_ uc: ACBUC, willRetryConnectionNumber attemptNumber: Int, in delay: TimeInterval) {
        self.logger.info("We are trying to reconnect to the network \(uc), \(attemptNumber), \(delay)")
        Task {
            await self.uc?.startSession()
            await MainActor.run {
            self.sessionExists = true
            }
        }
    }
    
    func ucDidReestablishConnection(_ uc: ACBUC) {
        self.logger.info("We restablished Network Connectivity \(uc)")
    }
    
}
