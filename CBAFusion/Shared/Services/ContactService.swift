//
//  ContactService.swift
//  CBAFusion
//
//  Created by Cole M on 11/17/21.
//

import Foundation
import SwiftUI
import UIKit
import FCSDKiOS
import Logging

protocol FCSDKStore: AnyObject, Sendable {
    func fetchContacts() async throws -> [ContactModel]?
    func createContact(_ contact: ContactModel) async throws
    func updateContact(_ contact: ContactModel) async throws
    func removeContact(_ contact: ContactModel) async throws
    
    func fetchActiveCalls() async throws -> [FCSDKCall]?
    func fetchCalls() async throws -> [FCSDKCall]?
    func fetchContactCalls(handle: String) async throws -> [FCSDKCall]?
    func createCall(_ contactID: UUID?, call: _CallsModel) async throws -> [ContactModel]?
    func updateCall(_ contactID: UUID, fcsdkCall: FCSDKCall) async throws -> [ContactModel]?
    func removeCall(_ contactID: UUID, fcsdkCall: FCSDKCall) async throws
    func removeCalls() async throws -> (Bool, [FCSDKCall]?)
}

extension FCSDKStore {
    func fetchContacts() async throws -> [ContactModel]? { return nil }
    func createContact(_ contact: ContactModel) async throws {}
    func updateContact(_ contact: ContactModel) async throws {}
    func removeContact(_ contact: ContactModel) async throws {}
    
    func fetchActiveCalls() async throws -> [FCSDKCall]? { return nil }
    func fetchCalls() async throws -> [FCSDKCall]? { return nil }
    func createCall(_ contactID: UUID?, call: _CallsModel) async throws  -> [ContactModel]? {return nil}
    func updateCall(_ contactID: UUID, fcsdkCall: FCSDKCall) async throws  -> [ContactModel]? {return nil}
    func removeCall(_ contactID: UUID, fcsdkCall: FCSDKCall) async throws {}
    func removeCalls() async throws -> (Bool, [FCSDKCall]?) { return (false, nil) }
}

@MainActor
final class ContactService: ObservableObject {
    
    
    @Published var username: String = ""
    @Published var number: String = ""
    var delegate: FCSDKStore?
    @Published var contacts: [ContactModel]?
    @Published var alert: Bool = false
    @Published var isEdit: Bool = false
    @Published var contactToEdit: ContactModel?
    @Published var addSheet: Bool = false
    @Published var selectedContact: ContactModel? = nil
    @Published var showProgress: Bool = false
    @Published var showError: Bool = false
    @Published var calls: [FCSDKCall] = []
    var logger: Logger
    
    init() {
        self.logger = Logger(label: "\(Constants.BUNDLE_IDENTIFIER) - Contact Service - ")
    }
    
    
    func addContact(_ contact: ContactModel?, isEdit: Bool) async {
        if !username.isEmpty || !number.isEmpty {
            let createContact = ContactModel(id: contact?.id ?? UUID(), username: username, number: number, calls: [], blocked: false)
            try? await addContactLogic(createContact)
        } else if username.isEmpty || number.isEmpty {
            guard let contact = contact else {
                return
            }
            try? await addContactLogic(contact)
        } else {
            await MainActor.run {
                self.alert = true
            }
        }
    }
    
    func addContactLogic(_ contact: ContactModel, fcsdkCall: FCSDKCall? = nil) async throws {
        do {
            if isEdit {
                try await delegate?.updateContact(contact)
            } else {
                try await delegate?.createContact(contact)
            }
            try await self.fetchContacts()
        } catch {
            self.logger.error("Add Contact Logic Error: - \(error)")
        }
    }
    
    @MainActor
    func clearToDismiss() async {
        username = ""
        number = ""
    }
    
    func fetchContacts() async throws {
        do {
            let contacts = try await delegate?.fetchContacts()
            await MainActor.run {
                self.contacts = contacts
            }
        } catch {
            self.logger.error("Error Fetching Contacts: \(error)")
        }
    }
    
    
    func deleteContact(contact: ContactModel) async {
        do {
            try await delegate?.removeContact(contact)
            try await fetchContacts()
        } catch {
            self.logger.error("Error deleting Calls: \(error)")
        }
    }
    
    func editContact(contact: ContactModel, isEdit: Bool) async {
        self.contactToEdit = contact
        self.isEdit = true
        self.addSheet = true
    }
    
    func addCall(_ contactID: UUID, fcsdkCall: FCSDKCall) async throws {
        do {
            let callModel = _CallsModel(call: fcsdkCall, contactID: contactID, new: true)
            let contacts = try await delegate?.createCall(contactID, call: callModel)
            await MainActor.run {
                self.contacts = contacts
            }
        } catch {
            self.logger.error("Error adding Call: \(error)")
        }
    }
    
    @MainActor
    func setCallsForContact(_ contact: ContactModel) async {
        self.calls = contact.calls
    }
    
    func fetchCalls() async throws {
        do {
            self.calls = try await delegate?.fetchCalls() ?? []
        } catch {
            self.logger.error("Error fetching all Calls: \(error)")
        }
    }
    
    func fetchContactCalls(_ destination: String) async throws {
        do {
            let calls = try await delegate?.fetchContactCalls(handle: destination)
            await MainActor.run {
                self.calls = calls ?? []
            }
        } catch {
            self.logger.error("Error fetching Calls: \(error)")
        }
    }
    
    func fetchActiveCall() async -> FCSDKCall? {
        var fcsdkCall: FCSDKCall?
        do {
            fcsdkCall = try await self.delegate?.fetchActiveCalls()?.first
        } catch {
            self.logger.error("Error fetching Active Call: \(error)")
        }
        return fcsdkCall
    }
    
    func deleteCall(fcsdkCall: FCSDKCall) async {
        do {
            try await delegate?.removeCall(fcsdkCall.contact!, fcsdkCall: fcsdkCall)
        } catch {
            self.logger.info("\(OurErrors.nilDelegate.rawValue)")
        }
    }
    
    func deleteCalls() async {
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.showProgress = true
        }
        do {
            let result = try await self.delegate?.removeCalls()
            Task { @MainActor [weak self] in
                guard let self else { return }
                if result?.0 == true {
                    self.calls = result?.1 ?? []
                    self.showProgress = false
                } else {
                    self.showProgress = false
                    self.showError = true
                }
            }
        } catch {
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.showProgress = false
                self.showError = true
            }
        }
        
    }
    
    func editCall(fcsdkCall: FCSDKCall) async {
        do {
            guard let contact = fcsdkCall.contact else { throw OurErrors.noContactID }
            let updated = try await self.delegate?.updateCall(contact, fcsdkCall: fcsdkCall)
            Task { @MainActor in
                self.contacts = updated
            }
        } catch {
            self.logger.error("Error Editing Call: \(error)")
        }
    }
}
