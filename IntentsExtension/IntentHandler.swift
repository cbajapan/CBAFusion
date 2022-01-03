//
//  IntentHandler.swift
//  IntentsExtension
//
//  Created by Cole M on 1/3/22.
//

import Intents

class IntentHandler: INExtension {
    
    func handle(intent: INStartCallIntent, completion: @escaping (INStartCallIntentResponse) -> Void) {
        print("MY_INTENT, \(intent)")
        let response: INStartCallIntentResponse

        defer {
            completion(response)
        }

        // Ensure there is a person handle.
        guard intent.contacts?.first?.personHandle != nil else {
            response = INStartCallIntentResponse(code: .failure, userActivity: nil)
            return
        }

        let userActivity = NSUserActivity(activityType: String(describing: INStartCallIntent.self))
print("USER_ACTIVTY: \(userActivity)")
        response = INStartCallIntentResponse(code: .continueInApp, userActivity: userActivity)
    }
    
}

extension IntentHandler: INShareFocusStatusIntentHandling {
    func handle(intent: INShareFocusStatusIntent, completion: @escaping (INShareFocusStatusIntentResponse) -> Void) {
        /// Check if Focus is enabled.
        if intent.focusStatus?.isFocused == true {
             /// Focus is enabled
            print("Focus is enabled")
        } else {
            print("Focus is disabled")
        }
        /// Provide a response
        let response = INShareFocusStatusIntentResponse(code: .success, userActivity: nil)
        completion(response)
    }
}
