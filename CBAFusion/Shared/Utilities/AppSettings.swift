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


struct AppSettings {
    
    static let media = ACBMediaDirection.sendAndReceive

    static func registerDefaults() {
        UserDefaults.standard.set(ACBMediaDirection.sendAndReceive.rawValue, forKey: MediaValue.keyAudioDirection.rawValue)
        UserDefaults.standard.set(ACBMediaDirection.sendAndReceive.rawValue, forKey: MediaValue.keyVideoDirection.rawValue)
    }
    
    
   static func mediaDirection(for string: String) -> ACBMediaDirection {
       switch AppSettings.media {
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
    
    static func perferredAudioDirection() -> ACBMediaDirection {
        guard let audioPreference = UserDefaults.standard.string(forKey: MediaValue.keyAudioDirection.rawValue) else { return ACBMediaDirection.none }
        return self.mediaDirection(for: audioPreference)
    }
    
    static func perferredVideoDirection() -> ACBMediaDirection {
        guard let videoPreference = UserDefaults.standard.string(forKey: MediaValue.keyVideoDirection.rawValue) else { return ACBMediaDirection.none }
        return  self.mediaDirection(for: videoPreference)
    }
}
