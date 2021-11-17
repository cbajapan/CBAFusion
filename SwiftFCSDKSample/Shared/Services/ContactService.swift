//
//  ContactService.swift
//  SwiftFCSDKSample
//
//  Created by Cole M on 11/17/21.
//

import Foundation
import SwiftUI

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
    
    
    init() {}
    
    func addContact() async {
        let contact = ContactModel(id: UUID(), username: username, number: number)
        do {
            guard let del = delegate else { throw OurErrors.nilDelegate }
            try await del.createContact(contact)
            try? await self.fetchContacts()
        } catch {
            print(error)
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
}
