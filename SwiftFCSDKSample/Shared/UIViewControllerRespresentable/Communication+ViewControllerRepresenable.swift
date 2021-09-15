//
//  Communication+ViewControllerRepresenable.swift
//  SwiftFCSDKSample
//
//  Created by Cole M on 9/1/21.
//

import UIKit
import SwiftUI

struct CommunicationViewControllerRepresenable: UIViewControllerRepresentable {

    @Binding var call: FCSDKCall
    @Binding var pip: Bool
    let communicationViewController: CommunicationViewController
    

    init(call: Binding<FCSDKCall>, pip: Binding<Bool>) {
        self._call = call
        self._pip = pip
        communicationViewController = CommunicationViewController()
        print(_call, "CALL_____")
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
    
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<CommunicationViewControllerRepresenable>) -> CommunicationViewController {
        return communicationViewController
    }
    
    func updateUIViewController(_ uiViewController: CommunicationViewController, context: UIViewControllerRepresentableContext<CommunicationViewControllerRepresenable>) {
        uiViewController.showPip(show: self.pip)
        uiViewController.videoView = call.videoView
        uiViewController.previewView = call.previewView
    }
}
