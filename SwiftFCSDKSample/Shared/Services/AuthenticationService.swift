//
//  AuthenticationServices.swift
//  SwiftFCSDKSample
//
//  Created by Cole M on 8/31/21.
//

import Foundation
import SwiftUI
import FCSDKiOS

class AuthenticationService: NSObject, ObservableObject {
    
    override init(){}
    
    @Published var username = UserDefaults.standard.string(forKey: "Username") ?? ""
    @Published var password = KeychainItem.getPassword
    @Published var server = UserDefaults.standard.string(forKey: "Server") ?? ""
    @Published var port = UserDefaults.standard.string(forKey: "Port") ?? ""
    @Published var secureSwitch = UserDefaults.standard.bool(forKey: "Secure")
    @Published var useCookies = UserDefaults.standard.bool(forKey: "Cookies")
    @Published var acceptUntrustedCertificates = UserDefaults.standard.bool(forKey: "Trust")
#if !DEBUG
    @Published var sessionID = KeychainItem.getSessionID
#else
    @Published var sessionID = UserDefaults.standard.string(forKey: "SessionID") ?? ""
#endif
    @Published var connectedToSocket = false
    @Published var acbuc: ACBUC?
    
    
    /// Authenticate the User
    @MainActor
    func loginUser(networkStatus: Bool) async {
        let loginCredentials = LoginViewModel(login:
                                                Login(
                                                    username: username,
                                                    password: password,
                                                    server: server,
                                                    port: port,
                                                    secureSwitch: secureSwitch,
                                                    useCookies: useCookies,
                                                    acceptUntrustedCertificates: acceptUntrustedCertificates
                                                ))
        
        
        UserDefaults.standard.set(username, forKey: "Username")
        KeychainItem.savePassword(password: password)
        UserDefaults.standard.set(server, forKey: "Server")
        UserDefaults.standard.set(port, forKey: "Port")
        UserDefaults.standard.set(secureSwitch, forKey: "Secure")
        UserDefaults.standard.set(useCookies, forKey: "Cookies")
        UserDefaults.standard.set(acceptUntrustedCertificates, forKey: "Trust")
        
        let payload = try? await NetworkRepository.shared.asyncLogin(loginReq: loginCredentials)
        self.sessionID = payload?.sessionid ?? ""
        await self.createSession(sessionid: payload?.sessionid ?? "", networkStatus: networkStatus)
        self.connectedToSocket = self.acbuc?.connection != nil
        
#if !DEBUG
        if KeychainItem.getSessionID == "" {
            KeychainItem.saveSessionID(sessionid: sessionID)
        }
#else
        if UserDefaults.standard.string(forKey: "SessionID") != "" {
            UserDefaults.standard.set(sessionID, forKey: "SessionID")
        }
#endif
    }
    
    
    /// Create the Session
    func createSession(sessionid: String, networkStatus: Bool) async {
        self.acbuc = ACBUC.uc(withConfiguration: sessionid, delegate: self)
        self.acbuc?.setNetworkReachable(networkStatus)
        let acceptUntrustedCertificates = UserDefaults.standard.bool(forKey: "Secure")
        self.acbuc?.acceptAnyCertificate(acceptUntrustedCertificates)
        let useCookies = UserDefaults.standard.bool(forKey: "Cookies")
        self.acbuc?.useCookies = useCookies
        self.acbuc?.startSession()
    }
    
    
    /// Logout and stop the session
    @MainActor
    func logout() async {
        print("Logging out of server: \(server) with: \(username)")
        let loginCredentials = LoginViewModel(login:
                                                Login(
                                                    username: username,
                                                    password: password,
                                                    server: server,
                                                    port: port,
                                                    secureSwitch: secureSwitch,
                                                    useCookies: useCookies,
                                                    acceptUntrustedCertificates: acceptUntrustedCertificates
                                                ))
        await stopSession()
        await NetworkRepository.shared.asyncLogout(logoutReq: loginCredentials, sessionid: self.sessionID)
        self.connectedToSocket = self.acbuc?.connection != nil
#if !DEBUG
        KeychainItem.deleteSessionID()
#else
        UserDefaults.standard.removeObject(forKey: "SessionID")
        sessionID = UserDefaults.standard.string(forKey: "SessionID") ?? ""
#endif
    }
    
    /// Stop the Session
    func stopSession() async {
        self.acbuc?.stopSession()
    }
    
    func selectAudio(audio: AudioOptions) {
        switch audio {
        case .ear:
            let ear = self.acbuc?.clientPhone.audioDeviceManager?.setAudioDevice(device: .earpiece)
            print("Is Ear", ear ?? false)
        case .speaker:
            let speaker = self.acbuc?.clientPhone.audioDeviceManager?.setAudioDevice(device: .speakerphone)
            print("Is Speaker:", speaker ?? false)
        }
    }
    
    func selectResolution(res: ResolutionOptions) {
        switch res {
        case .auto:
            self.acbuc?.clientPhone.preferredCaptureResolution = ACBVideoCapture.autoResolution;
        case .res288p:
            self.acbuc?.clientPhone.preferredCaptureResolution = ACBVideoCapture.resolution352x288;
        case .res480p:
            self.acbuc?.clientPhone.preferredCaptureResolution = ACBVideoCapture.resolution640x480;
        case .res720p:
            self.acbuc?.clientPhone.preferredCaptureResolution = ACBVideoCapture.resolution1280x720;
        }
    }
    
    func selectFramerate(rate: FrameRateOptions) {
        switch rate {
        case .fro20:
            self.acbuc?.clientPhone.preferredCaptureFrameRate = 20
        case .fro30:
            self.acbuc?.clientPhone.preferredCaptureFrameRate = 30
        }
    }

}


extension AuthenticationService: ACBUCDelegate {
    
    func ucDidStartSession(_ uc: ACBUC?) {
        print("Started Session \(String(describing: uc))")
    }
    
    func ucDidFail(toStartSession uc: ACBUC?) {
        print("Failed to start Session \(String(describing: uc))")
    }
    
    func ucDidReceiveSystemFailure(_ uc: ACBUC?) {
        print("Received system failure \(String(describing: uc))")
    }
    
    func ucDidLoseConnection(_ uc: ACBUC?) {
        print("Did lose connection \(String(describing: uc))")
    }
    
}
