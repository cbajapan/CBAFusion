//
//  Communication+ViewControllerRepresentable.swift
//  CBAFusion
//
//  Created by Cole M on 9/1/21.
//

import UIKit
import SwiftUI
import FCSDKiOS
import Logging
import AVFoundation

/// A SwiftUI wrapper for the CommunicationViewController, allowing it to be used in SwiftUI views.
struct CommunicationViewControllerRepresentable: UIViewControllerRepresentable {
    
    // Binding properties for various states and configurations
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
    
    // Environment objects for managing call state and services
    @EnvironmentObject var callKitManager: CallKitManager
    @EnvironmentObject var fcsdkCallService: FCSDKCallService
    @EnvironmentObject var authenticationService: AuthenticationService
    @EnvironmentObject var contactService: ContactService
    @EnvironmentObject var pipStateObject: PipStateObject
    
    // User preferences for audio, resolution, and frame rate
    var selectedAudio = UserDefaults.standard.string(forKey: "AudioOption")
    var selectedResolution = UserDefaults.standard.string(forKey: "ResolutionOption")
    var selectedFrameRate = UserDefaults.standard.string(forKey: "RateOption")
    
    // Creates the CommunicationViewController instance
    func makeUIViewController(context: UIViewControllerRepresentableContext<CommunicationViewControllerRepresentable>) -> CommunicationViewController {
        let communicationViewController = CommunicationViewController(
            callKitManager: self.callKitManager,
            fcsdkCallService: self.fcsdkCallService,
            pipStateObject: self.pipStateObject,
            contactService: self.contactService,
            destination: self.destination,
            hasVideo: self.hasVideo,
            acbuc: authenticationService.uc!,
            isOutgoing: self.isOutgoing
        )
        communicationViewController.fcsdkCallDelegate = context.coordinator
        return communicationViewController
    }
    
    // Updates the CommunicationViewController with new state
    func updateUIViewController(_ uiViewController: CommunicationViewController, context: UIViewControllerRepresentableContext<CommunicationViewControllerRepresentable>) {
        // Update properties of the view controller
        uiViewController.authenticationService = self.authenticationService
        uiViewController.destination = self.destination
        uiViewController.hasVideo = self.hasVideo
        uiViewController.callKitManager = self.callKitManager
        
        let call = self.fcsdkCallService
        
        // Handle various states and transitions
        handleCallStates(call, uiViewController, context)
    }
    
    // Handles the different call states and updates the UI accordingly
    private func handleCallStates(_ call: FCSDKCallService, _ uiViewController: CommunicationViewController, _ context: UIViewControllerRepresentableContext<CommunicationViewControllerRepresentable>) {
        // Check if the call has started connecting
        if call.hasStartedConnecting {
            if hasStartedConnectingID != context.coordinator.previousHasStartedConnectingID {
                Task {
                    await uiViewController.currentState(state: .hasStartedConnecting)
                }
            }
            context.coordinator.previousHasStartedConnectingID = hasStartedConnectingID
        }
        
        // Check if the call is ringing
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
        
        // Check if the call has connected
        if call.hasConnected {
            if hasConnectedID != context.coordinator.previousHasConnectedID {
                Task { @MainActor in
                    await uiViewController.currentState(state: .hasConnected)
                    if self.isOutgoing {
                        self.fcsdkCallService.stopRing()
                    } else {
                        configureCallSettings()
                    }
                }
            }
            context.coordinator.previousHasConnectedID = hasConnectedID
        }
        
        // Handle Picture-in-Picture state
        if #available(iOS 15, *) {
            if pipStateObject.pipClickedID != context.coordinator.previousPipClickedID {
                context.coordinator.previousPipClickedID = pipStateObject.pipClickedID
                Task {
                    await uiViewController.showPip(show: pipStateObject.pip)
                }
            }
        }
        
        // Handle hold, resume, mute, and camera states
        handleStateChanges(uiViewController, context)
    }
    
    // Configures call settings based on user preferences
    private func configureCallSettings() {
        self.fcsdkCallService.selectResolution(res: ResolutionOptions(rawValue: self.selectedResolution ?? ResolutionOptions.auto.rawValue)!)
        self.fcsdkCallService.selectFramerate(rate: FrameRateOptions(rawValue: self.selectedFrameRate ?? FrameRateOptions.fro20.rawValue)!)
        self.fcsdkCallService.selectAudio(audio: ACBAudioDevice(rawValue: self.selectedAudio ?? ACBAudioDevice.speakerphone.rawValue)!)
    }
    
    // Handles state changes for hold, resume, mute, and camera
    private func handleStateChanges(_ uiViewController: CommunicationViewController, _ context: UIViewControllerRepresentableContext<CommunicationViewControllerRepresentable>) {
        // Handle hold state
        if holdID != context.coordinator.previousHoldID {
            Task {
                await uiViewController.currentState(state: .hold)
                blurViewID = UUID()
            }
            context.coordinator.previousHoldID = holdID
        }
        
        // Handle blur view state
        if blurViewID != context.coordinator.previousBlurViewID {
            Task {
                await uiViewController.blurView()
            }
            context.coordinator.previousBlurViewID = blurViewID
        }
        
        // Handle resume state
        if resumeID != context.coordinator.previousResumeID {
            Task {
                await uiViewController.currentState(state: .resume)
                await uiViewController.removeBlurView()
            }
            context.coordinator.previousResumeID = resumeID
        }
        
        // Handle mute and resume video/audio states
        handleMuteAndResumeStates(uiViewController, context)
        
        // Handle camera state changes
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
        
        // Handle close call action
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
    
    // Handles mute and resume states for audio and video
    private func handleMuteAndResumeStates(_ uiViewController: CommunicationViewController, _ context: UIViewControllerRepresentableContext<CommunicationViewControllerRepresentable>) {
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
    }
    
    // Creates the Coordinator for managing the communication state
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // Coordinator class for handling call delegate methods
    class Coordinator: NSObject, FCSDKCallDelegate {
        
        var parent: CommunicationViewControllerRepresentable
        
        // Previous state identifiers for tracking changes
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
    
    // Resets the service state when the call ends
    @MainActor
    func setServiceHasEnded() async {
        self.fcsdkCallService.connectDate = nil
        self.fcsdkCallService.hasEnded = false
        self.fcsdkCallService.presentCommunication = false
        self.fcsdkCallService.hasConnected = false
        self.fcsdkCallService.isStreaming = false
    }
}

// Protocol for handling call delegate methods
protocol FCSDKCallDelegate: AnyObject {
    func passCallToService(_ call: FCSDKCall) async
    func passViewsToService(communicationView: CommunicationView) async
}

// Enum for error handling
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
