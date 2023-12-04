//
//  CommunicationViewController+PiPDelegate.swift
//  CBAFusion
//
//  Created by Cole M on 10/4/21.
//

import Foundation
import AVKit
import Logging
import FCSDKiOS

extension CommunicationViewController: AVPictureInPictureControllerDelegate, AVPictureInPictureSampleBufferPlaybackDelegate {
    
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, setPlaying playing: Bool) {}
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, didTransitionToRenderSize newRenderSize: CMVideoDimensions) {}
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, skipByInterval skipInterval: CMTime) async {}
    func pictureInPictureControllerTimeRangeForPlayback(_ pictureInPictureController: AVPictureInPictureController) -> CMTimeRange {
        return CMTimeRange(start: .zero, duration: .positiveInfinity)
    }
    func pictureInPictureControllerIsPlaybackPaused(_ pictureInPictureController: AVPictureInPictureController) -> Bool {
        PipStateObject.shared.pip = false
        PipStateObject.shared.pipClickedID = UUID()
        return false
    }
    
    @available(iOS 15.0, *)
    func showPip(show: Bool) async {
        if show {
            if AVPictureInPictureController.isPictureInPictureSupported() {
                if #available(iOS 16.0, *) {
                    let communicationView = self.view as! CommunicationView
                    guard let captureSession = communicationView.captureSession else { return }
                    if captureSession.isMultitaskingCameraAccessSupported {
                        let remoteVideoScale = UserDefaults.standard.integer(forKey: "remoteVideoScale")
                        let scaleWithOrientation = UserDefaults.standard.bool(forKey: "scaleWithOrientation")
                        
                        guard let remotePipView = await FCSDKCallService.shared.fcsdkCall?.call?.remoteBufferView(
                            scaleMode: VideoScaleMode(rawValue: remoteVideoScale) ?? .horizontal,
                            shouldScaleWithOrientation: scaleWithOrientation
                        ) else { return }
                        
                        let pipVideoCallViewController = AVPictureInPictureVideoCallViewController()
                        var size: CGSize?
                        switch UIDevice.current.orientation {
                        case .unknown, .faceUp, .faceDown:
                            if UIScreen.main.bounds.width < UIScreen.main.bounds.height {
                                let result = communicationView.setSize(isLandscape: false, minimize: false)
                                size = CGSize(width: result.0, height: result.1)
                            } else {
                                let result = communicationView.setSize(isLandscape: true, minimize: false)
                                size = CGSize(width: result.0, height: result.1)
                            }
                        case .portrait, .portraitUpsideDown:
                            let result = communicationView.setSize(isLandscape: false, minimize: false)
                            size = CGSize(width: result.0, height: result.1)
                        case .landscapeRight, .landscapeLeft:
                            let result = communicationView.setSize(isLandscape: true, minimize: false)
                            size = CGSize(width: result.0, height: result.1)
                        default:
                            let result = communicationView.setSize(isLandscape: true, minimize: false)
                            size = CGSize(width: result.0, height: result.1)
                        }
                        pipVideoCallViewController.preferredContentSize = size!
                        pipVideoCallViewController.view.addSubview(remotePipView)
                        
                        remotePipView.anchors(
                            top: pipVideoCallViewController.view.topAnchor,
                            leading: pipVideoCallViewController.view.leadingAnchor,
                            bottom: pipVideoCallViewController.view.bottomAnchor,
                            trailing: pipVideoCallViewController.view.trailingAnchor
                            
                        )
                        
                        let pipContentSource = AVPictureInPictureController.ContentSource(
                            activeVideoCallSourceView: view,
                            contentViewController: pipVideoCallViewController
                        )
                        
                        let pipController = AVPictureInPictureController(contentSource: pipContentSource)
                        pipController.canStartPictureInPictureAutomaticallyFromInline = true
                        pipController.delegate = self
                        self.pipController = pipController
                        await self.fcsdkCallService.fcsdkCall?.call?.setPipController(pipController)
                    }
                }
                pipController?.startPictureInPicture()
            } else {
                self.logger.info("PIP not Supported")
            }
        } else {
            if #available(iOS 16.0, *) {
                let communicationView = self.view as! CommunicationView
                guard let captureSession = communicationView.captureSession else { return }
                if captureSession.isMultitaskingCameraAccessSupported {
                    pipController?.stopPictureInPicture()
                    self.pipController = nil
                }
            } else {
                pipController?.stopPictureInPicture()
            }
        }
    }
    
    
    func setUpPip(_ communicationView: CommunicationView) async {
        guard let remoteView = communicationView.remoteView else { return }
        if #available(iOS 16.0, *) {
            guard let captureSession = communicationView.captureSession else { return }
            if captureSession.isMultitaskingCameraAccessSupported {
                //We set up when pip is hit due to resource allocation
            } else {
                //If we are iOS 16 and we are not an m chip
                guard let sourceLayer = communicationView.pipLayer else { return }
                let source = AVPictureInPictureController.ContentSource(sampleBufferDisplayLayer: sourceLayer, playbackDelegate: self)
                
                pipController = AVPictureInPictureController(contentSource: source)
                guard let pipController = self.pipController else { return }
                pipController.canStartPictureInPictureAutomaticallyFromInline = true
                pipController.delegate = self
                await self.fcsdkCallService.fcsdkCall?.call?.setPipController(pipController)
            }
        } else if #available(iOS 15.0, *) {
            //If we are iOS 15
            let sourceLayer = remoteView.layer as! AVSampleBufferDisplayLayer
            let source = AVPictureInPictureController.ContentSource(sampleBufferDisplayLayer: sourceLayer, playbackDelegate: self)
            guard var pipController = self.pipController else { return }
            pipController = AVPictureInPictureController(contentSource: source)
            pipController.canStartPictureInPictureAutomaticallyFromInline = true
            pipController.delegate = self
            await self.fcsdkCallService.fcsdkCall?.call?.setPipController(pipController)
        }
    }
    
    func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
    }
    func pictureInPictureControllerWillStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        PipStateObject.shared.pip = false
        PipStateObject.shared.pipClickedID = UUID()
    }
    
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, failedToStartPictureInPictureWithError error: Error) {
        logger.error("\(error)")
    }
    func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
    }
    
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController) async -> Bool {
        return true
    }
    func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
    }
}
