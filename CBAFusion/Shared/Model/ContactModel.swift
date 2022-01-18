//
//  ContactModelDTO.swift
//  CBAFusion
//
//  Created by Cole M on 11/17/21.
//

import Foundation
import FCSDKiOS

public final class ContactModel: Hashable {
    
    public let listID = UUID()
    public let id: UUID
    public let username: String
    public let number: String
    public let calls: [FCSDKCall]?
    public let blocked: Bool?
    public var createdAt: Date? = nil
    public var updatedAt: Date? = nil
    public var deletedAt: Date? = nil
    
    public init(
        id: UUID,
        username: String,
        number: String,
        calls: [FCSDKCall]?,
        blocked: Bool?,
        createdAt: Date? = nil,
        updatedAt: Date? = nil,
        deletedAt: Date? = nil
    ) {
        self.id = id
        self.username = username
        self.number = number
        self.calls = calls
        self.blocked = blocked
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
    }
    
    public static func == (lhs: ContactModel, rhs: ContactModel) -> Bool {
        return lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        id.hash(into: &hasher)
    }
    
}
