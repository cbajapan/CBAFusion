//
//  Communication+ViewControllerRepresenable.swift
//  CBAFusion
//
//  Created by Cole M on 9/1/21.
//

import UIKit
import SwiftUI
import FCSDKiOS

struct CommunicationViewControllerRepresentable: UIViewControllerRepresentable {
    
    @Binding var pip: Bool
    @Binding var removePip: Bool
    @Binding var destination: String
    @Binding var hasVideo: Bool
    @Binding var muteVideo: Bool
    @Binding var muteAudio: Bool
    @Binding var hold: Bool
    @Binding var acbuc: ACBUC?
    @Binding var isOutgoing: Bool
    @Binding var fcsdkCall: FCSDKCall?
    @Binding var closeClickID: UUID?
    @Binding var cameraFrontID: UUID?
    @Binding var cameraBackID: UUID?
    @Binding var holdID: UUID?
    @Binding var resumeID: UUID?
    @Binding var muteAudioID: UUID?
    @Binding var resumeAudioID: UUID?
    @Binding var muteVideoID: UUID?
    @Binding var resumeVideoID: UUID?
    
    @EnvironmentObject var callKitManager: CallKitManager
    @EnvironmentObject var fcsdkCallService: FCSDKCallService
    @EnvironmentObject var authenticationService: AuthenticationService
    
    @AppStorage("AutoAnswer") var autoAnswer = false
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<CommunicationViewControllerRepresentable>) -> CommunicationViewController {
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
                                context: UIViewControllerRepresentableContext<CommunicationViewControllerRepresentable>
    ) {
        //        uiViewController.showPip(show: self.pip)
        uiViewController.authenticationService = self.authenticationService
        uiViewController.destination = self.destination
        uiViewController.hasVideo = self.hasVideo
        uiViewController.callKitManager = self.callKitManager
        uiViewController.acbuc = self.acbuc!
        let call = self.fcsdkCallService
        
        if call.hasStartedConnecting {
            Task {
                await uiViewController.currentState(state: .hasStartedConnecting)
            }
        }
        
        if call.isRinging {
            Task {
                await uiViewController.currentState(state: .isRinging)
            }
        }
        
        if call.hasConnected {
            Task {
                await uiViewController.currentState(state: .hasConnected)
            }
        }
        
        if holdID != context.coordinator.previousHoldID {
            Task {
                await uiViewController.currentState(state: .hold)
            }
            context.coordinator.previousHoldID = holdID
        }
        
        if resumeID != context.coordinator.previousResumeID {
            Task {
                await uiViewController.currentState(state: .resume)
            }
            context.coordinator.previousResumeID = resumeID
        }
        
        if muteVideoID != context.coordinator.previousMuteVideoID {
            Task {
                await uiViewController.currentState(state: .muteVideo)
            }
            context.coordinator.previousMuteVideoID = muteVideoID
        }
        
        if resumeVideoID != context.coordinator.previousResumeVideoID {
            Task {
                await uiViewController.currentState(state: .resumeVideo)
            }
            context.coordinator.previousResumeVideoID = resumeVideoID
        }
        
        if muteAudioID != context.coordinator.previousMuteAudioID {
            Task {
                await uiViewController.currentState(state: .muteAudio)
            }
            context.coordinator.previousMuteAudioID = muteAudioID
        }
        
        if resumeAudioID != context.coordinator.previousResumeAudioID {
            Task {
                await uiViewController.currentState(state: .resumeAudio)
            }
            context.coordinator.previousResumeAudioID = resumeAudioID
        }
        
        if cameraFrontID != context.coordinator.previousCameraFrontID {
            Task {
                await uiViewController.currentState(state: .cameraFront)
            }
            context.coordinator.previousCameraFrontID = cameraFrontID
        }
        if cameraBackID != context.coordinator.previousCameraBackID {
            Task {
                await uiViewController.currentState(state: .cameraBack)
            }
            context.coordinator.previousCameraBackID = cameraBackID
        }
        
        if closeClickID != context.coordinator.previousCloseClickID {
            Task {
                await uiViewController.endCall()
                await uiViewController.currentState(state: .hasEnded)
            }
            self.isOutgoing = false
            context.coordinator.previousCloseClickID = closeClickID
        }
        
        
        if self.pip {
            uiViewController.showPip(show: true)
        }
        
        if self.removePip {
            uiViewController.showPip(show: false)
        }
        
    }
    
    class Coordinator: NSObject, FCSDKCallDelegate {
        
        var parent: CommunicationViewControllerRepresentable
        var previousCloseClickID: UUID? = nil
        var previousCameraFrontID: UUID? = nil
        var previousCameraBackID: UUID? = nil
        var previousResumeAudioID: UUID? = nil
        var previousMuteAudioID: UUID? = nil
        var previousHoldID: UUID? = nil
        var previousResumeID: UUID? = nil
        var previousMuteVideoID: UUID? = nil
        var previousResumeVideoID: UUID? = nil
        
        init(_ parent: CommunicationViewControllerRepresentable) {
            self.parent = parent
        }
        
        @MainActor
        func passCallToService(_ call: FCSDKCall) async {
            self.parent.fcsdkCall = call
        }
        
        
        func passViewsToService(preview: SamplePreviewVideoCallView, remoteView: SampleBufferVideoCallView) async {
            await self.parent.fcsdkCall?.previewView = preview
            await self.parent.fcsdkCall?.remoteView = remoteView
            
            if await self.parent.autoAnswer {
                do {
                    if await self.parent.fcsdkCall?.call != nil {
                        try await self.parent.fcsdkCallService.answerFCSDKCall()
                    }
                } catch {
                    print("OUR ERROR: \(OurErrors.nilACBUC.rawValue) - Specifically: \(error) ")
                }
            }
        }
    }
    
    func setServiceHasEnded() async {
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
    case nilDelegate = "The FCSDKStore delegate is nil"
}
