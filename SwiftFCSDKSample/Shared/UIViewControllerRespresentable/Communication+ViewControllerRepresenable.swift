//
//  Communication+ViewControllerRepresenable.swift
//  SwiftFCSDKSample
//
//  Created by Cole M on 9/1/21.
//

import UIKit
import SwiftUI
import SwiftFCSDK

struct CommunicationViewControllerRepresenable: UIViewControllerRepresentable {

    @Binding var call: FCSDKCall
    @Binding var pip: Bool
    @Binding var acbuc: ACBUC?
    

    init(call: Binding<FCSDKCall>, pip: Binding<Bool>, acbuc: Binding<ACBUC?>) {
        self._call = call
        self._pip = pip
        self._acbuc = acbuc
    }
    
//    class Coordinator: NSObject {
//        
//        var parent: CommunicationViewControllerRepresenable
//
//        init(_ parent: CommunicationViewControllerRepresenable) {
//            self.parent = parent
//        }
//    }
//        
//        ///Write UIVIew Delegate methods here
//        
//    func makeCoordinator() -> Coordinator {
//        Coordinator(self)
//    }
//
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<CommunicationViewControllerRepresenable>) -> CommunicationViewController {
        let communicationViewController = CommunicationViewController(acbuc: self.acbuc!, call: self.call)
        return communicationViewController
    }
    
    func updateUIViewController(_ uiViewController: CommunicationViewController, context: UIViewControllerRepresentableContext<CommunicationViewControllerRepresenable>) {
        uiViewController.call = call
        uiViewController.showPip(show: self.pip)
        uiViewController.playerView = call.videoView as? PlayerView ?? PlayerView()
        uiViewController.localView = call.previewView ?? ACBView()
    }
}

enum OurErrors: String, Swift.Error {
    case nilACBUC = "Cannot initialize because ACBUC is nil"
    case nilResolution = "Cannot get Resolution because it is nil"
    case nilFrameRate = "Cannot get frame rate because it is nil"
}
