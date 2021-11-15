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
    func configureAudioSession() {
        // See https://forums.developer.apple.com/thread/64544
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(AVAudioSession.Category.playAndRecord, mode: .default)
            try session.setActive(true)
            try session.setMode(AVAudioSession.Mode.voiceChat)
            try session.setPreferredSampleRate(44100.0)
            try session.setPreferredIOBufferDuration(0.005)
        } catch {
            print(error)
        }
    }

    
    //Receive calls with ACBClientSDK
    func phoneDidReceive(_ phone: ACBClientPhone?, call: ACBClientCall?) {
        guard let uc = self.acbuc else { return }
        self.playRingtone()

        // We need to temporarily assign ourselves as the call's delegate so that we get notified if it ends before we answer it.
        call?.delegate = self
        
        if UserDefaults.standard.bool(forKey: "AutoAnswer") {
            
            self.stopRingtone()
            DispatchQueue.main.async { [weak self] in
                guard let strongSelf = self else { return }
                let receivedCall = FCSDKCall(
                    handle: call?.remoteAddress ?? "",
                    hasVideo: strongSelf.fcsdkCall?.hasVideo ?? false,
                    previewView: nil,
                    remoteView: nil,
                    uuid: UUID(),
                    acbuc: uc,
                    call: call!
                )
                
                strongSelf.fcsdkCall = receivedCall
                strongSelf.fcsdkCall?.call?.delegate = call?.delegate

                Task {
                    await strongSelf.presentCommunicationSheet()
                }
            }
            
        } else {
            // we need to pass this to the call manager
            DispatchQueue.main.async { [weak self] in
                guard let strongSelf = self else { return }
                let backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
                let receivedCall = FCSDKCall(
                    handle: call?.remoteAddress ?? "",
                    hasVideo: strongSelf.fcsdkCall?.hasVideo ?? false,
                    previewView: nil,
                    remoteView: nil,
                    uuid: UUID(),
                    acbuc: uc,
                    call: call!
                )

                strongSelf.fcsdkCall = receivedCall
                strongSelf.fcsdkCall?.call?.delegate = call?.delegate
                Task {
                    await strongSelf.appDelegate?.displayIncomingCall(fcsdkCall: receivedCall)
                    UIApplication.shared.endBackgroundTask(backgroundTaskIdentifier)
                }
            }
        }
    }
    
    func phone(_ phone: ACBClientPhone?, didChange settings: ACBVideoCaptureSetting?, forCamera camera: AVCaptureDevice.Position) {
        print("didChangeCaptureSetting - resolution=\(String(describing: settings?.resolution.rawValue)) frame rate=\(String(describing: settings?.frameRate)) camera=\(camera.rawValue)")
    }
    
}
