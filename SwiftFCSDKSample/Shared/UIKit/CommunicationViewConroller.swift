//
//  CommunicationViewConroller.swift
//  SwiftFCSDKSample
//
//  Created by Cole M on 9/1/21.
//

import Foundation
import UIKit
import SwiftFCSDK
import AVKit

/// The Set of custom player controllers currently using or transitioning out of PiP
private var activeCustomPlayerViewControllers = Set<CommunicationViewController>()

class CommunicationViewController: UIViewController {

    weak var delegate: CommunicationViewControllerDelegate?
    var playerView = PlayerView()
    var localView: ACBView = {
        let lv = ACBView()
        lv.layer.cornerRadius = 8
        return lv
    }()
    var pipController: AVPictureInPictureController!
    var acbuc: ACBUC
    var call: FCSDKCall
    var audioAllowed: Bool = false
    var videoAllowed: Bool = false
    var currentCamera: AVCaptureDevice.Position!
    
    init(acbuc: ACBUC, call: FCSDKCall) {
        self.acbuc = acbuc
        self.call = call
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(playerView)
        view.layer.addSublayer(playerView.playerLayer)
        anchors()
        
        try? self.acbuc.clientPhone?.setPreviewView(self.localView)
        self.call.requestMicrophoneAndCameraPermissionFromAppSettings()
        self.audioAllowed = AppSettings.perferredAudioDirection() == .receiveOnly || AppSettings.perferredAudioDirection() == .sendAndReceive
        self.videoAllowed = AppSettings.perferredVideoDirection() == .receiveOnly || AppSettings.perferredVideoDirection() == .sendAndReceive

        try? self.configureResolutionOptions()
        try? self.configureFramerateOptions()
        
//        self.playerView.isHidden = true
//        self.localView.isHidden = true
        
        // For SettingsSheet
//        self.isHeld = false;
//        self.autoAnswerSwitch = AppSettings.shouldAutoAnswer()
        
        self.currentCamera = AVCaptureDevice.Position.front
        
        

        pipController = AVPictureInPictureController(playerLayer: playerView.playerLayer)
        pipController.delegate = self
        playerView.player = AVPlayer(url: URL(string: "https://cartisim.sfo2.digitaloceanspaces.com/CartisimVideos/CartisimLandingVideo.mov")!)
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(draggedLocalView(_:)))
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapLocalView(_:)))
        self.localView.addGestureRecognizer(tapGesture)
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
    
    func showPip(show: Bool) {
        if show {
            pipController?.startPictureInPicture()
        } else {
            pipController?.stopPictureInPicture()
        }
    }
    
    
    // Gestures
    @objc func draggedLocalView(_ sender:UIPanGestureRecognizer){
        self.view.bringSubviewToFront(localView)
        let translation = sender.translation(in: self.view)
        localView.center = CGPoint(x: localView.center.x + translation.x, y: localView.center.y + translation.y)
        sender.setTranslation(CGPoint.zero, in: self.view)
    }

    @objc func tapLocalView(_ sender: UITapGestureRecognizer) {
        self.currentCamera = self.currentCamera == AVCaptureDevice.Position.back ? AVCaptureDevice.Position.front : AVCaptureDevice.Position.back
        self.acbuc.clientPhone?.setCamera(self.currentCamera)
    }
    
    /// Configurations for Capture
    func configureResolutionOptions() throws {
        var show720Res = false
        var show480Res = false
        guard let recCaptureSettings = self.acbuc.clientPhone?.recommendedCaptureSettings() else { throw OurErrors.nilResolution }

        for captureSetting in recCaptureSettings {
            guard let captureSetting = captureSetting as? ACBVideoCaptureSetting else {
                continue
            }
            if captureSetting.resolution == .resolution1280x720 {
                show720Res = true
                show480Res = true
            } else if captureSetting.resolution == .resolution640x480 {
                show480Res = true
            }
        }

        if !show720Res {
            // Pass value back to swiftUI Settings Sheet
//            resolutionControl.setEnabled(false, forSegmentAt: 3)
        }
        if !show480Res {
            // Pass value back to swiftUI Settings Sheet
//            resolutionControl.setEnabled(false, forSegmentAt: 2)
        }
    }
    
    func configureFramerateOptions() throws {
        //disable 30fps unless one of the recommended settings allows it
        
        // Pass value back to swiftUI Settings Sheet
//        framerateControl.setEnabled(false, forSegmentAt: 1)
//        framerateControl.selectedSegmentIndex = 0
        guard let recCaptureSettings = acbuc.clientPhone?.recommendedCaptureSettings() else { throw OurErrors.nilFrameRate }
        for captureSetting in recCaptureSettings {
            guard let captureSetting = captureSetting as? ACBVideoCaptureSetting else {
                continue
            }
            if captureSetting.frameRate > 20 {
                
                // Pass value back to swiftUI Settings Sheet
//                framerateControl.setEnabled(true, forSegmentAt: 1)
//                framerateControl.selectedSegmentIndex = 1
                break
            }
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
