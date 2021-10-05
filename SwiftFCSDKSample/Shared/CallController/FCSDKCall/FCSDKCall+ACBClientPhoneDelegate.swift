//
//  FCSDKCall+ACBClientPhoneDelegate.swift
//  SwiftFCSDKSample
//
//  Created by Cole M on 10/4/21.
//

import Foundation
import SwiftFCSDK
import AVFoundation

extension FCSDKCall {
    //Receive calls with ACBClientSDK
    func phoneDidReceive(_ phone: ACBClientPhone?, call: ACBClientCall?) {
        
    }
    

    func callDidReceiveMediaChangeRequest(_ call: ACBClientCall?) {
    }
    
    func switchToNotInCallUI() {
        //TODO: - Hide any UI that is needed
    }
    
    func phone(_ phone: ACBClientPhone?, didChange settings: ACBVideoCaptureSetting?, forCamera camera: AVCaptureDevice.Position) {
        print("didChangeCaptureSetting - resolution=\(String(describing: settings?.resolution.rawValue)) frame rate=\(String(describing: settings?.frameRate)) camera=\(camera.rawValue)")
    }
    
}
