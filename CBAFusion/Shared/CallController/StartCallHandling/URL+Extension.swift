//
//  URL+Extension.swift
//  CBAFusion
//
//  Created by Cole M on 10/8/21.
//

import Foundation

extension URL: StartCallConvertible {

    private struct Constants {
        static let URLScheme = "cbaFusion"
    }

    var startCallHandle: String? {
        guard scheme == Constants.URLScheme else { return nil }

        return host
    }

}
