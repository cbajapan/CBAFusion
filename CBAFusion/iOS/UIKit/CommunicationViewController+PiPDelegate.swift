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
    
    @available(iOS 15, *)
    func showPip(show: Bool) async {
        if show {
            if AVPictureInPictureController.isPictureInPictureSupported() {
                if #available(iOS 16.0, *) {
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
                        await self.fcsdkCallService.fcsdkCall?.call?.setPipController(pipController)
                        self.pipController = pipController
                    }
                }
                pipController?.startPictureInPicture()
            } else {
                self.logger.info("PIP not Supported")
            }
        } else {
            if #available(iOS 16.0, *) {
                guard let captureSession = communicationView.captureSession else { return }
                if captureSession.isMultitaskingCameraAccessSupported {
                    pipController?.stopPictureInPicture()
                    self.pipController = nil
                    await self.fcsdkCallService.fcsdkCall?.call?.setPipController(nil)
                } else {
                    pipController?.stopPictureInPicture()
                }
            } else {
                pipController?.stopPictureInPicture()
            }
        }
    }
    
    
    func setUpPip(_ communicationView: CommunicationView) async {
        guard let remoteView = RemoteViews.shared.views.first?.remoteVideoView else { return }
        guard let captureSession = communicationView.captureSession else { return }
        if #available(iOS 16.0, *), captureSession.isMultitaskingCameraAccessSupported {
            //We set up when pip is hit due to resource allocation
            print("SUPPORTS MultitaskingCameraAccessSupported")
        } else if #available(iOS 15.0, *) {
            //If we are iOS 16 and we are not an m chip
            guard let sourceLayer = remoteView.sampleBufferLayer else { return }
            //            guard let sourceLayer = remoteView.layer as? AVSampleBufferDisplayLayer else { return }
            let source = AVPictureInPictureController.ContentSource(sampleBufferDisplayLayer: sourceLayer, playbackDelegate: self)
            
            let pipController = AVPictureInPictureController(contentSource: source)
            pipController.canStartPictureInPictureAutomaticallyFromInline = true
            pipController.delegate = self
            await self.fcsdkCallService.fcsdkCall?.call?.setPipController(pipController)
            self.pipController = pipController
        }
    }
    
    func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        print("STARTED_PIP")
    }
    func pictureInPictureControllerWillStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        PipStateObject.shared.pip = false
        PipStateObject.shared.pipClickedID = UUID()
    }
    
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, failedToStartPictureInPictureWithError error: Error) {
        logger.error("FAILED_PIP_\(error)")
    }
    func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
    }
    
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController) async -> Bool {
        return true
    }
    func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        print("WILL_START_PIP")
    }
}
