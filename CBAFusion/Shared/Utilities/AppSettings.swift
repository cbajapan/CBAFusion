//
//  AppSettings.swift
//  AppSettings
//
//  Created by Cole M on 9/14/21.
//

import Foundation
import FCSDKiOS


enum MediaValue: String {
    case keyAudioDirection = "acb.audio.direction"
    case keyVideoDirection = "acb.video.direction"
}


struct AppSettings: Sendable {
    
    @MainActor
    static var media = ACBMediaDirection.sendAndReceive
    @MainActor
    static func registerDefaults(_ video: ACBMediaDirection, audio: ACBMediaDirection) {
        UserDefaults.standard.set(audio.rawValue, forKey: MediaValue.keyAudioDirection.rawValue)
        UserDefaults.standard.set(video.rawValue, forKey: MediaValue.keyVideoDirection.rawValue)
    }
    
    @MainActor
   static func mediaDirection(for string: String) -> ACBMediaDirection {
       switch ACBMediaDirection(rawValue: string) ?? .none {
        case .sendAndReceive:
            return ACBMediaDirection.sendAndReceive
        case .sendOnly:
            return ACBMediaDirection.sendOnly
        case .receiveOnly:
            return ACBMediaDirection.receiveOnly
        case .none:
           return ACBMediaDirection.none
        default:
            return ACBMediaDirection.sendAndReceive
        }
    }
    @MainActor
    static func perferredAudioDirection() -> ACBMediaDirection {
        guard let audioPreference = UserDefaults.standard.string(forKey: MediaValue.keyAudioDirection.rawValue) else { return ACBMediaDirection.none }
        return self.mediaDirection(for: audioPreference)
    }
    @MainActor
    static func perferredVideoDirection() -> ACBMediaDirection {
        guard let videoPreference = UserDefaults.standard.string(forKey: MediaValue.keyVideoDirection.rawValue) else { return ACBMediaDirection.none }
        return  self.mediaDirection(for: videoPreference)
    }
}
