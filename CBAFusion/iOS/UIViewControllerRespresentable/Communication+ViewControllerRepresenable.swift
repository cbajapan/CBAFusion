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
    @Binding var pipClickedID: UUID?
    @Binding var hasStartedConnectingID: UUID?
    @Binding var ringingID: UUID?
    @Binding var hasConnectedID: UUID?
    @State var blurViewID: UUID?
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
        
        uiViewController.authenticationService = self.authenticationService
        uiViewController.destination = self.destination
        uiViewController.hasVideo = self.hasVideo
        uiViewController.callKitManager = self.callKitManager
        uiViewController.acbuc = self.authenticationService.acbuc!
        let call = self.fcsdkCallService
        
        if call.hasStartedConnecting {
            if hasStartedConnectingID != context.coordinator.previousHasStartedConnectingID {
                Task {
                    await uiViewController.currentState(state: .hasStartedConnecting)
                }
            }
            context.coordinator.previousHasStartedConnectingID = hasStartedConnectingID
        }
        
        
        if call.isRinging {
            if ringingID != context.coordinator.previousRingingID {
                Task {
                    await uiViewController.currentState(state: .isRinging)
                    if self.isOutgoing {
                        self.fcsdkCallService.startRing()
                    }
                }
            }
            context.coordinator.previousRingingID = ringingID
        }
        
        if call.hasConnected {
            if hasConnectedID != context.coordinator.previousHasConnectedID {
                Task {
//#if !targetEnvironment(simulator)
//                    if #available(iOS 15.0.0, *) {
//                        guard let remoteView = self.currentCall?.remoteView else { return }
//                        await uiViewController.updateRemoteViewForBuffer(view: remoteView)
//                    }
//#endif
                    await uiViewController.currentState(state: .hasConnected)
                    if self.isOutgoing {
                        self.fcsdkCallService.stopRing()
                    }
                }
            }
            context.coordinator.previousHasConnectedID = hasConnectedID
        }
        
        
        if pipClickedID != context.coordinator.previousPipClickedID {
            Task {
                await uiViewController.showPip(show: self.pip)
            }
            context.coordinator.previousPipClickedID = pipClickedID
        }
        
        if holdID != context.coordinator.previousHoldID {
            Task {
                await uiViewController.currentState(state: .hold)
                blurViewID = UUID()
            }
            context.coordinator.previousHoldID = holdID
        }
        
        if blurViewID != context.coordinator.previousBlurViewID {
            Task {
                await uiViewController.blurView()
            }
            context.coordinator.previousBlurViewID = blurViewID
        }
        
        if resumeID != context.coordinator.previousResumeID {
            Task {
                await uiViewController.currentState(state: .resume)
                await uiViewController.removeBlurView()
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
                    self.fcsdkCallService.stopRing()
                }
            }
            context.coordinator.previousCloseClickID = closeClickID
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
        var previousPipClickedID: UUID? = nil
        var previousHasStartedConnectingID: UUID? = nil
        var previousRingingID: UUID? = nil
        var previousHasConnectedID: UUID? = nil
        var previousBlurViewID: UUID? = nil
        
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
    case nilACBClientCall = "ACBClientCall is nil"
    case nilPreviewView = "Cannot set previewView because it is nil"
    case nilResolution = "Cannot get Resolution because it is nil"
    case nilFrameRate = "Cannot get frame rate because it is nil"
    case nilDelegate = "The FCSDKStore delegate is nil"
    case noCallKitCall = "There is not a CallKit Call in the Manager"
    case noContactID = "There is no a ContactID"
    case nilURL = "The URL is nil for network calls"
    case noActiveCalls = "There are not any Active Calls"
    case noNetworkManager = "The network manager delegate needs set"
}
