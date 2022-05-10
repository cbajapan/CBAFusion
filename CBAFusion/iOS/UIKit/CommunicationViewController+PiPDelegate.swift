//
//  CommunicationViewController+PiPDelegate.swift
//  CBAFusion
//
//  Created by Cole M on 10/4/21.
//

import Foundation
import AVKit

//TODO: -
extension CommunicationViewController: AVPictureInPictureControllerDelegate {
//, AVPictureInPictureSampleBufferPlaybackDelegate {
    
//    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, setPlaying playing: Bool) {
//
//    }
//
//    func pictureInPictureControllerTimeRangeForPlayback(_ pictureInPictureController: AVPictureInPictureController) -> CMTimeRange {
//        return CMTimeRange(start: .indefinite, duration: .indefinite)
//    }
//
//    func pictureInPictureControllerIsPlaybackPaused(_ pictureInPictureController: AVPictureInPictureController) -> Bool {
//        return false
//    }
//
//    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, didTransitionToRenderSize newRenderSize: CMVideoDimensions) {
//
//    }
//
//    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, skipByInterval skipInterval: CMTime, completion completionHandler: @escaping () -> Void) {
//
//    }
//
//    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, skipByInterval skipInterval: CMTime) async {
//
//    }
//
    func showPip(show: Bool) async {
        if show {
            let suppported = AVPictureInPictureController.isPictureInPictureSupported()
            if suppported {
                let communicationView = self.view as! CommunicationView
                guard let bufferView = await self.fcsdkCallService.fcsdkCall?.call?.remoteBufferView() else { return }
                communicationView.remoteView = bufferView
//                let sourceLayer = self.remoteBufferView?.sampleBufferDisplayLayer
                let pipVideoCallViewController = AVPictureInPictureVideoCallViewController()
                pipVideoCallViewController.preferredContentSize = CGSize(width: 1080, height: 1920)
                pipVideoCallViewController.view.addSubview(communicationView.remoteView)

//                let source = AVPictureInPictureController.ContentSource(sampleBufferDisplayLayer: sourceLayer!, playbackDelegate: self)
                let source = AVPictureInPictureController.ContentSource(
                    activeVideoCallSourceView: communicationView.remoteView,
                    contentViewController: pipVideoCallViewController)

                let pipController = AVPictureInPictureController(contentSource: source)
                pipController.canStartPictureInPictureAutomaticallyFromInline = true
                pipController.delegate = self
                pipController.startPictureInPicture()

            } else {
                self.logger.info("PIP not Supported")
            }
        } else {
            await self.fcsdkCallService.fcsdkCall?.call?.removeBufferView()
        }
    }
    
    
    func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
//        print("Source", pictureInPictureController.contentSource)
    }
    
    
    func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
//        print("Source", pictureInPictureController.contentSource)
    }
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, failedToStartPictureInPictureWithError error: Error) {
        print("failedToStartPictureInPictureWithError", error)
    }
    
    func pictureInPictureControllerWillStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        print("Will stop")
    }
    
    func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        print("Did stop")
    }
    
    
    
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController) async -> Bool {
        print("Async - restoreUserInterfaceForPictureInPictureStopWithCompletionHandler")
        return true
    }
    
}
