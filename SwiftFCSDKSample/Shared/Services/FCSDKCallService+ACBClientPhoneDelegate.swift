//
//  FCSDKCall+ACBClientPhoneDelegate.swift
//  SwiftFCSDKSample
//
//  Created by Cole M on 10/4/21.
//

import Foundation
import AVFoundation
import FCSDKiOS
import SwiftUI

extension FCSDKCallService: ACBClientPhoneDelegate  {

    
    //Receive calls with ACBClientSDK
    func phoneDidReceive(_ phone: ACBClientPhone?, call: ACBClientCall?) {
        Task {
            guard let uc = self.acbuc else { return }
            await self.playRingtone()
            
            // We need to temporarily assign ourselves as the call's delegate so that we get notified if it ends before we answer it.
            call?.delegate = self
            
            if UserDefaults.standard.bool(forKey: "AutoAnswer") {
                await self.stopRingtone()
                
                await MainActor.run {
                    let receivedCall = FCSDKCall(
                        handle: call?.remoteAddress ?? "",
                        hasVideo: self.fcsdkCall?.hasVideo ?? false,
                        previewView: nil,
                        remoteView: nil,
                        uuid: UUID(),
                        acbuc: uc,
                        call: call!
                    )
                    
                    self.fcsdkCall = receivedCall
                    self.fcsdkCall?.call?.delegate = call?.delegate
                }
                await self.presentCommunicationSheet()
                
                
            } else {
                // we need to pass this to the call manager
                await MainActor.run {
                    let receivedCall = FCSDKCall(
                        handle: call?.remoteAddress ?? "",
                        hasVideo: self.fcsdkCall?.hasVideo ?? false,
                        previewView: nil,
                        remoteView: nil,
                        uuid: UUID(),
                        acbuc: uc,
                        call: call!
                    )
                    
                    self.fcsdkCall = receivedCall
                    self.fcsdkCall?.call?.delegate = call?.delegate
                }
                guard let call = self.fcsdkCall else {return}
                await self.appDelegate?.displayIncomingCall(fcsdkCall: call)
                
            }
        }
    }
    
    func phone(_ phone: ACBClientPhone?, didChange settings: ACBVideoCaptureSetting?, forCamera camera: AVCaptureDevice.Position) {
        print("didChangeCaptureSetting - resolution=\(String(describing: settings?.resolution.rawValue)) frame rate=\(String(describing: settings?.frameRate)) camera=\(camera.rawValue)")
    }
    
}
