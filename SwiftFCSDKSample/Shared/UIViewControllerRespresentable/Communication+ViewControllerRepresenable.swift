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
    @Binding var removePip: Bool
    @Binding var cameraFront: Bool
    @Binding var cameraBack: Bool
    @Binding var destination: String
    @Binding var hasVideo: Bool
    @Binding var endCall: Bool
    @Binding var muteVideo: Bool
    @Binding var resumeVideo: Bool
    @Binding var muteAudio: Bool
    @Binding var resumeAudio: Bool
    @Binding var hold: Bool
    @Binding var resume: Bool
    @Binding var acbuc: ACBUC?
    @Binding var isOutgoing: Bool
    @Binding var fcsdkCall: FCSDKCall?
    
    @EnvironmentObject var callKitManager: CallKitManager
    @EnvironmentObject var fcsdkCallService: FCSDKCallService
    @EnvironmentObject var authenticationService: AuthenticationService
    
    @AppStorage("AutoAnswer") var autoAnswer = false
    
    init(
        pip: Binding<Bool>,
        removePip: Binding<Bool>,
        cameraFront: Binding<Bool>,
        cameraBack: Binding<Bool>,
        destination: Binding<String>,
        hasVideo: Binding<Bool>,
        endCall: Binding<Bool>,
        muteVideo: Binding<Bool>,
        resumeVideo: Binding<Bool>,
        muteAudio: Binding<Bool>,
        resumeAudio: Binding<Bool>,
        hold: Binding<Bool>,
        resume: Binding<Bool>,
        acbuc: Binding<ACBUC?>,
        fcsdkCall: Binding<FCSDKCall?>,
        isOutgoing: Binding<Bool>
    ) {
        self._pip = pip
        self._removePip = removePip
        self._cameraFront = cameraFront
        self._cameraBack = cameraBack
        self._acbuc = acbuc
        self._destination = destination
        self._hasVideo = hasVideo
        self._endCall = endCall
        self._muteVideo = muteVideo
        self._resumeVideo = resumeVideo
        self._muteAudio = muteAudio
        self._resumeAudio = resumeAudio
        self._hold = hold
        self._resume = resume
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
    
    func updateUIViewController(_
                                uiViewController: CommunicationViewController,
                                context: UIViewControllerRepresentableContext<CommunicationViewControllerRepresenable>
    ) {
        //        uiViewController.showPip(show: self.pip)
        uiViewController.authenticationService = self.authenticationService
        uiViewController.destination = self.destination
        uiViewController.hasVideo = self.hasVideo
        uiViewController.callKitManager = self.callKitManager
        uiViewController.acbuc = self.acbuc!
        let call = self.fcsdkCallService
        
        if call.hasStartedConnecting {
            uiViewController.currentState(state: .hasStartedConnecting)
        }
        
        if call.isRinging {
            uiViewController.currentState(state: .isRinging)
        }
        
        if call.hasConnected {
            uiViewController.currentState(state: .hasConnected)
        }
        
        if self.hold {
            uiViewController.currentState(state: .hold)
        }
        
        if self.resume {
            uiViewController.currentState(state: .resume)
        }
        
        if self.muteVideo {
            uiViewController.currentState(state: .muteVideo)
        }
        
        if self.resumeVideo {
            uiViewController.currentState(state: .resumeVideo)
        }
        
        if self.muteAudio {
            uiViewController.currentState(state: .muteAudio)
        }
        
        if self.resumeAudio {
            uiViewController.currentState(state: .resumeAudio)
        }
        
        if self.cameraFront {
            uiViewController.currentState(state: .cameraFront)
        }
        if self.cameraBack {
            uiViewController.currentState(state: .cameraBack)
        }
        
        
        if call.hasEnded {
            if !self.endCall {
                Task {
                    await uiViewController.endCall()
                }
            }
            self.isOutgoing = false
            uiViewController.currentState(state: .hasEnded)
        }
        
        if self.endCall {
            if !call.hasEnded {
                if self.autoAnswer && !self.isOutgoing {
                    self.fcsdkCallService.endFCSDKCall()
                } else {
                    Task {
                        await uiViewController.endCall()
                    }
                }
                uiViewController.currentState(state: .hasEnded)
            } else {
                //dismiss view
                uiViewController.currentState(state: .hasEnded)
            }
            self.isOutgoing = false
            dismissView()
        }
        
        if self.pip {
            uiViewController.showPip(show: true)
        }
        
        if self.removePip {
            uiViewController.showPip(show: false)
        }
        
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
            
            if self.parent.autoAnswer {
                do {
                    try await self.parent.fcsdkCallService.answerFCSDKCall()
                } catch {
                    print("OUR ERROR: \(OurErrors.nilACBUC.rawValue) - Specifically: \(error) ")
                }
            }
        }
    }
    
    func dismissView() {
        if !self.fcsdkCallService.hasEnded {
            self.fcsdkCallService.hasEnded = true
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
