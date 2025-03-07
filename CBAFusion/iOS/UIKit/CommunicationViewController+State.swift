//
//  CommunicationViewController+State.swift
//  CBAFusion
//
//  Created by Cole M on 2/1/22.
//

import UIKit

extension CommunicationViewController {
    
    /// An enumeration representing the various states of a call.
    enum CallState {
        case setup                // Initial setup state
        case hasStartedConnecting  // Call is in the process of connecting
        case isRinging            // Call is ringing
        case hasConnected         // Call has been successfully connected
        case isOutgoing           // Call is outgoing
        case hasEnded             // Call has ended
        case cameraFront          // Front camera is active
        case cameraBack           // Back camera is active
        case hold                 // Call is on hold
        case resume               // Call is resumed from hold
        case muteAudio            // Audio is muted
        case resumeAudio          // Audio is unmuted
        case muteVideo            // Video is muted
        case resumeVideo          // Video is unmuted
    }
    
    /// Updates the UI and state of the communication view based on the current call state.
    /// - Parameter state: The current state of the call.
    @MainActor
    func currentState(state: CallState) async {
        switch state {
        case .setup:
            // No action needed for setup state
            break
            
        case .hasStartedConnecting:
            // Update UI to show the remote address and connecting state
            communicationView.numberLabel.text = self.fcsdkCall?.call?.remoteAddress
            communicationView.connectingUI(isRinging: false)
            
        case .isRinging:
            // Update UI to show the remote address and ringing state
            communicationView.numberLabel.text = self.fcsdkCall?.call?.remoteAddress
            communicationView.connectingUI(isRinging: true)
            
        case .hasConnected:
            // Remove connecting UI and refresh the view
            communicationView.removeConnectingUI()
            await performQuery()
            
        case .isOutgoing:
            // No action needed for outgoing state
            break
            
        case .hold:
            // Put the call on hold
            do {
                try await self.onHoldView()
            } catch {
                self.logger.error("Error putting call on hold: \(error)")
            }
            
        case .resume:
            // Resume the call from hold
            do {
                try await self.removeOnHold()
            } catch {
                self.logger.error("Error resuming call from hold: \(error)")
            }
            
        case .hasEnded:
            // Clean up the UI after the call has ended
            communicationView.breakDownView()
            communicationView.removeConnectingUI()
            await self.currentState(state: .setup)
            
        case .muteVideo:
            // Mute the video
            do {
                try await self.muteVideo(isMute: true)
            } catch {
                self.logger.error("Error muting video: \(error)")
            }
            
        case .resumeVideo:
            // Unmute the video
            do {
                try await self.muteVideo(isMute: false)
            } catch {
                self.logger.error("Error unmuting video: \(error)")
            }
            
        case .muteAudio:
            // Mute the audio
            do {
                try await self.muteAudio(isMute: true)
            } catch {
                self.logger.error("Error muting audio: \(error)")
            }
            
        case .resumeAudio:
            // Unmute the audio
            do {
                try await self.muteAudio(isMute: false)
            } catch {
                self.logger.error("Error unmuting audio: \(error)")
            }
            
        case .cameraFront:
            // Switch to the front camera
            await self.flipCamera(showFrontCamera: false)
            
        case .cameraBack:
            // Switch to the back camera
            await self.flipCamera(showFrontCamera: true)
        }
    }
}
