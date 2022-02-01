//
//  IntentHandler.swift
//  IntentExtension
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
