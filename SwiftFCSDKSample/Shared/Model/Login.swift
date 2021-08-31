//
//  Login.swift
//  SwiftFCSDKSample
//
//  Created by Cole M on 8/31/21.
//

import Foundation


struct Login: Codable {
    var username: String
    var password: String
    var server: String
    var port: String
    var secureSwitch: Bool
    var useCookies: Bool
    var acceptUntrustedCertificates: Bool
}
