//
//  LoginResponse.swift
//  SwiftFCSDKSample
//
//  Created by Cole M on 8/31/21.
//

import Foundation

struct LoginResponse: Codable {
    var id: UUID?
    var sessionid: String
    var voiceUser: String
    var voiceDomain: String
}


struct LogoutResponse: Codable {
    var response: String
}
