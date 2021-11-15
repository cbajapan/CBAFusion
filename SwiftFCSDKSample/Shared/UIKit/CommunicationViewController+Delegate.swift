//
//  CommunicationViewController+Delegate.swift
//  SwiftFCSDKSample
//
//  Created by Cole M on 10/4/21.
//

import UIKit


// MARK: - CommunicationViewControllerDelegate
extension CommunicationViewController: CommunicationViewControllerDelegate {

    func communicationViewControllerShouldAutomaticallyDismissAtPictureInPictureStart(_ communicationViewController: CommunicationViewController) -> Bool {
        return true
    }

    func communicationViewController(_ communicationViewController: CommunicationViewController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
        restore(communicationViewController: communicationViewController, completionHandler: completionHandler)
    }

    func restore(communicationViewController: UIViewController, completionHandler: @escaping (Bool) -> Void) {
      if let presentedViewController = presentedViewController {
        presentedViewController.dismiss(animated: false) { [weak self] in
          self?.present(communicationViewController, animated: false) {
            completionHandler(true)
          }
        }
      } else {
        present(communicationViewController, animated: false) {
          completionHandler(true)
        }
      }
    }

}
