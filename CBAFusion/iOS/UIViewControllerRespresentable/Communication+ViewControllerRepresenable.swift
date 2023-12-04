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
    
    @Binding var removePip: Bool
    @Binding var destination: String
    @Binding var hasVideo: Bool
    @Binding var muteVideo: Bool
    @Binding var muteAudio: Bool
    @Binding var hold: Bool
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
    @Binding var hasStartedConnectingID: UUID?
    @Binding var ringingID: UUID?
    @Binding var hasConnectedID: UUID?
    @State var blurViewID: UUID?
    @EnvironmentObject var callKitManager: CallKitManager
    @EnvironmentObject var fcsdkCallService: FCSDKCallService
    @EnvironmentObject var authenticationService: AuthenticationService
    @EnvironmentObject var contactService: ContactService
    @EnvironmentObject var pipStateObject: PipStateObject
    
    var selectedAudio = UserDefaults.standard.string(forKey: "AudioOption")
    var selectedResolution = UserDefaults.standard.string(forKey: "ResolutionOption")
    var selectedFrameRate = UserDefaults.standard.string(forKey: "RateOption")
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<CommunicationViewControllerRepresentable>) -> CommunicationViewController {
        
        let communicationViewController = CommunicationViewController(
            callKitManager: self.callKitManager,
            fcsdkCallService: self.fcsdkCallService,
            contactService: self.contactService,
            destination: self.destination,
            hasVideo: self.hasVideo,
            acbuc: authenticationService.acbuc!,
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
                Task { @MainActor in
                    guard let newView = fcsdkCallService.fcsdkCall?.communicationView else { return }
                    uiViewController.view = newView
                    
#if !targetEnvironment(simulator)
                    if #available(iOS 15.0.0, *), fcsdkCallService.isBuffer {
                        await uiViewController.layoutPipLayer()
                    }
#endif
                    await uiViewController.currentState(state: .hasConnected)
                    if self.isOutgoing {
                        self.fcsdkCallService.stopRing()
                    } else {
                        self.fcsdkCallService.selectResolution(res: ResolutionOptions(rawValue: self.selectedResolution ?? ResolutionOptions.auto.rawValue)!)
                        self.fcsdkCallService.selectFramerate(rate: FrameRateOptions(rawValue: self.selectedFrameRate ?? FrameRateOptions.fro20.rawValue)!)
                        self.fcsdkCallService.selectAudio(audio: ACBAudioDevice(rawValue: self.selectedAudio ?? ACBAudioDevice.speakerphone.rawValue)!)
                    }
                }
            }
            context.coordinator.previousHasConnectedID = hasConnectedID
        }
        
        if #available(iOS 15, *) {
            if pipStateObject.pipClickedID != context.coordinator.previousPipClickedID {
                Task {
                    await uiViewController.showPip(show: pipStateObject.pip)
                }
                context.coordinator.previousPipClickedID = pipStateObject.pipClickedID
            }
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
                   print("Error ending call - Error: \(error)")
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
            self.parent.fcsdkCall = call
        }
        
        @MainActor
        func passViewsToService(communicationView: CommunicationView) async {
           self.parent.fcsdkCall?.communicationView = communicationView
        }
    }
    
    @MainActor
    func setServiceHasEnded() async {
        self.fcsdkCallService.connectDate = nil
        self.fcsdkCallService.hasEnded = false
        self.fcsdkCallService.presentCommunication = false
        self.fcsdkCallService.hasConnected = false
        self.fcsdkCallService.isStreaming = false
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}


protocol FCSDKCallDelegate: AnyObject {
    func passCallToService(_ call: FCSDKCall) async
    func passViewsToService(communicationView: CommunicationView) async
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
