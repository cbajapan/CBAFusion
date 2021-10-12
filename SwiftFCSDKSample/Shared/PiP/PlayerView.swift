//
//  PlayerView.swift
//  SwiftFCSDKSample
//
//  Created by Cole M on 9/8/21.
//

import Foundation
import SwiftFCSDK
import AVKit


class SampleBufferVideoCallView: ACBView {
    override class var layerClass: AnyClass {
         get { return AVSampleBufferDisplayLayer.self }
     }

     weak var sampleBufferDisplayLayer: AVSampleBufferDisplayLayer? {
         return layer as? AVSampleBufferDisplayLayer
     }
}

class SamplePreviewVideoCallView: ACBView {
    override class var layerClass: AnyClass {
         get { return AVCaptureVideoPreviewLayer.self }
     }

     weak var sampleBufferDisplayLayer: AVCaptureVideoPreviewLayer? {
         return layer as? AVCaptureVideoPreviewLayer
     }
}
