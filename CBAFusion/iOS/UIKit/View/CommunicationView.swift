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
    var remoteView: UIView?
    var pipLayer: AVSampleBufferDisplayLayer?
    var previewView: UIView?
    var captureSession: AVCaptureSession?
    let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.dark)
    var blurEffectView: UIVisualEffectView?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateAnchors(_ orientation: UIDeviceOrientation) {
        guard let previewView = previewView else { return }
        guard let remoteView = remoteView else { return }
        if UIApplication.shared.applicationState != .background {
            
            var width: CGFloat = 0
            var height: CGFloat = 0
            
            switch orientation {
            case .portrait, .portraitUpsideDown:
                switch UIDevice.current.userInterfaceIdiom {
                case .phone:
                    width = 150
                    height = 200
                case .pad:
                    width = 250
                    height = 200
                default:
                    break
                }
            case .landscapeRight, .landscapeLeft:
                switch UIDevice.current.userInterfaceIdiom {
                case .phone:
                    width = 200
                    height = 150
                case .pad:
                    width = 200
                    height = 250
                default:
                    break
                }
            default:
                switch UIDevice.current.userInterfaceIdiom {
                case .phone:
                    width = 150
                    height = 200
                case .pad:
                    width = 250
                    height = 200
                default:
                    break
                }
            }
            
 
            for constraint in previewView.constraints {
                if constraint.isActive {
                    constraint.isActive = false
                }
            }

            for constraint in remoteView.constraints {
                if constraint.isActive {
                    constraint.isActive = false
                }
            }
            
            remoteView.anchors(
                top: topAnchor,
                leading: leadingAnchor,
                bottom: bottomAnchor,
                trailing: trailingAnchor
            )

            previewView.anchors(
                bottom: bottomAnchor,
                trailing: trailingAnchor,
                bottomPadding: 110,
                trailPadding: 20,
                width: width,
                height: height
            )

            remoteView.frame = remoteView.bounds
            previewView.frame = previewView.bounds
            previewView.layer.cornerRadius = 10
            previewView.layer.masksToBounds = true
           
        }
    }
    
    func setupUI() {
        guard let previewView = previewView else { return }
        guard let remoteView = remoteView else { return }
        if !subviews.contains(previewView) || !subviews.contains(remoteView) {
            addSubview(remoteView)
            addSubview(previewView)
        }
    }

    
    func breakDownView() {
        guard let previewView = previewView else { return }
        guard let remoteView = remoteView else { return }
        remoteView.removeFromSuperview()
        previewView.removeFromSuperview()
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
    

    func removeConnectingUI() {
        stackView.removeFromSuperview()
    }
    
}
