//
//  CommunicationView.swift
//  CBAFusion
//
//  Created by Cole M on 2/1/22.
//

import UIKit
import AVKit

@MainActor
class CommunicationView: UIView {
    
    
    var stackView: UIStackView = {
        let stk = UIStackView()
        stk.alignment = .center
        return stk
    }()
    let numberLabel = UILabel()
    let nameLabel = UILabel()
    var pipLayer: AVSampleBufferDisplayLayer?
    var previewView: UIView?
    var captureSession: AVCaptureSession?
    let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.dark)
    var blurEffectView: UIVisualEffectView?
    var isFlipped = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateAnchors(_ orientation: UIDeviceOrientation, flipped: Bool = false, minimize: Bool = false) {
        self.isFlipped = flipped
        
        if UIApplication.shared.applicationState != .background {
            
            var size: (CGFloat, CGFloat) = (0,0)
            
            switch orientation {
            case .unknown, .faceUp, .faceDown:
                if UIScreen.main.bounds.width < UIScreen.main.bounds.height {
                    size = setSize(isLandscape: false, minimize: minimize)
                } else {
                    size = setSize(isLandscape: true, minimize: minimize)
                }
            case .portrait, .portraitUpsideDown:
                size = setSize(isLandscape: false, minimize: minimize)
            case .landscapeRight, .landscapeLeft:
                size = setSize(isLandscape: true, minimize: minimize)
            default:
                size = setSize(isLandscape: true, minimize: minimize)
            }
            setConstraint(flipped: flipped, size: size)
        }
    }
    
    func setConstraint(flipped: Bool, size: (CGFloat, CGFloat)) {
        if let previewView = previewView {
            for constraint in previewView.constraints {
                if constraint.isActive {
                    constraint.isActive = false
                }
            }
        }
        
        if flipped {
            if let previewView = previewView {
                previewView.anchors(
                    top: topAnchor,
                    leading: leadingAnchor,
                    bottom: bottomAnchor,
                    trailing: trailingAnchor
                )
            }
        } else {
            if let previewView = previewView {
                previewView.anchors(
                    bottom: bottomAnchor,
                    trailing: trailingAnchor,
                    bottomPadding: 135,
                    trailPadding: 20,
                    width: size.0,
                    height: size.1
                )
            }
        }
        if let previewView = previewView {
            previewView.frame = previewView.bounds
            previewView.layer.cornerRadius = 10
            previewView.layer.masksToBounds = true
        }
    }
    
    internal func getAspectRatio(width: CGFloat, height: CGFloat) -> CGFloat {
        if width > height {
            return width / height
        } else {
            return height / width
        }
    }
    
    internal func setSize(isLandscape: Bool, minimize: Bool) -> (CGFloat, CGFloat) {
        var width: CGFloat = 0
        var height: CGFloat = 0
        
        if isLandscape {
            switch UIDevice.current.userInterfaceIdiom {
            case .phone:
                width = minimize ? (UIScreen.main.bounds.width / 4) : (UIScreen.main.bounds.width / 3)
                height = minimize ? (UIScreen.main.bounds.width / 4) / getAspectRatio(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height) : (UIScreen.main.bounds.width / 3) / getAspectRatio(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
            case .pad:
                width = minimize ?  UIScreen.main.bounds.width / 3 : UIScreen.main.bounds.width / 4
                height = minimize ? (UIScreen.main.bounds.width / 3) / getAspectRatio(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height) : (UIScreen.main.bounds.width / 4) / getAspectRatio(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
            default:
                break
            }
        } else {
            switch UIDevice.current.userInterfaceIdiom {
            case .phone:
                width = minimize ? (UIScreen.main.bounds.width / 6.5) : UIScreen.main.bounds.height / 4.5
                
                height = minimize ? (UIScreen.main.bounds.width / 6.5) * getAspectRatio(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height) : (UIScreen.main.bounds.height / 5.5) * getAspectRatio(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
            case .pad:
                width = minimize ? UIScreen.main.bounds.height / 3 : UIScreen.main.bounds.height / 4
                height = minimize ? (UIScreen.main.bounds.height / 3) * getAspectRatio(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height) : (UIScreen.main.bounds.height / 4) * getAspectRatio(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
            default:
                break
            }
        }
        return (width, height)
    }
    
    func setupUI() {
        if let previewView = previewView, !subviews.contains(previewView) {
            addSubview(previewView)
        }
    }
    
    
    func breakDownView() {
        if let previewView = previewView {
            previewView.removeFromSuperview()
        }
    }
    
    func connectingUI(isRinging: Bool) {
        numberLabel.font = .boldSystemFont(ofSize: 18)
        if isRinging {
            nameLabel.text = "Ringing..."
        } else {
            nameLabel.text = "FCSDK iOS Connecting..."
        }
        nameLabel.font = .systemFont(ofSize: 16)
        addSubview(stackView)
        stackView.addArrangedSubview(numberLabel)
        stackView.addArrangedSubview(nameLabel)
        stackView.axis = .vertical
        if UIApplication.shared.applicationState != .background {
            stackView.anchors(
                top: topAnchor,
                leading: leadingAnchor,
                trailing: trailingAnchor,
                topPadding: 50
            )
        }
    }
    
    func gestures() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(draggedLocalView(_:)))
        guard let previewView = previewView else { return }
        previewView.isUserInteractionEnabled = true
        previewView.addGestureRecognizer(panGesture)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapLocalView))
        previewView.addGestureRecognizer(tapGesture)
    }
    
    @objc func draggedLocalView(_ sender:UIPanGestureRecognizer) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            guard let previewView = self.previewView else { return }
            self.bringSubviewToFront(previewView)
            let translation = sender.translation(in: self)
            previewView.center = CGPoint(x: previewView.center.x + translation.x, y: previewView.center.y + translation.y)
            sender.setTranslation(CGPoint.zero, in: self)
        }
    }
    
    
    var tapped = false
    @objc func tapLocalView() {
        tapped = !tapped
        self.updateAnchors(UIDevice.current.orientation, minimize: self.tapped)
    }
    
    func removeConnectingUI() {
        stackView.removeFromSuperview()
    }
    
}
