//
//  CommunicationViewController+PiPDelegate.swift
//  SwiftFCSDKSample
//
//  Created by Cole M on 10/4/21.
//

import Foundation
import AVKit



internal var activeCustomPlayerViewControllers = Set<CommunicationViewController>()

extension CommunicationViewController {
    
        func setupPiP() {
    
            AVPictureInPictureController.isPictureInPictureSupported()
    
            let pipContentSource = AVPictureInPictureController.ContentSource(
                activeVideoCallSourceView: self.remoteView,
                contentViewController: self)
    
            let pipController = AVPictureInPictureController(contentSource: pipContentSource)
            pipController.canStartPictureInPictureAutomaticallyFromInline = true
            pipController.delegate = self
            pipController.startPictureInPicture()
    
        }
//        2021-10-11 09:14:19.418617+0800 SwiftFCSDKSample[5751:2158591] [Common] -[PGPictureInPictureProxy (0x10321a720) _updateAutoPIPSettingsAndNotifyRemoteObjectWithReason:] - Acquiring remote object proxy for connection <NSXPCConnection: 0x2820dcdc0> connection to service with pid 64 named com.apple.pegasus failed with error: Error Domain=NSCocoaErrorDomain Code=4099 "The connection to service with pid 64 named com.apple.pegasus was invalidated from this process." UserInfo={NSDebugDescription=The connection to service with pid 64 named com.apple.pegasus was invalidated from this process.}
//    
    
        func showPip(show: Bool) {
            setupPiP()
        }
}



// MARK: - AVPictureInPictureControllerDelegate
extension CommunicationViewController: AVPictureInPictureControllerDelegate {
    public func pictureInPictureControllerWillStartPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) {
        activeCustomPlayerViewControllers.insert(self)
    }
    
    public func pictureInPictureControllerDidStartPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) {
        dismiss(animated: true, completion: nil)
    }
    
    public func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        failedToStartPictureInPictureWithError error: Error
    ) {
        activeCustomPlayerViewControllers.remove(self)
    }
    
    public func pictureInPictureControllerDidStopPictureInPicture(
        _ pictureInPictureController: AVPictureInPictureController
    ) {
        activeCustomPlayerViewControllers.remove(self)
    }
    
    public func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void
    ) {
        delegate?.communicationViewController(
            self,
            restoreUserInterfaceForPictureInPictureStopWithCompletionHandler: completionHandler)
    }
}
