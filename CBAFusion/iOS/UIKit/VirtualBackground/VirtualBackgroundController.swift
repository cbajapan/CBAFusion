//
//  VirtualBackgroundController.swift
//  CBAFusion
//
//  Created by Cole M on 1/23/23.
//

import UIKit
import SwiftUI

@available(iOS 15, *)
struct VirtualBackgroundController: UIViewControllerRepresentable {
    
    /// The collection view controller that displays virtual backgrounds.
    let compositionCollectionView: VirtualBackgroundViewController
    
    /// The observer for managing background images.
    let backgroundObserver: BackgroundObserver
    
    /// Initializes a new instance of `VirtualBackgroundController`.
    ///
    /// - Parameter backgroundObserver: An instance of `BackgroundObserver` to manage background images.
    init(backgroundObserver: BackgroundObserver) {
        self.backgroundObserver = backgroundObserver
        compositionCollectionView = VirtualBackgroundViewController(backgroundObserver: backgroundObserver)
    }
    
    /// A coordinator class that acts as a delegate for the collection view.
    class Coordinator: NSObject, UICollectionViewDelegate {
        
        /// The parent `VirtualBackgroundController` instance.
        var parent: VirtualBackgroundController
        
        /// Initializes a new instance of `Coordinator`.
        ///
        /// - Parameter parent: The parent `VirtualBackgroundController` instance.
        init(_ parent: VirtualBackgroundController) {
            self.parent = parent
        }
        
        /// Called when a collection view item is selected.
        ///
        /// - Parameter collectionView: The collection view containing the item.
        /// - Parameter indexPath: The index path of the selected item.
        func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            guard let object = parent.compositionCollectionView.dataSource.itemIdentifier(for: indexPath) else { return }
            object.image.title = object.title
            parent.backgroundObserver.displayImage = DisplayImageObject(image1: object.image, image2: object.thumbnail)
        }
        
        /// Called when a collection view item is deselected.
        ///
        /// - Parameter collectionView: The collection view containing the item.
        /// - Parameter indexPath: The index path of the deselected item.
        func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
            collectionView.deselectItem(at: indexPath, animated: true)
        }
    }
    
    /// Creates and returns a coordinator instance.
    ///
    /// - Returns: A new `Coordinator` instance.
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    /// Creates and configures the `VirtualBackgroundViewController`.
    ///
    /// - Parameter context: The context for the view controller.
    /// - Returns: A configured instance of `VirtualBackgroundViewController`.
    func makeUIViewController(context: UIViewControllerRepresentableContext<VirtualBackgroundController>) -> VirtualBackgroundViewController {
        compositionCollectionView.collectionView.delegate = context.coordinator
        return compositionCollectionView
    }
    
    /// Updates the `VirtualBackgroundViewController` when the SwiftUI view changes.
    ///
    /// - Parameters:
    ///   - uiViewController: The `VirtualBackgroundViewController` to update.
    ///   - context: The context for the update.
    func updateUIViewController(_ uiViewController: VirtualBackgroundViewController, context: UIViewControllerRepresentableContext<VirtualBackgroundController>) {
        // No updates needed for now
    }
}
