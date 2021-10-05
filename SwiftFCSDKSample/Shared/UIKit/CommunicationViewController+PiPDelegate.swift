//
//  CommunicationViewController+PiPDelegate.swift
//  SwiftFCSDKSample
//
//  Created by Cole M on 10/4/21.
//

import Foundation
import AVKit


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
