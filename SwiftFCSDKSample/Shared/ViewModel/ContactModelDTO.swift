//
//  ContactModelDTO.swift
//  SwiftFCSDKSample
//
//  Created by Cole M on 11/17/21.
//

import Foundation

public final class ContactModel: Hashable {
    
    public let id: UUID
    public let username: String
    public let number: String
    
    public init(
        id: UUID,
        username: String,
        number: String
    ) {
        self.id = id
        self.username = username
        self.number = number
    }
    
    public static func == (lhs: ContactModel, rhs: ContactModel) -> Bool {
        return lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        id.hash(into: &hasher)
    }
    
}
