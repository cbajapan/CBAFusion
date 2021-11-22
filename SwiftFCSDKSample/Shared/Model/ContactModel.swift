//
//  ContactModel.swift
//  SwiftFCSDKSample
//
//  Created by Cole M on 11/17/21.
//

import FluentSQLiteDriver
import Foundation
import FluentKit


final class _ContactModel: FluentKit.Model {
    static let schema = "contacts"

    @ID(key: .id) var id: UUID?
    @Field(key: "username") var username: String
    @Field(key: "number") var number: String

    init() {}

    init(contact: ContactModel, new: Bool) {
        self.id = contact.id
        self.username = contact.username
        self.number = contact.number
        $id.exists = !new
    }

    func makeContact() throws -> ContactModel {
        ContactModel(id: id!, username: username, number: number)
    }
}
