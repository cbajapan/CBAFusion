//
//  Communication+ViewControllerRepresenable.swift
//  SwiftFCSDKSample
//
//  Created by Cole M on 9/1/21.
//

import UIKit
import SwiftUI
import FCSDKiOS

struct CommunicationViewControllerRepresentable: UIViewControllerRepresentable {
    
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
        
        if self.hold {
            Task {
                await uiViewController.currentState(state: .hold)
            }
        }
        
        if self.resume {
            Task {
                await uiViewController.currentState(state: .resume)
            }
        }
        
        if self.muteVideo {
            Task {
                await uiViewController.currentState(state: .muteVideo)
            }
        }
        
        if self.resumeVideo {
            Task {
                await uiViewController.currentState(state: .resumeVideo)
            }
        }
        
        if self.muteAudio {
            Task {
                await uiViewController.currentState(state: .muteAudio)
            }
        }
        
        if self.resumeAudio {
            Task {
                await uiViewController.currentState(state: .resumeAudio)
            }
        }
        
        if self.cameraFront {
            Task {
                await uiViewController.currentState(state: .cameraFront)
            }
        }
        if self.cameraBack {
            Task {
                await uiViewController.currentState(state: .cameraBack)
            }
        }
        
        
        if call.hasEnded {
            if !self.endCall {
                Task {
                    await uiViewController.endCall()
                }
            }
            self.isOutgoing = false
            Task {
                await uiViewController.currentState(state: .hasEnded)
            }
        }
        
        if self.endCall {
            if !call.hasEnded {
                Task {
                    await self.fcsdkCallService.endFCSDKCall()
                    await uiViewController.endCall()
                    await uiViewController.currentState(state: .hasEnded)
                }
            } else {
                //dismiss view
                Task {
                    await uiViewController.currentState(state: .hasEnded)
                }
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
        
        var parent: CommunicationViewControllerRepresentable
        
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
    case nilDelegate = "The delegate is nil"
}
