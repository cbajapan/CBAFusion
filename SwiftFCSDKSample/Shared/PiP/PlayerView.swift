//
//  PlayerView.swift
//  SwiftFCSDKSample
//
//  Created by Cole M on 9/8/21.
//

import Foundation
import SwiftFCSDK
import AVKit

/// A view that displays the visual contents of a player object.
class PlayerView: ACBView {
    // Override the property to make AVPlayerLayer the view's backing layer.
    override static var layerClass: AnyClass { AVPlayerLayer.self }
    
    // The associated player object.
    var player: AVPlayer? {
        get { playerLayer.player }
        set { playerLayer.player = newValue }
    }
    
    internal var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
}
