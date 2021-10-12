//
//  FCSDKCall+ACBClientPhoneDelegate.swift
//  SwiftFCSDKSample
//
//  Created by Cole M on 10/4/21.
//

import Foundation
import AVFoundation
import SwiftFCSDK
import SwiftUI

extension FCSDKCallService: ACBClientPhoneDelegate  {
    //Receive calls with ACBClientSDK
    func phoneDidReceive(_ phone: ACBClientPhone?, call: ACBClientCall?) {
        let backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
        guard let uc = fcsdkCall?.acbuc else { return }
        let receivedCall = FCSDKCall(
            handle: call?.remoteAddress ?? "",
            hasVideo: fcsdkCall?.hasVideo ?? false,
            previewView: fcsdkCall?.previewView ?? SamplePreviewVideoCallView(),
            remoteView: fcsdkCall?.remoteView ?? SampleBufferVideoCallView(),
            uuid: UUID(uuidString: call?.callId ?? "") ?? UUID(), acbuc: uc,
            call: call!
        )
        AppDelegate.shared.displayIncomingCall(uuid: receivedCall.uuid, handle: receivedCall.handle, hasVideo: receivedCall.hasVideo) { error in
            UIApplication.shared.endBackgroundTask(backgroundTaskIdentifier)
        }
    }
    
    //TODO: - Write Some code
    func presentAnswerCallUI() {
        
    }
    
    func switchToNotInCallUI() {
        //TODO: - Hide any UI that is needed
    }
    
    func phone(_ phone: ACBClientPhone?, didChange settings: ACBVideoCaptureSetting?, forCamera camera: AVCaptureDevice.Position) {
        print("didChangeCaptureSetting - resolution=\(String(describing: settings?.resolution.rawValue)) frame rate=\(String(describing: settings?.frameRate)) camera=\(camera.rawValue)")
    }
    
}
