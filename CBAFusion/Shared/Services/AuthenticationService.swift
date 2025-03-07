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

/// Protocol defining the authentication functionalities.
protocol AuthenticationProtocol: AnyObject {
    var uc: ACBUC? { get set }
    func loginUser(networkStatus: Bool) async
}

/// Global actor for managing authentication tasks.
@globalActor
actor AuthenticationActor {
    static let shared = AuthenticationActor()
}

/// Service responsible for user authentication and session management.
final class AuthenticationService: NSObject, ObservableObject, AuthenticationProtocol, @unchecked Sendable {
    
    // Logger for tracking authentication events
    let logger = Logger(label: "\(Constants.BUNDLE_IDENTIFIER) - Authentication Service - ")
    
    // Repository for network operations
    let networkRepository = NetworkRepository()
    
    // User credentials and settings
    @Published var username = UserDefaults.standard.string(forKey: "Username") ?? ""
    @Published var password = KeychainItem.getPassword
    @Published var server = UserDefaults.standard.string(forKey: "Server") ?? ""
    @Published var port = UserDefaults.standard.string(forKey: "Port") ?? ""
    @Published var secureSwitch = UserDefaults.standard.bool(forKey: "Secure")
    @Published var useCookies = UserDefaults.standard.bool(forKey: "Cookies")
    @Published var acceptUntrustedCertificates = UserDefaults.standard.bool(forKey: "Trust")
    @Published var alwaysRetryConnection = UserDefaults.standard.bool(forKey: "Retry")
    @Published var sessionID = KeychainItem.getSessionID
    @Published var connectedToSocket = false
    @Published var showStartedSession = false
    @Published var showSystemFailed = false
    @Published var showFailedSession = false
    @Published var showDidLoseConnection = false
    @Published var showReestablishedConnection = false
    @Published var showErrorAlert: Bool = false
    @Published var errorMessage: String = ""
    @Published var showSettingsSheet = false
    @Published var selectedParentIndex: Int = 0
    @Published var currentTabIndex = 0
    @Published var showProgress: Bool = false
    @Published var sessionExists = false
    
    var uc: ACBUC?
    
    // Connection state
    var connection = false {
        didSet {
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.connectedToSocket = self.connection
            }
        }
    }
    
    override init() {
        super.init()
        self.networkRepository.networkRepositoryDelegate = networkRepository
    }
    
    deinit {
        // Clean up resources if needed
    }
    
    /// Creates a login request object with the current credentials.
    func requestLoginObject() -> LoginRequest {
        return LoginRequest(username: username, password: password)
    }
    
    /// Authenticates the user with the provided credentials.
    @AuthenticationActor
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
        
        // Save user credentials to UserDefaults and Keychain
        saveUserCredentials()
        
        do {
            guard let repository = networkRepository.networkRepositoryDelegate else { return }
            let (data, response) = try await repository.asyncLogin(loginReq: loginCredentials, reqObject: requestLoginObject())
            let payload = try JSONDecoder().decode(LoginResponse.self, from: data)
            await fireStatus(response: response)
            
            // Update session ID and create a session
            await updateSessionID(with: payload.sessionid)
            await createSession(sessionid: payload.sessionid, networkStatus: networkStatus)
            
            // Save session ID to Keychain if it's empty
            if KeychainItem.getSessionID.isEmpty {
                KeychainItem.saveSessionID(sessionid: sessionID)
            }
        } catch {
            await handleError(error)
        }
    }
    
    /// Updates the session ID and checks the connection status.
    @MainActor
    private func updateSessionID(with newSessionID: String) async {
        // Update the session ID property
        self.sessionID = newSessionID
        
        // Check if the connection is still valid
        if let currentUC = self.uc {
            // Update the connection status based on the current ACBUC instance
            self.connectedToSocket = currentUC.connection
            
            // Optionally, you can log the new session ID and connection status
            logger.info("Updated session ID to: \(newSessionID)")
            logger.info("Connection status updated: \(self.connectedToSocket ? "Connected" : "Disconnected")")
        } else {
            // If uc is nil, it means there is no active session
            self.connectedToSocket = false
            logger.warning("No active session found when updating session ID.")
        }
    }
    
    /// Saves user credentials to UserDefaults and Keychain.
    private func saveUserCredentials() {
        UserDefaults.standard.set(username, forKey: "Username")
        KeychainItem.savePassword(password: password)
        UserDefaults.standard.set(server, forKey: "Server")
        UserDefaults.standard.set(port, forKey: "Port")
        UserDefaults.standard.set(secureSwitch, forKey: "Secure")
        UserDefaults.standard.set(useCookies, forKey: "Cookies")
        UserDefaults.standard.set(acceptUntrustedCertificates, forKey: "Trust")
        UserDefaults.standard.set(alwaysRetryConnection, forKey: "Retry")
    }
    
    /// Handles errors during login and shows an alert.
    private func handleError(_ error: Error) async {
        await showAlert(error: error)
        logger.error("Error Logging in: \(error.localizedDescription)")
    }
    
    /// Checks the response status and handles it accordingly.
    @MainActor
    func fireStatus(response: URLResponse) async {
        guard let httpResponse = response as? HTTPURLResponse else { return }
        switch httpResponse.statusCode {
        case 200...299:
            logger.info("Login successful")
            showProgress = false
            showSettingsSheet = false
        case 401:
            await showAlert(response: httpResponse)
        case 402...500, 501...599, 600:
            await showAlert(response: httpResponse)
        default:
            await showAlert(response: httpResponse)
        }
    }
    
    /// Displays an alert with the error message or response details.
    @MainActor
    func showAlert(response: HTTPURLResponse? = nil, error: Error? = nil) async {
        var message: String = error?.localizedDescription ?? "No Message"
        if let response = response {
            message = "\(String(describing: response))"
        }
        errorMessage = message
        showErrorAlert = true
    }
    
    /// Creates a session with the provided session ID.
    func createSession(sessionid: String, networkStatus: Bool) async {
        self.uc = await ACBUC.uc(
            withConfiguration: sessionid,
            stunServers: [],
            audioDSCPPriority: .high,
            videoDSCPPriority: .high,
            delegate: self
        )
        uc?.phone.mirrorFrontFacingCameraPreview = await FCSDKCallService.shared.isMirroredFrontCamera
        //Set resolution and frame rate as soon as possible
        let selectedFrameRate = UserDefaults.standard.string(forKey: "RateOption") ?? FrameRateOptions.fro30.rawValue
        let selectedResolution = UserDefaults.standard.string(forKey: "ResolutionOption") ?? ResolutionOptions.auto.rawValue
        guard let uc = uc else { return }
        uc.phone.delegate = await FCSDKCallService.shared
        uc.phone.callDelegate = await FCSDKCallService.shared
        self.selectResolution(uc: uc, res: ResolutionOptions(rawValue: selectedResolution) ?? ResolutionOptions.auto)
        self.selectFramerate(uc: uc, rate: FrameRateOptions(rawValue: selectedFrameRate) ?? FrameRateOptions.fro30)
        
        self.uc?.logLevel = .info
        await self.uc?.setNetworkReachable(networkStatus)
        self.uc?.acceptAnyCertificate(UserDefaults.standard.bool(forKey: "Secure"))
        self.uc?.useCookies = UserDefaults.standard.bool(forKey: "Cookies")
        
        // Start session with retry option
        if UserDefaults.standard.bool(forKey: "Retry") {
            await self.uc?.startSession(triggerReconnect: true, timeout: 10)
        } else {
            await self.uc?.startSession(timeout: 10)
        }
        
        connection = self.uc?.connection != nil
        
        await MainActor.run { [weak self] in
            guard let self else { return }
            self.sessionExists = true
        }
    }
    
    /// Selects the resolution for the video call.
    /// - Parameter res: The resolution option to select.
    func selectResolution(uc: ACBUC, res: ResolutionOptions) {
        switch res {
        case .auto:
            uc.phone.preferredCaptureResolution = ACBVideoCapture.resolutionAuto
        case .res288p:
            uc.phone.preferredCaptureResolution = ACBVideoCapture.resolution352x288
        case .res480p:
            uc.phone.preferredCaptureResolution = ACBVideoCapture.resolution640x480
        case .res720p:
            uc.phone.preferredCaptureResolution = ACBVideoCapture.resolution1024x768
        }
    }
    
    /// Selects the frame rate for the video call.
    /// - Parameter rate: The frame rate option to select.
    func selectFramerate(uc: ACBUC, rate: FrameRateOptions) {
        switch rate {
        case .fro20:
            uc.phone.preferredCaptureFrameRate = 20
        case .fro30:
            uc.phone.preferredCaptureFrameRate = 30
        case .fro60:
            uc.phone.preferredCaptureFrameRate = 60
        }
    }
    
    /// Removes the current call from the call service.
    @MainActor
    func removeCall() async {
        FCSDKCallService.shared.fcsdkCall = nil
    }
    
    /// Logs out the user and stops the session.
    func logout() async {
        logger.info("Logging out of server: \(server) with: \(username)")
        showProgress = true
        
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
        self.uc = nil
        await removeCall()
        
        do {
            guard let repository = networkRepository.networkRepositoryDelegate else { return }
            let response = try await repository.asyncLogout(logoutReq: loginCredentials, sessionid: self.sessionID)
            await setSessionID()
            await fireStatus(response: response)
            sessionExists = false
        } catch {
            await handleError(error)
            UserDefaults.standard.set("", forKey: "Server")
            await setSessionID()
            showProgress = false
            showSettingsSheet = false
        }
    }
    
    /// Updates the session ID and connection status.
    @MainActor
    func setSessionID() async {
        connectedToSocket = self.uc?.connection != nil
        KeychainItem.deleteSessionID()
        sessionID = KeychainItem.getSessionID
    }
    
    /// Stops the current session.
    func stopSession() async {
        await self.uc?.stopSession()
    }
}

// MARK: - ACBUCDelegate Implementation
extension AuthenticationService: ACBUCDelegate {
    
    @MainActor
    func didStartSession(_ uc: ACBUC) async {
        logger.info("Started Session \(String(describing: uc))")
        _ = Task { [weak self] in
            guard let self else { return }
            showStartedSession = true
#if swift(>=6.0)
            if #available(iOS 18.0, *) {
                await sleep()
            }
#endif
            showStartedSession = false
        }
    }
    
    @MainActor
    func didFail(toStartSession uc: ACBUC) async {
        Task {
            logger.info("Failed to start Session \(String(describing: uc))")
            showFailedSession = true
#if swift(>=6.0)
            if #available(iOS 18.0, *) {
                await sleep()
            }
#endif
            showFailedSession = false
        }
    }
    
    @MainActor
    func didReceiveSystemFailure(_ uc: ACBUC) async {
        Task {
            logger.info("Received system failure \(String(describing: uc))")
            showSystemFailed = true
#if swift(>=6.0)
            if #available(iOS 18.0, *) {
                await sleep()
            }
#endif
            showSystemFailed = false
        }
    }
    
    @MainActor
    func didLoseConnection(_ uc: ACBUC) async {
        Task {
            logger.info("Did lose connection \(String(describing: uc))")
            showDidLoseConnection = true
#if swift(>=6.0)
            if #available(iOS 18.0, *) {
                await sleep()
            }
#endif
            showDidLoseConnection = false
        }
    }
    
    @MainActor
    func uc(_ uc: ACBUC, willRetryConnection attemptNumber: Int, in delay: TimeInterval) async {
        logger.info("Attempting to reconnect to the network - Attempt: \(attemptNumber), Delay: \(delay)")
        if attemptNumber == 7 {
            if UserDefaults.standard.bool(forKey: "Retry") {
                await self.uc?.startSession(triggerReconnect: true, timeout: 10)
            } else {
                await self.uc?.startSession(timeout: 10)
            }
            sessionExists = true
        }
    }
    
    @MainActor
    func didReestablishConnection(_ uc: ACBUC) async {
        Task {
            logger.info("Reestablished Network Connectivity - UC: \(uc)")
            showReestablishedConnection = true
#if swift(>=6.0)
            if #available(iOS 18.0, *) {
                await sleep()
            }
#endif
            showReestablishedConnection = false
        }
    }
    
    
    func sleep() async {
        if #available(iOS 16.0, *) {
            try? await Task.sleep(until: .now + .seconds(2), clock: .suspending)
        } else {
            try? await Task.sleep(nanoseconds: NSEC_PER_SEC * 2_000_000)
        }
    }
}
