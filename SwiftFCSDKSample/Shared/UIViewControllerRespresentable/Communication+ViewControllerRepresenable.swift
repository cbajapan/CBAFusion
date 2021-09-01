//
//  Communication+ViewControllerRepresenable.swift
//  SwiftFCSDKSample
//
//  Created by Cole M on 9/1/21.
//

import UIKit
import SwiftUI

struct CommunicationViewControllerRepresenable: UIViewControllerRepresentable {


    let communicationViewController: CommunicationViewController
    

    init() {
        communicationViewController = CommunicationViewController()
    }
    
    class Coordinator: NSObject {
        
        var parent: CommunicationViewControllerRepresenable

        init(_ parent: CommunicationViewControllerRepresenable) {
            self.parent = parent
        }
    }
        
        ///Write UIVIew Delegate methods here
        
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<CommunicationViewControllerRepresenable>) -> UIViewController {
        return communicationViewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: UIViewControllerRepresentableContext<CommunicationViewControllerRepresenable>) {
    }
}
