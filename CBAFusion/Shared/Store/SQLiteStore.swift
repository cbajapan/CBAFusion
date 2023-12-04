//
//  SQLiteStore.swift
//  CBAFusion
//
//  Created by Cole M on 11/16/21.
//

import FluentSQLiteDriver
import Foundation
import FluentKit
import SwiftUI
import FCSDKiOS
import Logging

class SQLiteStore: FCSDKStore {
    
    
    let databases: Databases
    let database: Database
    var eventLoop: EventLoop { database.eventLoop }
    
    init(databases: Databases, database: Database) {
        self.databases = databases
        self.database = database
    }
    
    static func exists() -> Bool {
        FileManager.default.fileExists(atPath: makeSQLiteURL())
    }
    
    static func destroy() {
        try? FileManager.default.removeItem(atPath: makeSQLiteURL())
    }
    
    func destroy() {
        Self.destroy()
    }
    
    public static func create(
        on eventLoop: EventLoop
    ) async throws -> SQLiteStore {
        try await withCheckedThrowingContinuation { continuation in
            do {
                let store = try self.create(withConfiguration: .file(makeSQLiteURL()), on: eventLoop).wait()
                continuation.resume(returning: store)
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    static func create(
        withConfiguration configuration: SQLiteConfiguration,
        on eventLoop: EventLoop
    ) -> EventLoopFuture<SQLiteStore> {
        returningAsyncDispatch {
            let databases = Databases(
                threadPool: NIOThreadPool(numberOfThreads: 1),
                on: eventLoop
            )
            databases.threadPool.start()
            
            databases.use(.sqlite(configuration), as: .sqlite)
            let logger = Logger(label: "\(Constants.BUNDLE_IDENTIFIER) - SQLiteStore - ")
            
            let migrations = Migrations()
            migrations.add(CreateContactMigration())
            migrations.add(CreateCallsMigration())
            
            let migrator = Migrator(databases: databases, migrations: migrations, logger: logger, on: eventLoop)
            return migrator.setupIfNeeded().flatMap {
                migrator.prepareBatch()
            }.recover { _ in }.map {
                return SQLiteStore(
                    databases: databases,
                    database: databases.database(logger: logger, on: eventLoop)!
                )
            }.flatMapErrorThrowing { error in
                databases.shutdown()
                throw error
            }
        }
    }
    
    func fetchContacts() async throws -> [ContactModel]? {
        try await _ContactModel.query(on: database)
            .with(\.$calls)
            .all()
            .flatMapEachThrowing {
                let c = $0.calls.map { call in
                    FCSDKCall(
                        id: call.id!,
                        handle: call.handle,
                        hasVideo: call.hasVideo,
                        activeCall: call.activeCall,
                        outbound: call.outbound,
                        missed: call.missed,
                        rejected: call.rejected,
                        contact: call.$contact.id,
                        createdAt: call.createdAt,
                        updatedAt: call.updatedAt,
                        deletedAt: call.deletedAt)
                }
                return ContactModel(id: $0.id!, username: $0.username,
                                    number: $0.number, calls: c, blocked: $0.blocked)
            }.get()
    }
    
    func createContact(_ contact: ContactModel) async throws {
        let contacts = try await fetchContacts()
        let filteredContact = contacts?.filter({ $0.number == contact.number })
        if contact.number != filteredContact?.last?.number {
            try await _ContactModel(contact: contact, new: true).create(on: database).get()
        }
    }
    
    func updateContact(_ contact: ContactModel) async throws {
        try await _ContactModel(contact: contact, new: false).update(on: database).get()
    }
    
    func removeContact(_ contact: ContactModel) async throws {
        try await _ContactModel(contact: contact, new: false).delete(force: true, on: database).get()
    }
    
    func fetchCalls() async throws -> [FCSDKCall]? {
        try await _CallsModel.query(on: database)
            .with(\.$contact).withDeleted()
            .all()
            .flatMapEachThrowing {
                try $0.makeCall()
            }.get()
    }
    
    func fetchContactCalls(handle: String) async throws -> [FCSDKCall]? {
        return try await _CallsModel.query(on: database)
            .filter(\.$handle == handle)
            .with(\.$contact).withDeleted()
            .all()
            .flatMapEachThrowing {
                try $0.makeCall()
            }.get()
    }
    
    
    func fetchActiveCalls() async throws -> [FCSDKCall]? {
        try await _CallsModel.query(on: database)
            .filter(\.$activeCall == true)
            .with(\.$contact).withDeleted()
            .all()
            .flatMapEachThrowing {
                try $0.makeCall()
            }.get()
    }
    
    
    func createCall(_ contactID: UUID?, call: _CallsModel) async throws -> [ContactModel]? {
        var contact: _ContactModel?
        if #available(iOS 15.0, *) {
            let contacts = try await _ContactModel.query(on: database).all()
            contact = contacts.first(where: { $0.id == contactID } )
        } else {
            guard let contactID = contactID else { throw SQLiteError.notFound }
            contact = try getNIOCall(contactID)
        }
        try await contact?.$calls.create(call, on: database).get()
        
        return try await self.fetchContacts()
    }
    
    
    func getNIOCall(_ contactID: UUID) throws -> _ContactModel {
        let contacts = _ContactModel.query(on: database).all()
        let promise = eventLoop.makePromise(of: _ContactModel.self)
        contacts.whenSuccess { contacts in
            if let contact = contacts.first(where: { $0.id == contactID } ) {
                promise.succeed(contact)
            } else {
                promise.fail(SQLiteError.notFound)
            }
        }
        return try promise.futureResult.wait()
    }
    
    func updateCall(_ contactID: UUID, fcsdkCall: FCSDKCall) async throws  -> [ContactModel]? {
        try await _CallsModel(call: fcsdkCall, contactID: contactID, new: false).update(on: database).get()
        return try await self.fetchContacts()
    }
    
    func removeCall(_ contactID: UUID, fcsdkCall: FCSDKCall) async throws {
        try await _CallsModel(call: fcsdkCall, contactID: contactID, new: false).delete(force: true, on: database).get()
    }
    
    func removeCalls() async throws -> (Bool, [FCSDKCall]?) {
        do {
            if #available(iOS 15, *) {
                _ = try await _CallsModel.query(on: self.database).delete(force: true)
            } else {
//                _ = _CallsModel.query(on: self.database).delete(force: true)
            }
            let calls = try await self.fetchCalls()
            return (true, calls)
        } catch {
            return (false, nil)
        }
    }
    
    deinit {
        DispatchQueue.main.async { [databases] in
            databases.shutdown()
        }
    }
}

enum SQLiteError: Error {
    case notFound
}


struct CreateContactMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(_ContactModel.schema)
            .id()
            .field("username", .string, .required)
            .field("number", .string, .required)
            .field("blocked", .bool, .required)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .field("deleted_at", .datetime)
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(_ContactModel.schema).delete()
    }
}

struct CreateCallsMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(_CallsModel.schema)
            .id()
            .field("handle", .string, .required)
            .field("hasVideo", .bool, .required)
            .field("activeCall", .bool, .required)
            .field("outbound", .bool, .required)
            .field("missed", .bool, .required)
            .field("rejected", .bool, .required)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .field("deleted_at", .datetime)
            .field("contact_id", .uuid, .required, .references(_ContactModel.schema, "id", onDelete: .cascade))
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(_CallsModel.schema).delete()
    }
}


fileprivate func makeSQLiteURL() -> String {
    guard var url = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first else {
        fatalError()
    }
    
    url = url.appendingPathComponent("db")
    Logger(label: "\(Constants.BUNDLE_IDENTIFIER) - SQLiteStore - ").info("DATABASE \(url)")
    if FileManager.default.fileExists(atPath: url.path) {
        var excludedFromBackup = URLResourceValues()
        excludedFromBackup.isExcludedFromBackup = true
        try! url.setResourceValues(excludedFromBackup)
    }
    
    return url.path
}


@discardableResult func returningAsyncDispatch<T>(_ block: @escaping () -> T) -> T {
    let queue = DispatchQueue.global(qos: .background)
    let group = DispatchGroup()
    var result: T?
    group.enter()
    queue.async(group: group) { result = block(); group.leave(); }
    group.wait()

    return result!
}
