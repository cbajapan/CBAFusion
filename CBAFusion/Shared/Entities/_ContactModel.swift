//
//  ContactModel.swift
//  CBAFusion
//
//  Created by Cole M on 11/17/21.
//

import FluentSQLiteDriver
import Foundation
import FluentKit


final class _ContactModel: FluentKit.Model, @unchecked Sendable {
    static let schema = "contact"

    @ID(key: .id) var id: UUID?
    @Field(key: "username") var username: String
    @Field(key: "number") var number: String
    @Field(key: "blocked") var blocked: Bool?
    @Children(for: \.$contact) var calls: [_CallsModel]
    @Timestamp(key: "created_at", on: .create) var createdAt: Date?
    @Timestamp(key: "updated_at", on: .update) var updatedAt: Date?
    @Timestamp(key: "deleted_at", on: .delete) var deletedAt: Date?

    init() {}

    init(contact: ContactModel, new: Bool) {
        self.id = contact.id
        $id.exists = !new
        self.username = contact.username
        self.number = contact.number
        self.blocked = contact.blocked
        self.createdAt = contact.createdAt
        self.updatedAt = contact.updatedAt
        self.deletedAt = contact.deletedAt
    }
    
//    func makeContact() throws -> ContactModel {
//        ContactModel(id: id!, username: username, number: number, calls: calls, blocked: blocked, createdAt: createdAt, updatedAt: updatedAt, deletedAt: deletedAt)
//    }
}
