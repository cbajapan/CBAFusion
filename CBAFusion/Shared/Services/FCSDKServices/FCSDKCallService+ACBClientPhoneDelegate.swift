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
    func phone(_ phone: ACBClientPhone, received call: ACBClientCall) async {
        call.delegate = self
        do {
            await MainActor.run {
                self.isOutgoing = false
            }
            try await self.contactService?.fetchContacts()
            let number = call.remoteAddress
            if let contact = self.contactService?.contacts?.first(where: { $0.number == number } )  {
                await createCallObject(contact, call: call)
            } else {
                let contact = ContactModel(
                    id: UUID(),
                    username: call.remoteDisplayName,
                    number: call.remoteAddress,
                    calls: [],
                    blocked: false
                )
                try await self.contactService?.delegate?.createContact(contact)
                await createCallObject(contact, call: call)
            }
        } catch {
            logger.error("\(error)")
        }
    }
    
    func createCallObject(_ contact: ContactModel, call: ACBClientCall) async {
        guard let uc = delegate?.uc else { return }
        let fcsdkCall = FCSDKCall(
            id: UUID(),
            handle:  call.remoteAddress,
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
            try await processInboundCall(fcsdkCall: fcsdkCall)
        } catch {
            self.logger.error("\(error)")
        }
    }
    
    @MainActor
    private func setCall(fcsdkCall: FCSDKCall) {
        self.fcsdkCall = fcsdkCall
    }
    
    @MainActor
    private func setProperties(from fcsdkCall: FCSDKCall) {
        var fcsdkCall = fcsdkCall
        fcsdkCall.missed = true
        fcsdkCall.outbound = false
        fcsdkCall.rejected = false
        fcsdkCall.activeCall = false
    }
    
    func processInboundCall(fcsdkCall: FCSDKCall) async throws {
        var fcsdkCall = fcsdkCall
        let call = await self.contactService?.fetchActiveCall()
        
        if call?.activeCall == nil {
            fcsdkCall.call?.delegate = self
            self.fcsdkCall?.call?.delegate = fcsdkCall.call?.delegate
            
            fcsdkCall.missed = false
            fcsdkCall.outbound = false
            fcsdkCall.rejected = false
            fcsdkCall.activeCall = true
            await self.addCall(fcsdkCall: fcsdkCall)
            self.setCall(fcsdkCall: fcsdkCall)
            guard let fcsdkCall = self.fcsdkCall else { throw OurErrors.nilFCSDKCall }
            await self.appDelegate?.displayIncomingCall(fcsdkCall: fcsdkCall)
        } else if call?.activeCall == true {
            await fcsdkCall.call?.end()
            LocalNotification.newMessageNotification(title: "Missed Call", subtitle: "\(fcsdkCall.handle)", body: "You missed a call from \(fcsdkCall.call?.remoteDisplayName ?? "No Display Name")")
            setProperties(from: fcsdkCall)
            await self.addCall(fcsdkCall: fcsdkCall)
        }
    }
    
    func phone(_ phone: ACBClientPhone, didChange settings: ACBVideoCaptureSetting?, forCamera camera: AVCaptureDevice.Position) async {
        self.logger.info("didChangeCaptureSetting - resolution=\(String(describing: settings?.resolution.rawValue)) frame rate=\(String(describing: settings?.frameRate)) camera=\(camera.rawValue)")
    }
}
