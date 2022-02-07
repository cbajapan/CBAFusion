//
//  UIApplication+Extension.swift
//  CBAFusion
//
//  Created by Cole M on 2/2/22.
//

import UIKit

extension UIApplication {
    static var appVersion: String? {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    }
}
