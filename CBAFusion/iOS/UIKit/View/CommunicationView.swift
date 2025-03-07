//
//  CommunicationView.swift
//  CBAFusion
//
//  Created by Cole M on 2/1/22.
//

import UIKit
import AVKit

/// A custom UIView that manages the communication interface for video calls.
@MainActor
class CommunicationView: UIView {
    
    // MARK: - Properties
    
    /// A stack view to arrange the number and name labels vertically.
    var stackView: UIStackView = {
        let stk = UIStackView()
        stk.alignment = .center
        return stk
    }()
    
    /// A label to display the remote number.
    let numberLabel = UILabel()
    
    /// A label to display the name of the contact.
    let nameLabel = UILabel()
    
    /// A layer for displaying video frames.
    var pipLayer: AVSampleBufferDisplayLayer?
    
    /// A view for displaying the video preview.
    var previewView: UIView?
    
    /// The capture session for managing video input and output.
    var captureSession: AVCaptureSession?
    
    /// A blur effect for the background.
    let blurEffect = UIBlurEffect(style: .dark)
    
    /// A view to apply the blur effect.
    var blurEffectView: UIVisualEffectView?
    
    let block: UIView = {
        let v = UIView()
        v.backgroundColor = .darkGray
        return v
    }()
    
    /// A flag indicating whether the preview view is flipped.
    var isFlipped = false
    
    // MARK: - Initializers
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Layout Methods
    
    /// Updates the layout anchors based on the device orientation and whether the view is flipped.
    /// - Parameters:
    ///   - orientation: The current device orientation.
    ///   - flipped: A boolean indicating if the view should be flipped.
    ///   - minimize: A boolean indicating if the view should be minimized.
    func updateAnchors(_ orientation: UIDeviceOrientation, flipped: Bool = false, minimize: Bool = false) {
        assert(!Thread.isMainThread)
        self.isFlipped = flipped
        
        if UIApplication.shared.applicationState != .background {
            let size: (CGFloat, CGFloat) = determineSize(for: orientation, minimize: minimize)
            setConstraint(flipped: flipped, size: size)
        }
    }
    
    /// Sets the constraints for the preview view based on its flipped state and size.
    /// - Parameters:
    ///   - flipped: A boolean indicating if the view should be flipped.
    ///   - size: A tuple containing the width and height for the preview view.
    func setConstraint(flipped: Bool, size: (CGFloat, CGFloat)) {
        assert(!Thread.isMainThread)
        if let previewView = previewView {
            previewView.removeConstraints(previewView.constraints)
            previewView.layer.cornerRadius = 10
            previewView.layer.masksToBounds = true
            
            if flipped {
                previewView.anchors(
                    top: topAnchor,
                    leading: leadingAnchor,
                    bottom: bottomAnchor,
                    trailing: trailingAnchor
                )
            } else {
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
    }
    
    /// Calculates the aspect ratio based on the given width and height.
    /// - Parameters:
    ///   - width: The width of the view.
    ///   - height: The height of the view.
    /// - Returns: The aspect ratio as a CGFloat.
    internal func getAspectRatio(width: CGFloat, height: CGFloat) -> CGFloat {
        return max(width, height) / min(width, height)
    }
    
    /// Determines the size of the preview view based on the device orientation and whether it should be minimized.
    /// - Parameters:
    ///   - orientation: The current device orientation.
    ///   - minimize: A boolean indicating if the view should be minimized.
    /// - Returns: A tuple containing the width and height for the preview view.
    internal func determineSize(for orientation: UIDeviceOrientation, minimize: Bool) -> (CGFloat, CGFloat) {
        var width: CGFloat = 0
        var height: CGFloat = 0
        
        switch orientation {
        case .unknown, .faceUp, .faceDown:
            if UIScreen.main.bounds.width < UIScreen.main.bounds.height {
                // Portrait
                width = minimize ? UIScreen.main.bounds.width / 6.5 : UIScreen.main.bounds.height / 4.5
                height = width * getAspectRatio(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
            } else {
                // Landscape
                width = minimize ? UIScreen.main.bounds.width / 4 : UIScreen.main.bounds.width / 3
                height = width / getAspectRatio(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
            }
        case .portrait, .portraitUpsideDown:
            width = minimize ? UIScreen.main.bounds.width / 6.5 : UIScreen.main.bounds.height / 4.5
            height = width * getAspectRatio(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        case .landscapeLeft, .landscapeRight:
            width = minimize ? UIScreen.main.bounds.width / 4 : UIScreen.main.bounds.width / 3
            height = width / getAspectRatio(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        default:
            break
        }
        
        return (width, height)
    }
    
    // MARK: - UI Setup Methods
    
    /// Sets up the user interface for the communication view.
    func setupUI() {
        if let previewView = previewView, !subviews.contains(previewView) {
            addSubview(previewView)
        }
    }
    
    /// Cleans up the view by removing the preview view.
    func breakDownView() {
        previewView?.removeFromSuperview()
    }
    
    /// Configures the UI to indicate that a connection is being established.
    /// - Parameter isRinging: A boolean indicating if the call is ringing.
    func connectingUI(isRinging: Bool) {
        assert(!Thread.isMainThread)
        numberLabel.font = .boldSystemFont(ofSize: 18)
        nameLabel.text = isRinging ? "Ringing..." : "FCSDK iOS Connecting..."
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
    
    // MARK: - Gesture Handling
    
    /// Configures gesture recognizers for the preview view.
    func gestures() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(draggedLocalView(_:)))
        guard let previewView = previewView else { return }
        previewView.isUserInteractionEnabled = true
        previewView.addGestureRecognizer(panGesture)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapLocalView))
        previewView.addGestureRecognizer(tapGesture)
    }
    
    /// Handles dragging of the local view.
    /// - Parameter sender: The pan gesture recognizer.
    @objc func draggedLocalView(_ sender: UIPanGestureRecognizer) {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            guard let previewView = self.previewView else { return }
            self.bringSubviewToFront(previewView)
            let translation = sender.translation(in: self)
            previewView.center = CGPoint(x: previewView.center.x + translation.x, y: previewView.center.y + translation.y)
            sender.setTranslation(.zero, in: self)
        }
    }
    
    /// Handles tap gestures on the local view.
    @objc func tapLocalView() {
        // Toggle the tapped state and update anchors if needed
        // tapped = !tapped
        // self.updateAnchors(UIDevice.current.orientation, minimize: self.tapped)
    }
    
    /// Removes the connecting UI elements from the view.
    func removeConnectingUI() {
        stackView.removeFromSuperview()
    }
}
