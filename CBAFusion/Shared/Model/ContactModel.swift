//
//  ContactModelDTO.swift
//  CBAFusion
//
//  Created by Cole M on 11/17/21.
//

import Foundation
import FCSDKiOS

struct ContactModel: Hashable, Sendable {
    
  let listID = UUID()
  let id: UUID
  let username: String
  let number: String
  var calls: [FCSDKCall] = []
  let blocked: Bool?
  var createdAt: Date? = nil
  var updatedAt: Date? = nil
  var deletedAt: Date? = nil
    
    init(
        id: UUID,
        username: String,
        number: String,
        calls: [FCSDKCall] = [],
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
    
    static func == (lhs: ContactModel, rhs: ContactModel) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        id.hash(into: &hasher)
    }
    
}
