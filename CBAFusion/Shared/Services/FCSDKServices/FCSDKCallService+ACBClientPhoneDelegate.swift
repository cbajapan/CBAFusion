//
//  FCSDKCall+ACBClientPhoneDelegate.swift
//  CBAFusion
//
//  Created by Cole M on 10/4/21.
//

import Foundation
import AVFoundation
import FCSDKiOS
import SwiftUI

// Extension to handle phone call events using FCSDK
extension FCSDKCallService: ACBClientPhoneDelegate {
    
    // Called when a call is received
    func phone(_ phone: ACBClientPhone, received call: ACBClientCall) async {
        
        do {
            await MainActor.run {
                self.isOutgoing = false // Mark the call as incoming
            }
            try await self.contactService?.fetchContacts() // Fetch contacts
            
            let number = call.remoteAddress // Get the remote address (caller number)
            if let contact = self.contactService?.contacts?.first(where: { $0.number == number }) {
                // If the contact exists, create a call object
                await createCallObject(contact, call: call)
            } else {
                // If the contact does not exist, create a new contact
                let contact = ContactModel(
                    id: UUID(),
                    username: call.remoteDisplayName,
                    number: call.remoteAddress,
                    calls: [],
                    blocked: false
                )
                try await self.contactService?.delegate?.createContact(contact) // Create the new contact
                await createCallObject(contact, call: call) // Create a call object for the new contact
            }
        } catch {
            logger.error("\(error)") // Log any errors that occur
        }
    }
    
    // Creates a call object for the given contact
    func createCallObject(_ contact: ContactModel, call: ACBClientCall) async {
        guard let uc = delegate?.uc else { return } // Ensure the delegate is available
        
        let fcsdkCall = FCSDKCall(
            id: UUID(),
            handle: call.remoteAddress,
            hasVideo: call.hasRemoteVideo,
            communicationView: nil,
            acbuc: uc,
            call: call,
            activeCall: false,
            outbound: false,
            missed: false,
            rejected: false,
            contact: contact.id,
            createdAt: Date(),
            updatedAt: nil,
            deletedAt: nil
        )
        
        do {
            try await processInboundCall(fcsdkCall: fcsdkCall) // Process the inbound call
        } catch {
            self.logger.error("\(error)") // Log any errors that occur
        }
    }
    
    // Sets the current call object
    @MainActor
    private func setCall(fcsdkCall: FCSDKCall) {
        self.fcsdkCall = fcsdkCall
    }
    
    // Sets properties for the given call object
    @MainActor
    private func setProperties(from fcsdkCall: FCSDKCall) {
        var fcsdkCall = fcsdkCall
        fcsdkCall.missed = true
        fcsdkCall.outbound = false
        fcsdkCall.rejected = false
        fcsdkCall.activeCall = false
    }
    
    // Processes an inbound call
    func processInboundCall(fcsdkCall: FCSDKCall) async throws {
        var fcsdkCall = fcsdkCall
        let call = await self.contactService?.fetchActiveCall() // Fetch the active call
        
        if call?.activeCall == nil {
            
            fcsdkCall.missed = false
            fcsdkCall.outbound = false
            fcsdkCall.rejected = false
            fcsdkCall.activeCall = true
            
            await self.addCall(fcsdkCall: fcsdkCall) // Add the call to the call list
            self.setCall(fcsdkCall: fcsdkCall) // Set the current call
            
            guard let fcsdkCall = self.fcsdkCall else { throw OurErrors.nilFCSDKCall }
            await self.appDelegate?.displayIncomingCall(fcsdkCall: fcsdkCall) // Display the incoming call
        } else if call?.activeCall == true {
            // If there is an active call, end the current call and notify the user
            await fcsdkCall.call?.end()
            LocalNotification.newMessageNotification(
                title: "Missed Call",
                subtitle: "\(fcsdkCall.handle)",
                body: "You missed a call from \(fcsdkCall.call?.remoteDisplayName ?? "No Display Name")"
            )
            setProperties(from: fcsdkCall) // Set properties for the missed call
            await self.addCall(fcsdkCall: fcsdkCall) // Add the missed call to the call list
        }
    }
    
    // Called when the video capture settings change
    func phone(_ phone: ACBClientPhone, didChangeSettings settings: ACBVideoCaptureSetting, for camera: AVCaptureDevice.Position) async {
            self.logger.info("didChangeCaptureSetting - resolution=\(String(describing: settings.resolution.rawValue)) frame rate=\(String(describing: settings.frameRate)) camera=\(camera.rawValue)")
        }
}
