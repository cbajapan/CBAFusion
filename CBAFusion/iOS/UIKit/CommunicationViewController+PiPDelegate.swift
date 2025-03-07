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


/// Extension for `CommunicationViewController` to handle Picture in Picture (PiP) functionality.
/// This extension conforms to `AVPictureInPictureControllerDelegate` and `AVPictureInPictureSampleBufferPlaybackDelegate`.
extension CommunicationViewController: @preconcurrency AVPictureInPictureControllerDelegate, @preconcurrency AVPictureInPictureSampleBufferPlaybackDelegate {
    
    /// Shows or hides the Picture in Picture (PiP) interface.
    /// - Parameter show: A Boolean indicating whether to show or hide PiP.
    @available(iOS 15, *)
    func showPip(show: Bool) async {
        guard AVPictureInPictureController.isPictureInPictureSupported() else {
            self.logger.info("PIP not Supported")
            return
        }
        
        guard let captureSession = communicationView.captureSession else { return }
        guard let remoteView = RemoteViews.shared.views.last?.remoteVideoView else { return }
        
        if show {
            if #available(iOS 16.0, *), captureSession.isMultitaskingCameraAccessSupported  {
                self.logger.info("Multitasking Camera is Supported")
                
                let size = communicationView.determineSize(for: UIDevice.current.orientation, minimize: false)
                let pipVideoCallViewController = AVPictureInPictureVideoCallViewController(remoteView, preferredContentSize: CGSize(width: size.0, height: size.1))
                let contentSource = AVPictureInPictureController.ContentSource(activeVideoCallSourceView: view, contentViewController: pipVideoCallViewController)
                let pipController = AVPictureInPictureController(contentSource: contentSource)
                await self.fcsdkCallService.fcsdkCall!.call!.setPipController(pipController)
                pipController.delegate = self
                pipController.canStartPictureInPictureAutomaticallyFromInline = true
                pipController.startPictureInPicture()
                self.pipController = pipController
            } else {
                self.logger.info("Multitasking Camera is not Supported")
            guard let sourceLayer = await self.fcsdkCallService.fcsdkCall?.call?.getSampleLayers().first else { return }
                if pipController == nil {
                    let source = AVPictureInPictureController.ContentSource(sampleBufferDisplayLayer: sourceLayer, playbackDelegate: self)
                    let pipController = AVPictureInPictureController(contentSource: source)
                    pipController.canStartPictureInPictureAutomaticallyFromInline = true
                    await self.fcsdkCallService.fcsdkCall?.call?.setPipController(pipController)
                    pipController.delegate = self
                    pipController.canStartPictureInPictureAutomaticallyFromInline = true
                    pipController.startPictureInPicture()
                    self.pipController = pipController
                }
            }
        } else {
            // Stop Picture in Picture
            pipController?.stopPictureInPicture()
        }
    }
    
    /// Called when Picture in Picture has started successfully.
    /// - Parameter pictureInPictureController: The PiP controller.
    func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        // Handle PiP started
    }
    
    /// Called when Picture in Picture is about to stop.
    /// - Parameter pictureInPictureController: The PiP controller.
    func pictureInPictureControllerWillStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            PipStateObject.shared.pip = false
            PipStateObject.shared.pipClickedID = UUID()
            
            if #available(iOS 16.0, *), let captureSession = communicationView.captureSession, captureSession.isMultitaskingCameraAccessSupported {
                await self.performQuery()
            }
        }
    }
    
    /// Called when Picture in Picture fails to start.
    /// - Parameters:
    ///   - pictureInPictureController: The PiP controller.
    ///   - error: The error that occurred.
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, failedToStartPictureInPictureWithError error: Error) {
        self.logger.error("Failed to start PiP: \(error.localizedDescription)")
    }
    
    /// Called when Picture in Picture has stopped.
    /// - Parameter pictureInPictureController: The PiP controller.
    func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        // Handle PiP stopped
    }
    
    /// Called to determine if Picture in Picture should start.
    /// - Parameter pictureInPictureController: The PiP controller.
    /// - Returns: A Boolean indicating whether PiP should start.
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController) async -> Bool {
        return true
    }
    
    /// Called when Picture in Picture is about to start.
    /// - Parameter pictureInPictureController: The PiP controller.
    func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        // Handle PiP will start
    }
    
    
    /// Called when the PiP controller's playing state changes.
    /// - Parameters:
    ///   - pictureInPictureController: The PiP controller.
    ///   - playing: A Boolean indicating whether playback is currently active.
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, setPlaying playing: Bool) {}
    
    /// Called when the PiP controller transitions to a new render size.
    /// - Parameters:
    ///   - pictureInPictureController: The PiP controller.
    ///   - newRenderSize: The new render size for the PiP window.
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, didTransitionToRenderSize newRenderSize: CMVideoDimensions) {}
    
    /// Called to skip playback by a specified interval.
    /// - Parameters:
    ///   - pictureInPictureController: The PiP controller.
    ///   - skipInterval: The time interval to skip.
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, skipByInterval skipInterval: CMTime) async {}
    
    /// Provides the time range for playback in the PiP controller.
    /// - Parameter pictureInPictureController: The PiP controller.
    /// - Returns: A `CMTimeRange` representing the playback time range.
    func pictureInPictureControllerTimeRangeForPlayback(_ pictureInPictureController: AVPictureInPictureController) -> CMTimeRange {
        return CMTimeRange(start: .zero, duration: .positiveInfinity)
    }
    
    /// Indicates whether playback is paused in the PiP controller.
    /// - Parameter pictureInPictureController: The PiP controller.
    /// - Returns: A Boolean indicating if playback is paused.
    func pictureInPictureControllerIsPlaybackPaused(_ pictureInPictureController: AVPictureInPictureController) -> Bool {
        return false
    }
    
    
}

@available(iOS 15.0, *)
extension AVPictureInPictureVideoCallViewController {
    
    convenience init(_ pipView: UIView, preferredContentSize: CGSize) {
        
        // Initialize.
        self.init()
        
        // Set the preferredContentSize.
        self.preferredContentSize = preferredContentSize
        
        // Configure the PreviewView.
        pipView.translatesAutoresizingMaskIntoConstraints = false
        pipView.frame = self.view.frame
        self.view.addSubview(pipView)
        pipView.anchors(
            top: view.topAnchor,
            leading: view.leadingAnchor,
            bottom: view.bottomAnchor,
            trailing: view.trailingAnchor
        )
    }
    
}
