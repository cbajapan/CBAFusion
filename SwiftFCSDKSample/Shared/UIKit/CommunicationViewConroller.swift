//
//  CommunicationViewConroller.swift
//  SwiftFCSDKSample
//
//  Created by Cole M on 9/1/21.
//

import Foundation
import UIKit
import ACBClientSDK
import AVKit

/// The Set of custom player controllers currently using or transitioning out of PiP
private var activeCustomPlayerViewControllers = Set<CommunicationViewController>()

class CommunicationViewController: UIViewController {

    var panGesture = UIPanGestureRecognizer()
    weak var delegate: CommunicationViewControllerDelegate?
    var playerView = PlayerView()
    var localView: ACBView = {
        let lv = ACBView()
        lv.layer.cornerRadius = 8
        return lv
    }()
    var pipController: AVPictureInPictureController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(playerView)
        view.layer.addSublayer(playerView.playerLayer)
        pipController = AVPictureInPictureController(playerLayer: playerView.playerLayer)
        pipController.delegate = self
        playerView.player = AVPlayer(url: URL(string: "https://cartisim.sfo2.digitaloceanspaces.com/CartisimVideos/CartisimLandingVideo.mov")!)
        
        anchors()
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(draggedView(_:)))
        self.localView.isUserInteractionEnabled = true
        self.localView.addGestureRecognizer(panGesture)
    }
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerView.playerLayer.frame = view.bounds
    }

    func anchors() {
        self.localView.translatesAutoresizingMaskIntoConstraints = true
        self.view.addSubview(self.localView)
        self.localView.greaterThanHeightAnchors(top: nil, leading: nil, bottom: view.bottomAnchor, trailing: view.trailingAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 100, paddingRight: 8, width: view.frame.width / 2, height: view.frame.height / 4)
        self.localView.backgroundColor = UIColor.darkGray
    }
    
    @objc func draggedView(_ sender:UIPanGestureRecognizer){
        self.view.bringSubviewToFront(localView)
        let translation = sender.translation(in: self.view)
        localView.center = CGPoint(x: localView.center.x + translation.x, y: localView.center.y + translation.y)
        sender.setTranslation(CGPoint.zero, in: self.view)
    }
    
    func showPip(show: Bool) {
        if show {
            pipController?.startPictureInPicture()
        } else {
            pipController?.stopPictureInPicture()
        }
    }
}

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

// MARK: - AVPlayerViewControllerDelegate
//extension CommunicationViewController: AVPlayerViewControllerDelegate {
//    @objc func playerViewControllerShouldDismiss(_ playerViewController: AVPlayerViewController) -> Bool {
//      if let presentedViewController = presentedViewController as? AVPlayerViewController,
//        presentedViewController == playerViewController {
//        return true
//      }
//      return false
//    }
//
//    @objc func playerViewControllerShouldAutomaticallyDismissAtPictureInPictureStart(_ playerViewController: AVPlayerViewController) -> Bool {
//      // Dismiss the controller when PiP starts so that the user is returned to the item selection screen.
//      return true
//    }
//
//    @objc func playerViewController(
//      _ playerViewController: AVPlayerViewController,
//      restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void
//    ) {
//      restore(communicationViewController: playerViewController, completionHandler: completionHandler)
//    }
//}


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
