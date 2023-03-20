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

extension FCSDKCallService: ACBClientPhoneDelegate  {
    
    
    //Receive calls with FCSDK
//   @FCSDKTransportActor
    func phone(_ phone: ACBClientPhone, received call: ACBClientCall) async throws {
            await MainActor.run {
                self.isOutgoing = false
            }
            try await self.contactService?.fetchContacts()
            let number = call.remoteAddress
            if let contact = self.contactService?.contacts?.first(where: { $0.number == number } )  {
                await createCallObject(contact, call: call)
            } else {
                let contact = await ContactModel(
                    id: UUID(),
                    username: call.remoteDisplayName,
                    number: call.remoteAddress,
                    calls: nil,
                    blocked: false)
                try await self.contactService?.delegate?.createContact(contact)
                await createCallObject(contact, call: call)
            }
        }
    
    func createCallObject(_ contact: ContactModel, call: ACBClientCall) async {
        guard let uc = self.acbuc else { return }
        let fcsdkCall = FCSDKCall(
            id: UUID(),
            handle:  call.remoteAddress,
            hasVideo: call.hasRemoteVideo,
            previewView: nil,
            remoteView: nil,
            acbuc: uc,
            call: call,
            activeCall: false,
            outbound: false,
            missed: false,
            rejected: false,
            contact: contact.id,
            createdAt: Date(),
            updatedAt: nil,
            deletedAt: nil)
        do {
            try await processInboundCall(fcsdkCall: fcsdkCall)
        } catch {
            self.logger.error("\(error)")
        }
    }
    
//   @FCSDKTransportActor
    func processInboundCall(fcsdkCall: FCSDKCall) async throws {
        let call = await self.contactService?.fetchActiveCall()
        
        if call?.activeCall == nil {
//            await MainActor.run {
            fcsdkCall.call?.delegate = self
            self.fcsdkCall?.call?.delegate = fcsdkCall.call?.delegate
//            }
            
            fcsdkCall.missed = false
            fcsdkCall.outbound = false
            fcsdkCall.rejected = false
            fcsdkCall.activeCall = true
            await self.addCall(fcsdkCall: fcsdkCall)
            await MainActor.run {
                self.fcsdkCall = fcsdkCall
            }
                guard let fcsdkCall = self.fcsdkCall else { throw OurErrors.nilFCSDKCall }
                await self.appDelegate?.displayIncomingCall(fcsdkCall: fcsdkCall)
        } else if call?.activeCall == true {
            await fcsdkCall.call?.end()
            LocalNotification.newMessageNotification(title: "Missed Call", subtitle: "\(fcsdkCall.handle)", body: "You missed a call from \( await fcsdkCall.call?.remoteDisplayName ?? "No Display Name")")
            await MainActor.run {
                fcsdkCall.missed = true
                fcsdkCall.outbound = false
                fcsdkCall.rejected = false
                fcsdkCall.activeCall = false
            }
            await self.addCall(fcsdkCall: fcsdkCall)
        }
    }
    
    func phone(_ phone: ACBClientPhone, didChange settings: ACBVideoCaptureSetting?, forCamera camera: AVCaptureDevice.Position) async {
        self.logger.info("didChangeCaptureSetting - resolution=\(String(describing: settings?.resolution.rawValue)) frame rate=\(String(describing: settings?.frameRate)) camera=\(camera.rawValue)")
    }
}
