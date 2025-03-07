//
//  FCSDKCall+ACBCallDelegate.swift
//  CBAFusion
//
//  Created by Cole M on 10/4/21.
//

import Foundation
import FCSDKiOS
import AVFoundation
import UIKit

// Extension to handle call events and manage call state
extension FCSDKCallService: ACBClientCallDelegate, @unchecked Sendable {
    
    // Called when the remote display name changes
    func didChangeRemoteDisplayName(_ name: String, with call: FCSDKiOS.ACBClientCall) async {
        // Handle remote display name change if needed
    }
    
    // Called when a media change request is received
    func willReceiveMediaChangeRequest(_ call: FCSDKiOS.ACBClientCall) async {
        // Handle media change request if needed
    }
    
    // Called when a provisional response status is received
    func responseStatus(didReceive responseStatus: FCSDKiOS.ACBClientCallProvisionalResponse, withReason reason: String, call: FCSDKiOS.ACBClientCall) async {
        // Handle response status if needed
    }
    
    // Ends the call and cleans up resources
    @MainActor private func endCall() async {
        if !endPressed {
            self.hasEnded = true
        }
        
        if #available(iOS 15.0, *), isBuffer {
            await self.fcsdkCall?.call?.removeBufferView()
            await self.fcsdkCall?.call?.removeLocalBufferView()
            
            RemoteViews.shared.views.removeAll()
            fcsdkCall?.communicationView?.previewView = nil
        }
        
        self.endPressed = false
    }
    
    // Sets up buffer views for local and remote video
    @MainActor
    func setupBufferViews(call: ACBClientCall) async {
        let localVideoScale = UserDefaults.standard.string(forKey: "LocalScale") ?? "Horizontal"
        let remoteVideoScale = UserDefaults.standard.string(forKey: "RemoteScale") ?? "Horizontal"
        let scaleWithOrientation = UserDefaults.standard.bool(forKey: "ScaleWithOrientation")
        
        // Setup remote video view
        if let remoteView = await call.remoteBufferView(
            scaleMode: VideoScaleMode(string: remoteVideoScale) ?? .horizontal,
            shouldScaleWithOrientation: scaleWithOrientation
        ) {
            RemoteViews.shared.views.append(RemoteVideoViewModel(remoteVideoView: remoteView))
        }
        
       //   if let remoteView2 = await call.remoteBufferView(
       //            scaleMode: VideoScaleMode(string: remoteVideoScale) ?? .horizontal,
       //            shouldScaleWithOrientation: scaleWithOrientation
       //        ) {
       //            RemoteViews.shared.views.append(RemoteVideoViewModel(remoteVideoView: remoteView2))
       //        }
       //
       //        if let remoteView3 = await call.remoteBufferView(
       //            scaleMode: VideoScaleMode(string: remoteVideoScale) ?? .horizontal,
       //            shouldScaleWithOrientation: scaleWithOrientation
       //        ) {
       //            RemoteViews.shared.views.append(RemoteVideoViewModel(remoteVideoView: remoteView3))
       //        }
       //
       //        if let remoteView4 = await call.remoteBufferView(
       //            scaleMode: VideoScaleMode(string: remoteVideoScale) ?? .horizontal,
       //            shouldScaleWithOrientation: scaleWithOrientation
       //        ) {
       //            RemoteViews.shared.views.append(RemoteVideoViewModel(remoteVideoView: remoteView4))
       //        }
       //
        
        // Setup local video view if not already set
        if fcsdkCall?.communicationView?.previewView == nil {
            fcsdkCall?.communicationView?.previewView = await call.localBufferView(
                scaleMode: VideoScaleMode(string: localVideoScale) ?? .vertical,
                shouldScaleWithOrientation: true
            )
            
            if #available(iOS 16, *), fcsdkCall?.communicationView?.captureSession == nil {
                let session = await call.captureSession()
                fcsdkCall?.communicationView?.captureSession = session
            }
            
            if #available(iOS 15, *) {
                await fcsdkCall?.call?.feedBackgroundImage(backgroundImage, mode: virtualBackgroundMode)
            }
            
            fcsdkCall?.communicationView?.setupUI()
            fcsdkCall?.communicationView?.updateAnchors(UIDevice.current.orientation)
            fcsdkCall?.communicationView?.gestures()
        }
    }
    
    // Notifies that the call is active
    @MainActor
    func notifyInCall() async {
        await self.inCall()
        isStreaming = true
    }
    
    
    func sleep() async {
        do {
            if #available(iOS 16.0, *) {
                try await Task.sleep(until: .now + .seconds(1), clock: .suspending)
            } else {
                try await Task.sleep(nanoseconds: NSEC_PER_SEC * 1_000_000)
            }
        } catch {
            print("Sleep Error", error)
        }
    }
    
    // Handles changes in call status
    func didChange(_ status: ACBClientCallStatus, call: ACBClientCall) async {
        Task { @MainActor [weak self] in
            guard let self else { return }
            fcsdkCall?.call = call
            self.callStatus = status.rawValue
        }
        
        switch status {
        case .setup:
            break
        case .preparingBufferViews:
            await Task.detached { [weak self] in
                guard let self else { return }
                // Wait for a second if answering from CallKit
#if swift(>=6.0)
                if #available(iOS 18.0, *) {
                    await sleep()
                }
#endif
                if await isBuffer {
                    await setupBufferViews(call: call)
                }
             }.value
        case .alerting:
            _ = await Task.detached { [weak self] in
                guard let self else { return }
                await self.alerting()
            }.value
        case .ringing:
            _ = await Task.detached { [weak self] in
                guard let self else { return }
                await ringing()
            }.value
        case .mediaPending:
            break
        case .inCall:
            _ = await Task.detached { [weak self] in
                guard let self else { return }
                await notifyInCall()
            }.value
        case .timedOut:
            await setErrorMessage(message: "Call timed out")
        case .busy:
            await setErrorMessage(message: "User is busy")
        case .notFound:
            await setErrorMessage(message: "Could not find user")
        case .error:
            await setErrorMessage(message: "Unknown error")
        case .ended:
            Task { @MainActor [weak self] in
                guard let self else { return }
                await self.endCall()
            }
        @unknown default:
            break
        }
    }
    
    // Marks the call as alerting
    @MainActor
    func alerting() async {
        self.hasStartedConnecting = true
    }
    
    // Marks the call as in progress
    @MainActor
    func inCall() async {
        self.isRinging = false
        self.hasConnected = true
        self.connectDate = Date()
    }
    
    // Marks the call as ringing
    @MainActor
    func ringing() async {
        self.hasStartedConnecting = false
        self.connectingDate = Date()
        self.isRinging = true
    }
    
    // Sets an error message
    @MainActor
    func setErrorMessage(message: String) async {
        self.sendErrorMessage = true
        self.errorMessage = message
    }
    
    // Handles session interruption
    func didReceiveSessionInterruption(_ message: String, call: ACBClientCall) async {
        if message == "Session interrupted", let call = self.fcsdkCall?.call, call.status == .inCall, !self.isOnHold {
            await call.hold()
            self.isOnHold = true
        }
    }
    
    // Handles call failure
    func didReceiveCallFailure(with error: Error, call: ACBClientCall) async {
        await MainActor.run {
            self.sendErrorMessage = true
            self.errorMessage = error.localizedDescription
        }
    }
    
    // Handles dial failure
    func didReceiveDialFailure(with error: Error, call: ACBClientCall) async {
        await MainActor.run {
            self.sendErrorMessage = true
            self.errorMessage = error.localizedDescription
        }
    }
    
    // Handles call recording permission failure
    func didReceiveCallRecordingPermissionFailure(_ message: String, call: ACBClientCall?) async {
        await MainActor.run {
            self.sendErrorMessage = true
            self.errorMessage = message
        }
    }
    
    // Handles received SSRCs for audio and video
    func didReceiveSSRCs(for audioSSRCs: [String], andVideo videoSSRCs: [String], call: ACBClientCall) async {
        self.logger.info("Received SSRC information for\n AUDIO \(audioSSRCs)\n VIDEO \(videoSSRCs)")
    }
    
    // Reports inbound quality change
    func didReportInboundQualityChange(_ inboundQuality: Int, with call: ACBClientCall) async {
        self.logger.info("Call Quality: \(inboundQuality)")
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.callQuality = inboundQuality
        }
    }
    
    // Handles media change request
    func didReceiveMediaChangeRequest(_ call: ACBClientCall) async {
        let audio = call.hasRemoteAudio
        let video = call.hasRemoteVideo
        self.logger.info("HAS AUDIO \(audio)")
        self.logger.info("HAS VIDEO \(video)")
    }
    
    // Called when a remote media stream is added
    func didAddRemoteMediaStream(_ call: ACBClientCall) async {
        print("\(#function)")
    }
    
    // Called when a local media stream is added
    func didAddLocalMediaStream(_ call: ACBClientCall) async {
        print("\(#function)")
    }
}

// Extension to initialize VideoScaleMode from a string
extension VideoScaleMode {
    init?(string: String?) {
        switch string {
        case "Vertical":
            self.init(rawValue: 0)
        case "Horizontal":
            self.init(rawValue: 1)
        case "Fill":
            self.init(rawValue: 2)
        case "None":
            self.init(rawValue: 3)
        default:
            self.init(rawValue: 0) // Default to Horizontal
        }
    }
}
