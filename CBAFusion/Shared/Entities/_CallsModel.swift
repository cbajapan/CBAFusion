//
//  _CallsModel.swift
//  CBAFusion
//
//  Created by Cole M on 1/10/22.
//

import FluentSQLiteDriver
import Foundation
import FluentKit
import FCSDKiOS

final class _CallsModel: FluentKit.Model {
    static let schema = "call"

    @ID(key: .id) var id: UUID?
    @Field(key: "handle") var handle: String
    @Field(key: "hasVideo") var hasVideo: Bool
    @Field(key: "activeCall") var activeCall: Bool
    @Field(key: "outbound") var outbound: Bool
    @Field(key: "missed") var missed: Bool
    @Field(key: "rejected") var rejected: Bool
    @Parent(key: "contact_id") var contact: _ContactModel
    @Timestamp(key: "created_at", on: .create) var createdAt: Date?
    @Timestamp(key: "updated_at", on: .update) var updatedAt: Date?
    @Timestamp(key: "deleted_at", on: .delete) var deletedAt: Date?
    
    init() {}
    
    init(call: FCSDKCall, contactID: _ContactModel.IDValue, new: Bool) {
        self.id = call.id
        $id.exists = !new
        self.handle = call.handle
        self.hasVideo = call.hasVideo
        self.activeCall = call.activeCall!
        self.outbound = call.outbound!
        self.missed = call.missed!
        self.rejected = call.rejected!
        self.$contact.id = contactID
        self.createdAt = call.createdAt
        self.updatedAt = call.updatedAt
        self.deletedAt = call.deletedAt
    }
    
    func makeCall() throws -> FCSDKCall {
        return FCSDKCall(id: id!, handle: handle, hasVideo: hasVideo, communicationView: nil, acbuc: nil, call: nil, activeCall: activeCall, outbound: outbound, missed: missed, rejected: rejected, contact: contact.id, createdAt: createdAt, updatedAt: updatedAt, deletedAt: deletedAt)
    }
}
