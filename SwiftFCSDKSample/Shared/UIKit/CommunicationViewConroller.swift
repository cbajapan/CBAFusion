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


class CommunicationViewController: AVPlayerViewController {
    
    
    var panGesture = UIPanGestureRecognizer()
    
    var remoteView: UIView = {
        let rv = UIView()
        return rv
    }()
    
    var playerView = PlayerView()
    
    var localView: ACBView = {
        let lv = ACBView()
        lv.layer.cornerRadius = 8
        return lv
    }()
    
    
    init() {
        super.init(nibName: "", bundle: nil)
        self.player = self.playerView.player
        self.showsPlaybackControls = false
        self.allowsPictureInPicturePlayback = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        anchors()
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(draggedView(_:)))
        self.localView.isUserInteractionEnabled = true
        self.localView.addGestureRecognizer(panGesture)
    }
    
    func anchors() {
//        self.remoteView.translatesAutoresizingMaskIntoConstraints = true
        self.localView.translatesAutoresizingMaskIntoConstraints = true
//        self.view.addSubview(self.remoteView)
//        self.playerView.addSubview(self.localView)
        self.contentOverlayView?.addSubview(self.localView)
//        self.remoteView.greaterThanHeightAnchors(top: view.topAnchor, leading: view.leadingAnchor, bottom: view.bottomAnchor, trailing: view.trailingAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
//        self.localView.greaterThanHeightAnchors(top: nil, leading: nil, bottom: playerView.bottomAnchor, trailing: playerView.trailingAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 100, paddingRight: 8, width: playerView.frame.width / 2, height: playerView.frame.height / 4)
//        self.remoteView.backgroundColor = UIColor.black
        self.localView.backgroundColor = UIColor.darkGray
    }
    
    @objc func draggedView(_ sender:UIPanGestureRecognizer){
        self.contentOverlayView?.bringSubviewToFront(localView)
        let translation = sender.translation(in: self.view)
        localView.center = CGPoint(x: localView.center.x + translation.x, y: localView.center.y + translation.y)
        sender.setTranslation(CGPoint.zero, in: self.view)
    }
}


/// A view that displays the visual contents of a player object.
class PlayerView: ACBView {
    // Override the property to make AVPlayerLayer the view's backing layer.
    override static var layerClass: AnyClass { AVPlayerLayer.self }
    
    // The associated player object.
    var player: AVPlayer? {
        get { playerLayer.player }
        set { playerLayer.player = newValue }
    }
    
    private var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
}
