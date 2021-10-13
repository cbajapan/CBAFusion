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
        guard let uc = acbuc else { return }
        
        self.acbCall = call;
        self.playRingtone()
        
        // We need to temporarily assign ourselves as the call's delegate so that we get notified if it ends before we answer it.
        call?.delegate = self
        // we need to pass this to the call manager
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }
            let backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
            let receivedCall = FCSDKCall(
                handle: call?.remoteAddress ?? "",
                hasVideo: strongSelf.fcsdkCall?.hasVideo ?? false,
                previewView: strongSelf.fcsdkCall?.previewView ?? SamplePreviewVideoCallView(),
                remoteView: strongSelf.fcsdkCall?.remoteView ?? SampleBufferVideoCallView(),
                uuid: UUID(uuidString: call?.callId ?? "") ?? UUID(), acbuc: uc,
                call: call!
            )
            
            
            
            Task {
                await strongSelf.appDelegate?.displayIncomingCall(fcsdkCall: receivedCall)
                    UIApplication.shared.endBackgroundTask(backgroundTaskIdentifier)
            }
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
