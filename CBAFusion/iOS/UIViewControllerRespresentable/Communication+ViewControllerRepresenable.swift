//
//  Communication+ViewControllerRepresenable.swift
//  CBAFusion
//
//  Created by Cole M on 9/1/21.
//

import UIKit
import SwiftUI
import FCSDKiOS
import Logging
import AVFoundation

struct CommunicationViewControllerRepresentable: UIViewControllerRepresentable {
    
    @Binding var pip: Bool
    @Binding var removePip: Bool
    @Binding var destination: String
    @Binding var hasVideo: Bool
    @Binding var muteVideo: Bool
    @Binding var muteAudio: Bool
    @Binding var hold: Bool
    @Binding var isOutgoing: Bool
    @Binding var currentCall: FCSDKCall?
    @Binding var closeClickID: UUID?
    @Binding var cameraFrontID: UUID?
    @Binding var cameraBackID: UUID?
    @Binding var holdID: UUID?
    @Binding var resumeID: UUID?
    @Binding var muteAudioID: UUID?
    @Binding var resumeAudioID: UUID?
    @Binding var muteVideoID: UUID?
    @Binding var resumeVideoID: UUID?
    @State var blurView: Bool = false
    @EnvironmentObject var callKitManager: CallKitManager
    @EnvironmentObject var fcsdkCallService: FCSDKCallService
    @EnvironmentObject var authenticationService: AuthenticationService
    @EnvironmentObject var contactService: ContactService
    var logger: Logger?
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<CommunicationViewControllerRepresentable>) -> CommunicationViewController {
      
        let communicationViewController = CommunicationViewController(
            callKitManager: self.callKitManager,
            fcsdkCallService: self.fcsdkCallService,
            contactService: self.contactService,
            destination: self.destination,
            hasVideo: self.hasVideo,
            acbuc: self.authenticationService.acbuc!,
            isOutgoing: self.isOutgoing
        )
        communicationViewController.fcsdkCallDelegate = context.coordinator
        return communicationViewController

    }
    
    
    func updateUIViewController(_
                                uiViewController: CommunicationViewController,
                                context: UIViewControllerRepresentableContext<CommunicationViewControllerRepresentable>
    ) {
//        guard let c =  self.fcsdkCallService.currentCall?.remoteView else {return}
//        uiViewController.remoteView = c
        //        uiViewController.showPip(show: self.pip)
        uiViewController.authenticationService = self.authenticationService
        uiViewController.destination = self.destination
        uiViewController.hasVideo = self.hasVideo
        uiViewController.callKitManager = self.callKitManager
        uiViewController.acbuc = self.authenticationService.acbuc!
        let call = self.fcsdkCallService
      
        if call.hasStartedConnecting {
            Task {
                await uiViewController.currentState(state: .hasStartedConnecting)
                if self.isOutgoing {
                    await self.fcsdkCallService.playOutgoingRingtone()
                }
            }
        }
        
        if call.isRinging {
            Task {
                await uiViewController.currentState(state: .isRinging)
            }
        }
        
        if call.hasConnected {
            Task {
                if self.isOutgoing {
                await self.fcsdkCallService.stopOutgoingRingtone()
                }
                guard let remoteView = self.currentCall?.remoteView else { return }
                await uiViewController.updateRemoteViewForBuffer(view: remoteView)
                await uiViewController.currentState(state: .hasConnected)
              let l = self.currentCall?.remoteView?.layer as? AVSampleBufferDisplayLayer
                print("THE STATUS", l?.status.rawValue as Any)
            }
        }
        
        if holdID != context.coordinator.previousHoldID {
            Task {
                await uiViewController.currentState(state: .hold)
                blurView = true
            }
            context.coordinator.previousHoldID = holdID
        }
        
        if blurView {
            Task {
                await uiViewController.blurView()
            }
        }
        
        if resumeID != context.coordinator.previousResumeID {
            Task {
                await uiViewController.currentState(state: .resume)
                await uiViewController.removeBlurView()
                blurView = false
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
                do {
                    try await uiViewController.endCall()
                } catch {
                     self.logger?.error("\(error)")
                }
                    await setServiceHasEnded()
                    await uiViewController.currentState(state: .hasEnded)
                if self.isOutgoing {
                await self.fcsdkCallService.stopOutgoingRingtone()
                }
            }
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
            self.parent.currentCall = call
        }
        
        func passViewsToService(preview: UIView, remoteView: UIView) async {
            await self.parent.currentCall?.previewView = preview
            await self.parent.currentCall?.remoteView = remoteView
        }
    }
    
    @MainActor
    func setServiceHasEnded() async {
        if !self.fcsdkCallService.hasEnded {
            self.fcsdkCallService.hasEnded = true
            self.fcsdkCallService.connectDate = nil
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}


protocol FCSDKCallDelegate: AnyObject {
    func passCallToService(_ call: FCSDKCall) async
    func passViewsToService(preview: UIView, remoteView: UIView) async
}

enum OurErrors: String, Swift.Error {
    case nilACBUC = "Cannot initialize because ACBUC is nil"
    case nilFCSDKCall = "Cannot initialize because FCSDKCall is nil"
    case nilPreviewView = "Cannot set previewView because it is nil"
    case nilResolution = "Cannot get Resolution because it is nil"
    case nilFrameRate = "Cannot get frame rate because it is nil"
    case nilDelegate = "The FCSDKStore delegate is nil"
    case noCallKitCall = "There is not a CallKit Call in the Manager"
    case noContactID = "There is no a ContactID"
    case nilURL = "The URL is nil for network calls"
    case noActiveCalls = "There are not any Active Calls"
}
