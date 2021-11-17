//
//  SQLiteStore.swift
//  SwiftFCSDKSample
//
//  Created by Cole M on 11/16/21.
//

import FluentSQLiteDriver
import Foundation
import FluentKit
import SwiftUI


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
        try? FileManager.default.removeItem(atPath:makeSQLiteURL())
    }
    
    func destroy() {
        Self.destroy()
    }
    
    public static func create(
        on eventLoop: EventLoop
    ) async throws -> SQLiteStore {
        try await self.create(withConfiguration: .file(makeSQLiteURL()), on: eventLoop).get()
    }
    
    static func create(
        withConfiguration configuration: SQLiteConfiguration,
        on eventLoop: EventLoop
    ) -> EventLoopFuture<SQLiteStore> {
        
        let databases = Databases(
            threadPool: NIOThreadPool(numberOfThreads: 1),
            on: eventLoop
        )
        
        databases.use(.sqlite(configuration), as: .sqlite)
        let logger = Logger(label: "sqlite")
        
        let migrations = Migrations()
        migrations.add(CreateContactMigration())
        
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
    
    func fetchContacts() async throws -> [ContactModel] {
        try await _ContactModel.query(on: database).all().flatMapEachThrowing {
            try $0.makeContact()
        }.get()
    }
    
    func createContact(_ contact: ContactModel) async throws {
        try await _ContactModel(contact: contact, new: true).create(on: database).get()
    }
    
    func updateContact(_ contact: ContactModel) async throws {
        try await _ContactModel(contact: contact, new: false).update(on: database).get()
    }
    
    func removeContact(_ contact: ContactModel) async throws {
        try await _ContactModel(contact: contact, new: false).delete(on: database).get()
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
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(_ContactModel.schema).delete()
    }
}

fileprivate func makeSQLiteURL() -> String {
    guard var url = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first else {
        fatalError()
    }
    
    url = url.appendingPathComponent("db")
    
    if FileManager.default.fileExists(atPath: url.path) {
        var excludedFromBackup = URLResourceValues()
        excludedFromBackup.isExcludedFromBackup = true
        try! url.setResourceValues(excludedFromBackup)
    }
    
    return url.path
}
