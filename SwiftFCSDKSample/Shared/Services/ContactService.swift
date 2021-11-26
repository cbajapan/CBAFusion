//
//  ContactService.swift
//  SwiftFCSDKSample
//
//  Created by Cole M on 11/17/21.
//

import Foundation
import SwiftUI
import UIKit

protocol FCSDKStore: AnyObject {
    func fetchContacts() async throws -> [ContactModel]
    func createContact(_ contact: ContactModel) async throws
    func updateContact(_ contact: ContactModel) async throws
    func removeContact(_ contact: ContactModel) async throws
    
}


class ContactService: ObservableObject {
    @Published var username: String = ""
    @Published var number: String = ""
    @Published var delegate: FCSDKStore?
    @Published var contacts: [ContactModel]?
    @Published var alert: Bool = false
    @Published var isEdit: Bool = false
    @Published var contactToEdit: ContactModel?
    @Published var addSheet: Bool = false
    
    init() {}
    
    
    func addContact(_ contact: ContactModel?, isEdit: Bool) async {
        if !username.isEmpty || !number.isEmpty {
            do {
                guard let del = delegate else { throw OurErrors.nilDelegate }
                let contact = ContactModel(id: contact?.id ?? UUID(), username: username, number: number)
                if isEdit {
                    try await del.updateContact(contact)
                } else {
                    try await del.createContact(contact)
                }
                try? await self.fetchContacts()
            } catch {
                print(error)
            }
        } else {
            self.alert = true
        }
    }
    
    func clearToDismiss() async {
        username = ""
        number = ""
    }
    
    @MainActor
    func fetchContacts() async throws {
        do {
            guard let del = self.delegate else { throw OurErrors.nilDelegate }
            self.contacts = try await del.fetchContacts()
        } catch {
            print(error)
        }
    }
    

    func deleteContact(contact: ContactModel) async {
        do {
            guard let del = self.delegate else { throw OurErrors.nilDelegate }
            try await del.removeContact(contact)
            try? await fetchContacts()
        } catch {
            print(error)
        }
    }
    
    func editContact(contact: ContactModel, isEdit: Bool) async {
        self.contactToEdit = contact
        self.isEdit = true
        self.addSheet = true
    }
}
