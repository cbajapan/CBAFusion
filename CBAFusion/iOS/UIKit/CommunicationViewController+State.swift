//
//  CommunicationViewController+State.swift
//  CBAFusion
//
//  Created by Cole M on 2/1/22.
//

import UIKit


extension CommunicationViewController {
    
    enum CallState {
        case setup
        case hasStartedConnecting
        case isRinging
        case hasConnected
        case isOutgoing
        case hasEnded
        case cameraFront
        case cameraBack
        case hold
        case resume
        case muteAudio
        case resumeAudio
        case muteVideo
        case resumeVideo
    }
    
    
    @MainActor
    func currentState(state: CallState) async {
        let communicationView = self.view as! CommunicationView
        switch state {
        case .setup:
            break
        case .hasStartedConnecting:
            communicationView.numberLabel.text = self.fcsdkCall?.call?.remoteAddress
            communicationView.connectingUI(isRinging: false)
        case .isRinging:
            communicationView.numberLabel.text = self.fcsdkCall?.call?.remoteAddress
            communicationView.connectingUI(isRinging: true)
        case .hasConnected:
            communicationView.removeConnectingUI()
        case .isOutgoing:
            break
        case .hold:
            do {
                try await self.onHoldView()
            } catch {
                self.logger.error("\(error)")
            }
        case .resume:
            do {
                try await self.removeOnHold()
            } catch {
                self.logger.error("\(error)")
            }
        case .hasEnded:
            communicationView.breakDownView()
            communicationView.removeConnectingUI()
            await self.currentState(state: .setup)
        case .muteVideo:
            do {
                try await self.muteVideo(isMute: true)
            } catch {
                self.logger.error("\(error)")
            }
        case .resumeVideo:
            do {
                try await self.muteVideo(isMute: false)
            } catch {
                self.logger.error("\(error)")
            }
        case .muteAudio:
            do {
                try await self.muteAudio(isMute: true)
            } catch {
                self.logger.error("\(error)")
            }
        case .resumeAudio:
            do {
                try await self.muteAudio(isMute: false)
            } catch {
                self.logger.error("\(error)")
            }
        case .cameraFront:
            await self.flipCamera(showFrontCamera: false)
        case .cameraBack:
            await self.flipCamera(showFrontCamera: true)
        }
    }
}
