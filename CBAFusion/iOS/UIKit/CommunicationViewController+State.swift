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
            communicationView.setupUI()
            communicationView.anchors()
        case .isOutgoing:
            break
        case .hold:
            do {
                try self.onHoldView()
            } catch {
                self.logger.error("\(error)")
            }
        case .resume:
            do {
                try self.removeOnHold()
            } catch {
                self.logger.error("\(error)")
            }
        case .hasEnded:
            await self.fcsdkCallService.fcsdkCall?.call?.removeBufferView()
            communicationView.breakDownView()
            communicationView.removeConnectingUI()
            await self.currentState(state: .setup)
        case .muteVideo:
            do {
                try self.muteVideo(isMute: true)
            } catch {
                self.logger.error("\(error)")
            }
        case .resumeVideo:
            do {
                try self.muteVideo(isMute: false)
            } catch {
                self.logger.error("\(error)")
            }
        case .muteAudio:
            do {
                try self.muteAudio(isMute: true)
            } catch {
                self.logger.error("\(error)")
            }
        case .resumeAudio:
            do {
                try self.muteAudio(isMute: false)
            } catch {
                self.logger.error("\(error)")
            }
        case .cameraFront:
            self.flipCamera(show: true)
        case .cameraBack:
            self.flipCamera(show: false)
        }
    }
}
