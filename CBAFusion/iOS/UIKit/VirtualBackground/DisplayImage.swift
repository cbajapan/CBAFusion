//
//  DisplayImage.swift
//  CBAFusion
//
//  Created by Cole M on 1/23/23.
//

import UIKit
import SwiftUI

struct DisplayImage: UIViewRepresentable {
    
    @EnvironmentObject var backgrounds: Backgrounds

    func makeCoordinator() -> Coordinator {
        return DisplayImage.Coordinator(parent: self)
    }
    
    func makeUIView(context: Context) -> UIImageView {
        UIImageView(image: backgrounds.displayImage?.1)
    }
    func updateUIView(_ uiView: UIImageView, context: Context) {
        uiView.image = backgrounds.displayImage?.1
    }
    
    class Coordinator: NSObject {
        var parent: DisplayImage
        
        init(parent: DisplayImage) {
            self.parent = parent
        }
    }
}
