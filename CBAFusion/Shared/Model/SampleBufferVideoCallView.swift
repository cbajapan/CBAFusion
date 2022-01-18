//
//  ACBView.swift
//  swift_fcsdk
//
//  Created by Cole Moore on 7/12/2021
//

import UIKit
import AVKit


/// `SampleBufferVideoCallView` subclasses `UIView`
public final class SampleBufferVideoCallView: UIView {
    
    /// Here we override the layerClass in order to return `AVSampleBufferDisplayLayer`
    override public class var layerClass: AnyClass {
        get { return AVSampleBufferDisplayLayer.self }
    }
    
    /// Here we create the layer in order to render `AVSampleBufferDisplayLayer`
    public weak var sampleBufferDisplayLayer: AVSampleBufferDisplayLayer? {
        return layer as? AVSampleBufferDisplayLayer
    }
}

/// `SamplePreviewVideoCallView` subclasses `UIView`
public final class SamplePreviewVideoCallView: UIView {
    
    /// Here we override the layerClass in order to return `AVCaptureVideoPreviewLayer`
    override public class var layerClass: AnyClass {
        get { return AVCaptureVideoPreviewLayer.self }
    }
    
    /// Here we create the layer in order to render `AVCaptureVideoPreviewLayer`
    public weak var samplePreviewDisplayLayer: AVCaptureVideoPreviewLayer? {
        return layer as? AVCaptureVideoPreviewLayer
    }
}
