//
//  CommunicationViewConroller.swift
//  SwiftFCSDKSample
//
//  Created by Cole M on 9/1/21.
//

import Foundation
import UIKit
import ACBClientSDK

class CommunicationViewController: UIViewController {
    
    
    var panGesture = UIPanGestureRecognizer()
    
    var remoteView: UIView = {
        let rv = UIView()
        return rv
    }()
    
    var localView: UIView = {
        let lv = UIView()
        lv.layer.cornerRadius = 8
        return lv
    }()
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        anchors()
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(draggedView(_:)))
        self.localView.isUserInteractionEnabled = true
        self.localView.addGestureRecognizer(panGesture)
    }
    
    
    func anchors() {
        self.remoteView.translatesAutoresizingMaskIntoConstraints = true
        self.localView.translatesAutoresizingMaskIntoConstraints = true
        self.view.addSubview(self.remoteView)
        self.remoteView.addSubview(self.localView)
        self.remoteView.greaterThanHeightAnchors(top: view.topAnchor, leading: view.leadingAnchor, bottom: view.bottomAnchor, trailing: view.trailingAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        self.localView.greaterThanHeightAnchors(top: nil, leading: nil, bottom: view.bottomAnchor, trailing: view.trailingAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 6, paddingRight: 6, width: view.frame.width / 2, height: view.frame.height / 4)
        self.remoteView.backgroundColor = UIColor.yellow
        self.localView.backgroundColor = UIColor.blue
    }
    
    @objc func draggedView(_ sender:UIPanGestureRecognizer){
        self.remoteView.bringSubviewToFront(localView)
        let translation = sender.translation(in: self.view)
        localView.center = CGPoint(x: localView.center.x + translation.x, y: localView.center.y + translation.y)
        sender.setTranslation(CGPoint.zero, in: self.view)
    }
}
