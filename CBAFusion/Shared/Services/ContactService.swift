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

// MARK: - ContactService Class

@MainActor
final class ContactService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var username: String = ""
    @Published var number: String = ""
    @Published var contacts: [ContactModel]?
    @Published var alert: Bool = false
    @Published var isEdit: Bool = false
    @Published var contactToEdit: ContactModel?
    @Published var addSheet: Bool = false
    @Published var selectedContact: ContactModel? = nil
    @Published var showProgress: Bool = false
    @Published var showError: Bool = false
    @Published var calls: [FCSDKCall] = []
    
    // MARK: - Properties
    var delegate: FCSDKStore?
    var logger: Logger
    
    // MARK: - Initializer
    init() {
        self.logger = Logger(label: "\(Constants.BUNDLE_IDENTIFIER) - Contact Service - ")
    }
    
    // MARK: - Contact Management Methods
    
    /// Adds a contact, either creating a new one or updating an existing one.
    /// - Parameters:
    ///   - contact: The contact to add or update.
    ///   - isEdit: A boolean indicating if the contact is being edited.
    func addContact(_ contact: ContactModel?, isEdit: Bool) async {
        guard !username.isEmpty || !number.isEmpty else {
            await MainActor.run { self.alert = true }
            return
        }
        
        let createContact = ContactModel(id: contact?.id ?? UUID(), username: username, number: number, calls: [], blocked: false)
        do {
            try await addContactLogic(createContact, isEdit: isEdit)
        } catch {
            logger.error("Error adding contact: \(error)")
        }
    }
    
    /// Logic for adding or updating a contact.
    /// - Parameters:
    ///   - contact: The contact to add or update.
    ///   - isEdit: A boolean indicating if the contact is being edited.
    private func addContactLogic(_ contact: ContactModel, isEdit: Bool) async throws {
        if isEdit {
            try await delegate?.updateContact(contact)
        } else {
            try await delegate?.createContact(contact)
        }
        try await fetchContacts()
    }
    
    /// Fetches the list of contacts.
    func fetchContacts() async throws {
        do {
            let fetchedContacts = try await delegate?.fetchContacts()
            await MainActor.run { self.contacts = fetchedContacts }
        } catch {
            logger.error("Error fetching contacts: \(error)")
        }
    }
    
    /// Deletes a contact.
    /// - Parameter contact: The contact to delete.
    func deleteContact(contact: ContactModel) async {
        do {
            try await delegate?.removeContact(contact)
            try await fetchContacts()
        } catch {
            logger.error("Error deleting contact: \(error)")
        }
    }
    
    /// Prepares to edit a contact.
    /// - Parameters:
    ///   - contact: The contact to edit.
    ///   - isEdit: A boolean indicating if the contact is being edited.
    func editContact(contact: ContactModel, isEdit: Bool) async {
        self.contactToEdit = contact
        self.isEdit = true
        self.addSheet = true
    }
    
    // MARK: - Call Management Methods
    
    /// Adds a call for a contact.
    /// - Parameters:
    ///   - contactID: The ID of the contact.
    ///   - fcsdkCall: The call to add.
    func addCall(_ contactID: UUID, fcsdkCall: FCSDKCall) async throws {
        let callModel = _CallsModel(call: fcsdkCall, contactID: contactID, new: true)
        do {
            let updatedContacts = try await delegate?.createCall(contactID, call: callModel)
            await MainActor.run { self.contacts = updatedContacts }
        } catch {
            logger.error("Error adding call: \(error)")
        }
    }
    
    /// Fetches all calls.
    func fetchCalls() async throws {
        do {
            self.calls = try await delegate?.fetchCalls() ?? []
        } catch {
            logger.error("Error fetching all calls: \(error)")
        }
    }
    
    /// Fetches calls for a specific contact.
    /// - Parameter destination: The contact's handle.
    func fetchContactCalls(_ destination: String) async throws {
        do {
            let fetchedCalls = try await delegate?.fetchContactCalls(handle: destination)
            await MainActor.run { self.calls = fetchedCalls ?? [] }
        } catch {
            logger.error("Error fetching calls: \(error)")
        }
    }
    
    /// Fetches the active call.
    /// - Returns: The active call, if available.
    func fetchActiveCall() async -> FCSDKCall? {
        do {
            return try await delegate?.fetchActiveCalls()?.first
        } catch {
            logger.error("Error fetching active call: \(error)")
            return nil
        }
    }
    
    /// Deletes a specific call.
    /// - Parameter fcsdkCall: The call to delete.
    func deleteCall(fcsdkCall: FCSDKCall) async {
        do {
            guard let contactID = fcsdkCall.contact else { throw OurErrors.noContactID }
            try await delegate?.removeCall(contactID, fcsdkCall: fcsdkCall)
        } catch {
            logger.error("Error deleting call: \(error)")
        }
    }
    
    /// Deletes all calls.
    func deleteCalls() async {
        showProgress = true
        do {
            let result = try await delegate?.removeCalls()
            await MainActor.run {
                self.showProgress = false
                if result?.0 == true {
                    self.calls = result?.1 ?? []
                } else {
                    self.showError = true
                }
            }
        } catch {
            await MainActor.run {
                self.showProgress = false
                self.showError = true
            }
            logger.error("Error deleting calls: \(error)")
        }
    }
    
    /// Edits a specific call.
    /// - Parameter fcsdkCall: The call to edit.
    func editCall(fcsdkCall: FCSDKCall) async {
        do {
            guard let contactID = fcsdkCall.contact else { throw OurErrors.noContactID }
            let updatedContacts = try await delegate?.updateCall(contactID, fcsdkCall: fcsdkCall)
            await MainActor.run { self.contacts = updatedContacts }
        } catch {
            logger.error("Error editing call: \(error)")
        }
    }
    
    /// Clears the input fields to dismiss the add/edit sheet.
    func clearToDismiss() async {
        username = ""
        number = ""
    }
}
