//
//  VirtualBackgroundController.swift
//  CBAFusion
//
//  Created by Cole M on 1/23/23.
//
import UIKit
import SwiftUI

@available(iOS 15.0, *)
struct VirtualBackgroundController: UIViewControllerRepresentable {
    
    var compositionCollectionView: VirtualBackgroundViewController
    @EnvironmentObject var backgrounds: Backgrounds

    init(backgrounds: EnvironmentObject<Backgrounds>) {
        self._backgrounds = backgrounds
        self.compositionCollectionView = VirtualBackgroundViewController(backgrounds: _backgrounds.wrappedValue)
    }
    
    class Coordinator: NSObject, UICollectionViewDelegate {
        
        var parent: VirtualBackgroundController
        
        init(_ parent: VirtualBackgroundController) {
            self.parent = parent
        }
        
        
        func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            let object = parent.compositionCollectionView.dataSource.itemIdentifier(for: (parent.compositionCollectionView.collectionView.indexPathsForSelectedItems?.first)!)
                if let object = object {
                    parent.backgrounds.displayImage = (object.image, object.thumbnail)
                }
            }
        
        func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
            parent.compositionCollectionView.collectionView.deselectItem(at: indexPath, animated: true)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<VirtualBackgroundController>) -> VirtualBackgroundViewController {
        compositionCollectionView.collectionView.delegate = context.coordinator
        return compositionCollectionView
    }
    
    func updateUIViewController(_ uiViewController: VirtualBackgroundViewController, context: UIViewControllerRepresentableContext<VirtualBackgroundController>) {
        uiViewController.backgrounds = self.backgrounds
    }
}
