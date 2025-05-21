import Foundation
import FCSDKiOS
import Logging

// MARK: - FCSDKStore Protocol

protocol FCSDKStore: AnyObject, Sendable {
    // MARK: - Contact Management
    func fetchContacts() async throws -> [ContactModel]?
    func createContact(_ contact: ContactModel) async throws
    func updateContact(_ contact: ContactModel) async throws
    func removeContact(_ contact: ContactModel) async throws
    
    // MARK: - Call Management
    func fetchActiveCalls() async throws -> [FCSDKCall]?
    func fetchCalls() async throws -> [FCSDKCall]?
    func fetchContactCalls(handle: String) async throws -> [FCSDKCall]?
    func createCall(_ contactID: UUID?, call: _CallsModel) async throws -> [ContactModel]?
    func updateCall(_ contactID: UUID, fcsdkCall: FCSDKCall) async throws -> [ContactModel]?
    func removeCall(_ contactID: UUID, fcsdkCall: FCSDKCall) async throws
    func removeCalls() async throws -> (Bool, [FCSDKCall]?)
}

// MARK: - Default Implementation of FCSDKStore

extension FCSDKStore {
    func fetchContacts() async throws -> [ContactModel]? { return nil }
    func createContact(_ contact: ContactModel) async throws {}
    func updateContact(_ contact: ContactModel) async throws {}
    func removeContact(_ contact: ContactModel) async throws {}
    
    func fetchActiveCalls() async throws -> [FCSDKCall]? { return nil }
    func fetchCalls() async throws -> [FCSDKCall]? { return nil }
    func createCall(_ contactID: UUID?, call: _CallsModel) async throws -> [ContactModel]? { return nil }
    func updateCall(_ contactID: UUID, fcsdkCall: FCSDKCall) async throws -> [ContactModel]? { return nil }
    func removeCall(_ contactID: UUID, fcsdkCall: FCSDKCall) async throws {}
    func removeCalls() async throws -> (Bool, [FCSDKCall]?) { return (false, nil) }
}

