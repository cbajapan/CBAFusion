//
//  FCSDKCall.swift
//  
//
//  Created by Cole M on 12/22/21.
//

import FCSDKiOS
import UIKit

/// This Model is a call object that can be used in making FCSDK Calls with or with out CallKit
public final class FCSDKCall: Codable, Hashable {

    public var id: UUID
    /// The destination to call
    public var handle: String
    /// Lets CallKit know if we want to use video
    public var hasVideo: Bool
    /// The preview view for video calls
    public var previewView: UIView? = nil
    /// The remote view for video calls
    public var remoteView: UIView? = nil
    /// Our ACBUC Object
    public var acbuc: ACBUC? = nil
    /// The ACBClientCall associated with this CallObject
    public weak var call: ACBClientCall? = nil
    /// A boolean value that determines if the call is an active call
    public var activeCall: Bool? = false
    /// A boolean value indicating if the call is an outbound call
    public var outbound: Bool? = false
    /// A boolean value to indicate if we missed the call
    public var missed: Bool? = false
    /// A boolean value to indicate if we rejected the call
    public var rejected: Bool? = false
    /// The UUID for the parent Contact Model
    public var contact: UUID? = nil
    /// Date of creation
    public var createdAt: Date? = nil
    /// Date updated
    public var updatedAt: Date? = nil
    /// Date  deleted
    public var deletedAt: Date? = nil

    public init(
        id: UUID,
        handle: String,
        hasVideo: Bool,
        previewView: UIView? = nil,
        remoteView: UIView? = nil,
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
        self.previewView = previewView
        self.remoteView = remoteView
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
    
    public enum CodingKeys: String, CodingKey {
        case id, handle, hasVideo, activeCall, outbound, missed, rejected, contact, createdAt, updatedAt, deletedAt
    }
    
    public init(from decoder: Decoder) throws {
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
    
    public func encode(to encoder: Encoder) throws {
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
