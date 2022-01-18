//
//  LocalNotification.swift
//  CBAFusion
//
//  Created by Cole M on 1/5/22.
//

import Foundation
import UserNotifications
import Logging

class LocalNotification {
    public static func newMessageNotification(title: String, subtitle: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.subtitle = subtitle
        content.body = body
        content.sound = UNNotificationSound.default
        content.badge = 1
        let uuidString = UUID().uuidString
        let request = UNNotificationRequest(identifier: uuidString,
                                            content: content, trigger: .none)
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.add(request) { (error) in
           if error != nil {
               Logger(label: "\(Constants.BUNDLE_IDENTIFIER) - Local Notification - ")
                   .error("Local Notification Error: \(error as Any)")
           }
        }
    }
}
