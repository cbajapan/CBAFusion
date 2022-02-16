//
//  CommunicationView.swift
//  CBAFusion
//
//  Created by Cole M on 2/1/22.
//

import UIKit
import AVKit

class CommunicationView: UIView {

    
    var stackView: UIStackView = {
        let stk = UIStackView()
        stk.alignment = .center
        return stk
    }()
    let numberLabel = UILabel()
    let nameLabel = UILabel()
    var remoteView = UIView()
    var remoteBufferView: UIView?
    var previewView = UIView()
    let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.dark)
    var blurEffectView: UIVisualEffectView?
    
    
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    @MainActor
    func anchors() {
        
        //We can adjust the size of video if we want to via the constraints API, the next 2 lines can center a view
        //        self.remoteView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
        //        self.remoteView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        if UIApplication.shared.applicationState != .background {
            //We can change width and height as we wish
            self.remoteView.anchors(top: topAnchor, leading: leadingAnchor, bottom: bottomAnchor, trailing: trailingAnchor, topPadding: 0, leadPadding: 0, bottomPadding: 0, trailPadding: 0, width: 0, height: 0)
            if UIDevice.current.userInterfaceIdiom == .phone {
                self.previewView.anchors(top: nil, leading: nil, bottom: bottomAnchor, trailing: trailingAnchor, topPadding: 0, leadPadding: 0, bottomPadding: 110, trailPadding: 20, width: 150, height: 200)
                
            } else {
                self.previewView.anchors(top: nil, leading: nil, bottom: bottomAnchor, trailing: trailingAnchor, topPadding: 0, leadPadding: 0, bottomPadding: 110, trailPadding: 20, width: 250, height: 200)
            }
            
            /// We can access the `AVSampleBufferDisplayLayer` and adjust the layer size. We want to cast our layer  according if we are using the remoteBufferView.
            
            let layer = self.remoteView.layer as? AVSampleBufferDisplayLayer
            layer?.masksToBounds = true
            layer?.videoGravity = .resizeAspectFill
        }
    }
    
    @MainActor
    func setupUI() {
        addSubview(self.remoteView)
        addSubview(self.previewView)
        self.previewView.layer.cornerRadius = 10
        self.previewView.layer.masksToBounds = true
    }

    
    @MainActor
    func breakDownView() {
        remoteView.removeFromSuperview()
        previewView.removeFromSuperview()
    }
    
    @MainActor
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
            stackView.anchors(top: topAnchor, leading: leadingAnchor, bottom: nil, trailing: trailingAnchor, topPadding: 50, leadPadding: 0, bottomPadding: 0, trailPadding: 0, width: 0, height: 0)
        }
    }
    
    @MainActor
    func removeConnectingUI() {
        stackView.removeFromSuperview()
    }
    
}
