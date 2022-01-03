//
//  FCSDKCall+ACBClientPhoneDelegate.swift
//  CBAFusion
//
//  Created by Cole M on 10/4/21.
//

import Foundation
import AVFoundation
import FCSDKiOS
import SwiftUI

extension FCSDKCallService: ACBClientPhoneDelegate  {
    
    
    //Receive calls with FCSDK
    func phoneDidReceive(_ phone: ACBClientPhone?, call: ACBClientCall?) {
        if self.fcsdkCall?.call == nil {
            Task {
                guard let uc = self.acbuc else { return }
                
                // We need to temporarily assign ourselves as the call's delegate so that we get notified if it ends before we answer it.
                call?.delegate = self
                let receivedCall = FCSDKCall(
                    handle: call?.remoteAddress ?? "",
                    hasVideo: self.fcsdkCall?.hasVideo ?? false,
                    previewView: nil,
                    remoteView: nil,
                    uuid: UUID(),
                    acbuc: uc,
                    call: call!
                )
                await MainActor.run {
                    self.fcsdkCall = receivedCall
                    self.fcsdkCall?.call?.delegate = call?.delegate
                }
                    await self.appDelegate?.displayIncomingCall(fcsdkCall: receivedCall)
            }
        } else {
            print("We currently don't support responding to multiple calls")
        }
    }
    
    func phone(_ phone: ACBClientPhone?, didChange settings: ACBVideoCaptureSetting?, forCamera camera: AVCaptureDevice.Position) {
        print("didChangeCaptureSetting - resolution=\(String(describing: settings?.resolution.rawValue)) frame rate=\(String(describing: settings?.frameRate)) camera=\(camera.rawValue)")
    }
    
}
