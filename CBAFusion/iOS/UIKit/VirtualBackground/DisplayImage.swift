//
//  DisplayImage.swift
//  CBAFusion
//
//  Created by Cole M on 1/23/23.
//

import UIKit
import SwiftUI

/// A SwiftUI view that displays an image using a UIImageView.
/// It observes changes in the background and updates the displayed image accordingly.
struct DisplayImage: UIViewRepresentable {
    
    // An environment object that observes background changes and provides the display image.
    @EnvironmentObject var backgroundObserver: BackgroundObserver

    /// Creates a coordinator to manage the interaction between the SwiftUI view and the UIKit view.
    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }
    
    /// Creates the initial UIImageView to be displayed.
    /// - Parameter context: The context in which the view is created.
    /// - Returns: A UIImageView initialized with the first image from the background observer.
    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit // Set content mode for better image scaling
        imageView.image = backgroundObserver.displayImage?.image1 // Set initial image
        return imageView
    }
    
    /// Updates the UIImageView when the SwiftUI view's state changes.
    /// - Parameters:
    ///   - uiView: The UIImageView to be updated.
    ///   - context: The context in which the view is updated.
    func updateUIView(_ uiView: UIImageView, context: Context) {
        uiView.image = backgroundObserver.displayImage?.image2 // Update image based on the observer
    }
    
    /// A coordinator class to manage interactions between the SwiftUI view and the UIKit view.
    class Coordinator: NSObject {
        var parent: DisplayImage
        
        /// Initializes the coordinator with a reference to the parent DisplayImage.
        /// - Parameter parent: The parent DisplayImage instance.
        init(parent: DisplayImage) {
            self.parent = parent
        }
    }
}
