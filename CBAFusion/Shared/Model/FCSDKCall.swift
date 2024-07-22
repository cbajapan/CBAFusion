//
//  FCSDKCall.swift
//  
//
//  Created by Cole M on 12/22/21.
//

import FCSDKiOS
import UIKit

/// This Model is a call object that can be used in making FCSDK Calls with or with out CallKit
struct FCSDKCall: Codable, Hashable, Sendable {
    
    var id: UUID
    /// The destination to call
    var handle: String
    /// Lets CallKit know if we want to use video
    var hasVideo: Bool
    /// Our View Controllers view that we use to update it's content.
    var communicationView: CommunicationView? = nil
    /// Our ACBUC Object
    var acbuc: ACBUC? = nil
    /// The ACBClientCall associated with this CallObject
    weak var call: ACBClientCall? = nil
    /// A boolean value that determines if the call is an active call
    var activeCall: Bool? = false
    /// A boolean value indicating if the call is an outbound call
    var outbound: Bool? = false
    /// A boolean value to indicate if we missed the call
    var missed: Bool? = false
    /// A boolean value to indicate if we rejected the call
    var rejected: Bool? = false
    /// The UUID for the parent Contact Model
    var contact: UUID? = nil
    /// Date of creation
    var createdAt: Date? = nil
    /// Date updated
    var updatedAt: Date? = nil
    /// Date  deleted
    var deletedAt: Date? = nil
    
    init(
        id: UUID,
        handle: String,
        hasVideo: Bool,
        communicationView: CommunicationView? = nil,
        acbuc: ACBUC? = nil,
        call: ACBClientCall? = nil,
        activeCall: Bool? = false,
        outbound: Bool? = nil,
        missed: Bool? = nil,
        rejected: Bool? = false,
        contact: UUID? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil,
        deletedAt: Date? = nil
    ) {
        self.id = id
        self.handle = handle
        self.hasVideo = hasVideo
        self.communicationView = communicationView
        self.acbuc = acbuc
        self.call = call
        self.activeCall = activeCall
        self.outbound = outbound
        self.missed = missed
        self.rejected = rejected
        self.contact = contact
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
    }
    
    enum CodingKeys: String, CodingKey {
        case id, handle, hasVideo, activeCall, outbound, missed, rejected, contact, createdAt, updatedAt, deletedAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.handle = try container.decode(String.self, forKey: .handle)
        self.hasVideo = try container.decode(Bool.self, forKey: .hasVideo)
        self.activeCall = try container.decode(Bool.self, forKey: .activeCall)
        self.outbound = try container.decode(Bool.self, forKey: .outbound)
        self.missed = try container.decode(Bool.self, forKey: .missed)
        self.rejected = try container.decode(Bool.self, forKey: .rejected)
        self.contact = try container.decodeIfPresent(UUID.self, forKey: .contact)
        self.createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        self.updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
        self.deletedAt = try container.decodeIfPresent(Date.self, forKey: .deletedAt)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.id, forKey: .id)
        try container.encode(self.handle, forKey: .handle)
        try container.encode(self.hasVideo, forKey: .hasVideo)
        try container.encode(self.activeCall, forKey: .activeCall)
        try container.encode(self.outbound, forKey: .outbound)
        try container.encode(self.missed, forKey: .missed)
        try container.encode(self.rejected, forKey: .rejected)
        try container.encodeIfPresent(self.contact, forKey: .contact)
        try container.encodeIfPresent(self.createdAt, forKey: .createdAt)
        try container.encodeIfPresent(self.updatedAt, forKey: .updatedAt)
        try container.encodeIfPresent(self.deletedAt, forKey: .deletedAt)
    }
    
    public static func == (lhs: FCSDKCall, rhs: FCSDKCall) -> Bool {
        return lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        id.hash(into: &hasher)
    }
}

