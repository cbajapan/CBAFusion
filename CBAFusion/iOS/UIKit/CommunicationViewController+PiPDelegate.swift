//
//  CommunicationViewController+PiPDelegate.swift
//  CBAFusion
//
//  Created by Cole M on 10/4/21.
//

import Foundation
import AVKit
import Logging

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
        guard let pipController = self.pipController else { return }
        if show {
            if AVPictureInPictureController.isPictureInPictureSupported() {
                pipController.startPictureInPicture()
            } else {
                self.logger.info("PIP not Supported")
            }
        } else {
            pipController.stopPictureInPicture()
        }
    }
    
    
    func setUpPip(_ communicationView: CommunicationView) async {
//        let audioSession = AVAudioSession.sharedInstance()
//
//        do {
//            try audioSession.setCategory(.playback, mode: .moviePlayback)
//        } catch {
//            print("Setting category to AVAudioSessionCategoryPlayback failed.", error)
//        }
        guard let remoteView = communicationView.remoteView else { return }
        if #available(iOS 16.0, *) {
            guard let captureSession = communicationView.captureSession else { return }

            if captureSession.isMultitaskingCameraAccessSupported {
                let pipVideoCallViewController = AVPictureInPictureVideoCallViewController()
                pipVideoCallViewController.preferredContentSize = CGSize(width: 1080, height: 1920)
                pipVideoCallViewController.view.addSubview(remoteView)
                
                let source = AVPictureInPictureController.ContentSource(
                    activeVideoCallSourceView: remoteView,
                    contentViewController: pipVideoCallViewController)
                
                pipController = AVPictureInPictureController(contentSource: source)
                guard let pipController = self.pipController else { return }
                pipController.canStartPictureInPictureAutomaticallyFromInline = true
                pipController.delegate = self
                await self.fcsdkCallService.fcsdkCall?.call?.setPipController(pipController)
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
