//
//  NSUserActivity+Extension.swift
//  CBAFusion
//
//  Created by Cole M on 10/8/21.
//

import Foundation
import Intents

extension NSUserActivity: StartCallConvertible {

    var startCallHandle: String? {
        guard let startCallIntent = interaction?.intent as? INStartCallIntent,
            let personHandle = startCallIntent.contacts?.first?.personHandle
            else {
                return nil
        }

        return personHandle.value
    }

    var isVideo: Bool? {
        guard let startCallIntent = interaction?.intent as? INStartCallIntent else { return nil }
        return startCallIntent.callCapability == .videoCall
    }

}

