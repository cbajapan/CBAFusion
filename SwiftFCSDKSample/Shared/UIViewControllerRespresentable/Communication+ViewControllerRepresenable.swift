//
//  Communication+ViewControllerRepresenable.swift
//  SwiftFCSDKSample
//
//  Created by Cole M on 9/1/21.
//

import UIKit
import SwiftUI
import FCSDKiOS

struct CommunicationViewControllerRepresenable: UIViewControllerRepresentable {
    @Binding var pip: Bool
    @Binding var destination: String
    @Binding var hasVideo: Bool
    @Binding var endCall: Bool
    @Binding var isOnHold: Bool
    @Binding var acbuc: ACBUC?
    @Binding var isOutgoing: Bool
    @Binding var fcsdkCall: FCSDKCall?
    
    @EnvironmentObject var callKitManager: CallKitManager
    @EnvironmentObject var fcsdkCallService: FCSDKCallService
    
    init(
        pip: Binding<Bool>,
        destination: Binding<String>,
        hasVideo: Binding<Bool>,
        endCall: Binding<Bool>,
        isOnHold: Binding<Bool>,
        acbuc: Binding<ACBUC?>,
        fcsdkCall: Binding<FCSDKCall?>,
        isOutgoing: Binding<Bool>
    ) {
        self._pip = pip
        self._acbuc = acbuc
        self._destination = destination
        self._hasVideo = hasVideo
        self._endCall = endCall
        self._isOnHold = isOnHold
        self._fcsdkCall = fcsdkCall
        self._isOutgoing = isOutgoing
    }
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<CommunicationViewControllerRepresenable>) -> CommunicationViewController {
        let communicationViewController = CommunicationViewController(
            callKitManager: self.callKitManager,
            destination: self.destination,
            hasVideo: self.hasVideo,
            acbuc: self.acbuc!,
            isOutgoing: self.isOutgoing
        )
        communicationViewController.fcsdkCallDelegate = context.coordinator
        return communicationViewController
    }
    
    func updateUIViewController(_ uiViewController: CommunicationViewController, context: UIViewControllerRepresentableContext<CommunicationViewControllerRepresenable>) {
        //        uiViewController.showPip(show: self.pip)
        
        uiViewController.destination = self.destination
        uiViewController.hasVideo = self.hasVideo
        uiViewController.callKitManager = self.callKitManager
        uiViewController.acbuc = self.acbuc!
        let call = self.fcsdkCallService
        if call.hasStartedConnecting {
            uiViewController.currentState(state: .hasStartedConnecting)
        }
        else if call.isRinging {
            uiViewController.currentState(state: .isRinging)
        }
        else if call.hasConnected {
            uiViewController.currentState(state: .hasConnected)
        }
        else if self.isOnHold {
            uiViewController.currentState(state: .isOnHold)
        }
        else if !self.isOnHold {
            uiViewController.currentState(state: .notOnHold)
        }
        if call.hasEnded {
            uiViewController.currentState(state: .hasEnded)
        }

        if self.endCall {
            Task {
                await uiViewController.endCall()
            }
        }
        
//        if call.receivedEnd {
//            Task {
//                await uiViewController.endCall()
//            }
//        }
    }
    
    class Coordinator: NSObject, FCSDKCallDelegate {
        
        var parent: CommunicationViewControllerRepresenable
        
        init(_ parent: CommunicationViewControllerRepresenable) {
            self.parent = parent
        }
        
        @MainActor func passCallToService(_ call: FCSDKCall) async {
            self.parent.fcsdkCall = call
        }
        
        @MainActor func passViewsToService(preview: SamplePreviewVideoCallView, remoteView: SampleBufferVideoCallView) async {
            self.parent.fcsdkCall?.previewView = preview
            self.parent.fcsdkCall?.remoteView = remoteView
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}


protocol FCSDKCallDelegate: AnyObject {
    func passCallToService(_ call: FCSDKCall) async
    func passViewsToService(preview: SamplePreviewVideoCallView, remoteView: SampleBufferVideoCallView) async
}

enum OurErrors: String, Swift.Error {
    case nilACBUC = "Cannot initialize because ACBUC is nil"
    case nilFCSDKCall = "Cannot initialize because FCSDKCall is nil"
    case nilPreviewView = "Cannot set previewView because it is nil"
    case nilResolution = "Cannot get Resolution because it is nil"
    case nilFrameRate = "Cannot get frame rate because it is nil"
}
