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
    @Binding var pip: Bool
    @Binding var acbuc: ACBUC?
    @Binding var destination: String
    @Binding var hasVideo: Bool
    @Binding var endCall: Bool
    @EnvironmentObject var callKitManager: CallKitManager

    init(pip: Binding<Bool>, acbuc: Binding<ACBUC?>, destination: Binding<String>, hasVideo: Binding<Bool>, endCall: Binding<Bool>) {
        self._pip = pip
        self._acbuc = acbuc
        self._destination = destination
        self._hasVideo = hasVideo
        self._endCall = endCall
    }
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<CommunicationViewControllerRepresenable>) -> CommunicationViewController {
        let communicationViewController = CommunicationViewController(callKitManager: self.callKitManager, destination: self.destination, hasVideo: self.hasVideo, acbuc: self.acbuc!)
        return communicationViewController
    }
    
    func updateUIViewController(_ uiViewController: CommunicationViewController, context: UIViewControllerRepresentableContext<CommunicationViewControllerRepresenable>) {
        uiViewController.showPip(show: self.pip)
        uiViewController.destination = self.destination
        uiViewController.hasVideo = self.hasVideo
        if self.endCall {
            Task {
            await uiViewController.endCall()
            }
        }
        uiViewController.callKitManager = self.callKitManager
        uiViewController.acbuc = self.acbuc!
    }
}

enum OurErrors: String, Swift.Error {
    case nilACBUC = "Cannot initialize because ACBUC is nil"
    case nilPreviewView = "Cannot set previewView because it is nil"
    case nilResolution = "Cannot get Resolution because it is nil"
    case nilFrameRate = "Cannot get frame rate because it is nil"
}
