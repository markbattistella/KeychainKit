//
// Project: KeychainKit
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import Foundation
import Security

/// A utility class for interacting with the system Keychain.
///
/// This type provides a configurable interface for storing, retrieving, and managing secure
/// values. Instances may specify a custom service name and access group, or rely on sensible
/// defaults.
public final class Keychain: Sendable {

    /// The Keychain access group used to share items across apps or extensions.
    ///
    /// If `nil`, no access-group attribute is applied.
    public let accessGroup: String?

    /// The service name associated with all stored items.
    ///
    /// Defaults to the app’s bundle-derived prefix when not explicitly provided.
    public let serviceName: String

    /// A shared, lazily created `Keychain` instance using default configuration.
    public static let standard = Keychain()

    /// Creates a new Keychain instance.
    ///
    /// - Parameters:
    ///   - serviceName: A custom service name to associate with stored items. If omitted, a
    ///   bundle-derived prefix is used.
    ///   - accessGroup: A Keychain access group for shared storage.
    ///
    /// `serviceName` and `accessGroup` are applied to all queries performed
    /// by this instance.
    public init(
        serviceName: String? = nil,
        accessGroup: String? = nil
    ) {
        self.serviceName = serviceName ?? KeychainDefaults.bundlePrefix
        self.accessGroup = accessGroup
    }
}

extension Keychain {

    /// Constructs a base Keychain query dictionary for the specified key.
    ///
    /// - Parameters:
    ///   - key: A type conforming to `KeychainKeyRepresentable` whose value is used as the
    ///   account identifier.
    ///   - sync: Optional synchronisation behaviour for the item (local or iCloud).
    ///   - returnData: Indicates whether the query should request the item's data.
    ///   - returnRef: Indicates whether the query should request a persistent reference.
    ///   - returnAttributes: Indicates whether the query should request item attributes.
    ///
    /// - Returns: A dictionary configured for use with Security framework functions.
    private func baseQuery(
        for key: any KeychainKeyRepresentable,
        sync: KeychainSync?,
        returnData: Bool = false,
        returnRef: Bool = false,
        returnAttributes: Bool = false
    ) -> [String: Any] {

        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.value,
            kSecAttrService as String: serviceName
        ]

        if let group = accessGroup {
            query[kSecAttrAccessGroup as String] = group
        }

        if let sync = sync {
            query[kSecAttrSynchronizable as String] = sync.attributeValue
        }

        if returnData {
            query[kSecReturnData as String] = true
            query[kSecMatchLimit as String] = kSecMatchLimitOne
        }

        if returnRef {
            query[kSecReturnPersistentRef as String] = true
            query[kSecMatchLimit as String] = kSecMatchLimitOne
        }

        if returnAttributes {
            query[kSecReturnAttributes as String] = true
        }

        return query
    }

    /// Loads raw data associated with a given Keychain key.
    ///
    /// - Parameters:
    ///   - key: The Keychain key used as the account identifier.
    ///   - sync: Optional synchronisation behaviour to apply to the lookup.
    ///
    /// - Returns: The retrieved `Data` if found, otherwise `nil`.
    private func load(
        for key: any KeychainKeyRepresentable,
        sync: KeychainSync? = nil
    ) -> Data? {
        var result: CFTypeRef?
        let status = SecItemCopyMatching(
            baseQuery(for: key, sync: sync, returnData: true) as CFDictionary,
            &result
        )
        return status == errSecSuccess ? (result as? Data) : nil
    }
}

extension Keychain {

    /// Stores an encodable value in the Keychain.
    ///
    /// This method attempts to encode the value and write it to the Keychain, returning a Boolean
    /// indicating success or failure. Errors are suppressed.
    ///
    /// - Parameters:
    ///   - value: The value to store. `Data`, `String`, and any `Encodable` type are supported.
    ///   - key: The Keychain key identifying the item.
    ///   - sync: Synchronisation behaviour for the stored item.
    ///   - accessible: Accessibility level controlling when the item is readable.
    ///
    /// - Returns: `true` if the value was stored successfully, otherwise `false`.
    @discardableResult
    public func set<Value: Encodable>(
        _ value: Value,
        for key: any KeychainKeyRepresentable,
        sync: KeychainSync = .localOnly,
        accessible: KeychainAccessible = .whenUnlocked
    ) -> Bool {
        (try? setThrowing(value, for: key, sync: sync, accessible: accessible)) != nil
    }

    /// Stores an encodable value in the Keychain, throwing errors on failure.
    ///
    /// - Parameters:
    ///   - value: The value to store. `Data`, `String`, and any `Encodable` type are supported.
    ///   - key: The Keychain key identifying the item.
    ///   - sync: Synchronisation behaviour for the stored item.
    ///   - accessible: Accessibility level controlling when the item is readable.
    ///
    /// - Throws:
    ///   - `KeychainError.stringEncodingFailed` if a string cannot be encoded as UTF-8.
    ///   - `KeychainError.jsonEncodingFailed` if JSON encoding fails.
    ///   - Other `KeychainError` values for system-level Keychain failures.
    public func setThrowing<Value: Encodable>(
        _ value: Value,
        for key: any KeychainKeyRepresentable,
        sync: KeychainSync = .localOnly,
        accessible: KeychainAccessible = .whenUnlocked
    ) throws {

        let data: Data

        switch value {
            case let v as Data:
                data = v

            case let v as String:
                guard let d = v.data(using: .utf8) else {
                    throw KeychainError.stringEncodingFailed
                }
                data = d

            default:
                do {
                    data = try JSONEncoder().encode(value)
                } catch {
                    throw KeychainError.jsonEncodingFailed
                }
        }

        try storeData(data, for: key, sync: sync, accessible: accessible)
    }

    /// Inserts or updates raw data in the Keychain.
    ///
    /// - Parameters:
    ///   - data: The encoded data to store.
    ///   - key: The Keychain key identifying the item.
    ///   - sync: Synchronisation behaviour for the stored item.
    ///   - accessible: Accessibility level controlling when the item is readable.
    ///
    /// - Throws: A `KeychainError` if the update or insert operation fails.
    private func storeData(
        _ data: Data,
        for key: any KeychainKeyRepresentable,
        sync: KeychainSync,
        accessible: KeychainAccessible
    ) throws {

        var query = baseQuery(for: key, sync: sync)

        let updateAttrs = [kSecValueData as String: data]

        let updateStatus = SecItemUpdate(query as CFDictionary, updateAttrs as CFDictionary)

        if updateStatus == errSecSuccess { return }

        if updateStatus == errSecItemNotFound {
            query[kSecValueData as String] = data
            query[kSecAttrAccessible as String] = accessible.secAttr

            let addStatus = SecItemAdd(query as CFDictionary, nil)
            guard addStatus == errSecSuccess else { throw KeychainError(status: addStatus) }
            return
        }

        throw KeychainError(status: updateStatus)
    }
}

extension Keychain {

    /// Retrieves a Boolean value stored under the specified key.
    ///
    /// - Parameters:
    ///   - key: The Keychain key identifying the item.
    ///   - sync: Optional synchronisation behaviour.
    ///
    /// - Returns: A `Bool` if the value exists and can be decoded, otherwise `nil`.
    public func bool(
        for key: any KeychainKeyRepresentable,
        sync: KeychainSync? = nil
    ) -> Bool? {
        value(for: key, sync: sync)
    }

    /// Retrieves an integer value stored under the specified key.
    ///
    /// - Parameters:
    ///   - key: The Keychain key identifying the item.
    ///   - sync: Optional synchronisation behaviour.
    ///
    /// - Returns: An `Int` if the value exists and can be decoded, otherwise `nil`.
    public func integer(
        for key: any KeychainKeyRepresentable,
        sync: KeychainSync? = nil
    ) -> Int? {
        value(for: key, sync: sync)
    }

    /// Retrieves a floating-point value stored under the specified key.
    ///
    /// - Parameters:
    ///   - key: The Keychain key identifying the item.
    ///   - sync: Optional synchronisation behaviour.
    ///
    /// - Returns: A `Float` if the value exists and can be decoded, otherwise `nil`.
    public func float(
        for key: any KeychainKeyRepresentable,
        sync: KeychainSync? = nil
    ) -> Float? {
        value(for: key, sync: sync)
    }

    /// Retrieves a double-precision value stored under the specified key.
    ///
    /// - Parameters:
    ///   - key: The Keychain key identifying the item.
    ///   - sync: Optional synchronisation behaviour.
    ///
    /// - Returns: A `Double` if the value exists and can be decoded, otherwise `nil`.
    public func double(
        for key: any KeychainKeyRepresentable,
        sync: KeychainSync? = nil
    ) -> Double? {
        value(for: key, sync: sync)
    }

    /// Retrieves a UTF-8 string stored under the specified key.
    ///
    /// - Parameters:
    ///   - key: The Keychain key identifying the item.
    ///   - sync: Optional synchronisation behaviour.
    ///
    /// - Returns: A `String` decoded from UTF-8 data, otherwise `nil`.
    public func string(
        for key: any KeychainKeyRepresentable,
        sync: KeychainSync? = nil
    ) -> String? {
        load(for: key, sync: sync).flatMap { String(data: $0, encoding: .utf8) }
    }

    /// Retrieves raw data stored under the specified key.
    ///
    /// - Parameters:
    ///   - key: The Keychain key identifying the item.
    ///   - sync: Optional synchronisation behaviour.
    ///
    /// - Returns: The stored `Data` if present, otherwise `nil`.
    public func data(
        for key: any KeychainKeyRepresentable,
        sync: KeychainSync? = nil
    ) -> Data? {
        load(for: key, sync: sync)
    }

    /// Retrieves a `Date` value stored under the specified key.
    ///
    /// - Parameters:
    ///   - key: The Keychain key identifying the item.
    ///   - sync: Optional synchronisation behaviour.
    ///
    /// - Returns: A `Date` if present and decodable, otherwise `nil`.
    public func date(
        for key: any KeychainKeyRepresentable,
        sync: KeychainSync? = nil
    ) -> Date? {
        value(for: key, sync: sync)
    }

    /// Retrieves a URL value stored under the specified key.
    ///
    /// - Parameters:
    ///   - key: The Keychain key identifying the item.
    ///   - sync: Optional synchronisation behaviour.
    ///
    /// - Returns: A `URL` if present and valid, otherwise `nil`.
    public func url(
        for key: any KeychainKeyRepresentable,
        sync: KeychainSync? = nil
    ) -> URL? {
        string(for: key, sync: sync).flatMap(URL.init(string:))
    }

    /// Retrieves an array of decodable elements stored under the specified key.
    ///
    /// - Parameters:
    ///   - key: The Keychain key identifying the item.
    ///   - sync: Optional synchronisation behaviour.
    ///
    /// - Returns: The decoded array if present, otherwise `nil`.
    public func array<Value: Decodable>(
        for key: any KeychainKeyRepresentable,
        sync: KeychainSync? = nil
    ) -> [Value]? {
        value(for: key, sync: sync)
    }

    /// Retrieves a dictionary stored under the specified key.
    ///
    /// - Parameters:
    ///   - key: The Keychain key identifying the item.
    ///   - sync: Optional synchronisation behaviour.
    ///
    /// - Returns: A dictionary of decoded values keyed by `String`, otherwise `nil`.
    public func dictionary<Value: Decodable>(
        for key: any KeychainKeyRepresentable,
        sync: KeychainSync? = nil
    ) -> [String: Value]? {
        value(for: key, sync: sync)
    }

    /// Retrieves and decodes a value stored under the specified key.
    ///
    /// - Parameters:
    ///   - key: The Keychain key identifying the item.
    ///   - sync: Optional synchronisation behaviour.
    ///
    /// - Returns: A decoded value of type `Value`, or `nil` if decoding fails.
    public func value<Value: Decodable>(
        for key: any KeychainKeyRepresentable,
        sync: KeychainSync? = nil
    ) -> Value? {
        guard let data = load(for: key, sync: sync) else { return nil }

        switch Value.self {
            case is String.Type:
                return String(data: data, encoding: .utf8) as? Value

            case is Data.Type:
                return data as? Value

            default:
                do {
                    return try JSONDecoder().decode(Value.self, from: data)
                } catch {
                    return nil
                }
        }
    }
}

extension Keychain {

    /// Retrieves the persistent reference for the specified Keychain item.
    ///
    /// A persistent reference uniquely identifies a Keychain item and can be stored or used
    /// later to retrieve the item without knowing its attributes.
    ///
    /// - Parameters:
    ///   - key: The Keychain key identifying the item.
    ///   - sync: Optional synchronisation behaviour.
    ///
    /// - Returns: The item's persistent reference as `Data`, or `nil` if unavailable.
    public func persistentRef(
        for key: any KeychainKeyRepresentable,
        sync: KeychainSync? = nil
    ) -> Data? {

        var result: CFTypeRef?
        let status = SecItemCopyMatching(
            baseQuery(for: key, sync: sync, returnRef: true) as CFDictionary,
            &result
        )
        return status == errSecSuccess ? result as? Data : nil
    }

    /// Retrieves the accessibility setting for the specified Keychain item.
    ///
    /// - Parameters:
    ///   - key: The Keychain key identifying the item.
    ///   - sync: Optional synchronisation behaviour.
    ///
    /// - Returns: The corresponding `KeychainAccessible` case if found, otherwise `nil`.
    public func accessibility(
        for key: any KeychainKeyRepresentable,
        sync: KeychainSync? = nil
    ) -> KeychainAccessible? {

        var result: CFTypeRef?
        let query = baseQuery(
            for: key,
            sync: sync,
            returnAttributes: true
        )

        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let dict = result as? [String: Any],
              let attr = dict[kSecAttrAccessible as String] as? String
        else { return nil }

        switch attr as CFString {
            case kSecAttrAccessibleWhenUnlocked:
                return .whenUnlocked
            case kSecAttrAccessibleWhenUnlockedThisDeviceOnly:
                return .whenUnlockedThisDeviceOnly
            case kSecAttrAccessibleAfterFirstUnlock:
                return .afterFirstUnlock
            case kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly:
                return .afterFirstUnlockThisDeviceOnly
            case kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly:
                return .whenPasscodeSetThisDeviceOnly
            default:
                return nil
        }
    }

    /// Retrieves all Keychain keys stored under the current service name and access group.
    ///
    /// - Returns: An array of key identifiers as strings.
    public func allKeys() -> [String] {
        var result: CFTypeRef?

        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecMatchLimit as String: kSecMatchLimitAll,
            kSecReturnAttributes as String: true
        ]

        if let group = accessGroup {
            query[kSecAttrAccessGroup as String] = group
        }

        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let array = result as? [[String: Any]]
        else { return [] }

        return array.compactMap { $0[kSecAttrAccount as String] as? String }
    }

    /// Checks whether a Keychain item exists for the specified key.
    ///
    /// - Parameters:
    ///   - key: The Keychain key identifying the item.
    ///   - sync: Optional synchronisation behaviour.
    ///
    /// - Returns: `true` if the item exists, otherwise `false`.
    public func exists(
        for key: any KeychainKeyRepresentable,
        sync: KeychainSync? = nil
    ) -> Bool {
        load(for: key, sync: sync) != nil
    }
}

extension Keychain {

    /// Removes the Keychain item associated with the specified key.
    ///
    /// - Parameters:
    ///   - key: The Keychain key identifying the item to remove.
    ///   - sync: Optional synchronisation behaviour determining which store (local or iCloud)
    ///   the deletion applies to.
    ///
    /// - Returns: `true` if the item was removed or was already absent, otherwise `false`.
    @discardableResult
    public func remove(
        for key: any KeychainKeyRepresentable,
        sync: KeychainSync? = nil
    ) -> Bool {
        let status = SecItemDelete(
            baseQuery(for: key, sync: sync) as CFDictionary
        )
        return status == errSecSuccess || status == errSecItemNotFound
    }

    /// Removes the Keychain item associated with the specified key from both local and iCloud
    /// stores.
    ///
    /// - Parameter key: The Keychain key identifying the item to remove.
    public func removeLocalAndCloud(
        for key: any KeychainKeyRepresentable
    ) {
        remove(for: key, sync: .localOnly)
        remove(for: key, sync: .iCloud)
    }

    /// Removes all Keychain items stored under the current service name and access group.
    ///
    /// - Returns: `true` if all items were removed or none existed, otherwise `false`.
    @discardableResult
    public func removeAll() -> Bool {

        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName
        ]

        if let group = accessGroup {
            query[kSecAttrAccessGroup as String] = group
        }

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}

extension Keychain {

    /// Defines how a migration should be executed.
    ///
    /// - `dryRun`: Simulates migration without modifying Keychain data.
    /// - `perform`: Executes the migration, copying items and removing them from the source.
    public enum MigrationMode {
        case dryRun
        case perform
    }

    /// The result of a Keychain migration operation.
    ///
    /// Contains lists of successfully migrated keys, keys that failed to migrate, and whether
    /// any changes were made to the Keychain.
    public struct MigrationResult {

        /// Keys successfully migrated.
        public let migrated: [String]

        /// Keys that failed to migrate and their associated errors.
        public let failed: [String: KeychainError]

        /// Indicates whether migration modified any Keychain data.
        public let didModify: Bool
    }

    /// Migrates all Keychain items from an old service/access group configuration to a new one.
    ///
    /// This is useful when changing an app’s Keychain access group, bundle ID, or service name.
    /// Items are copied to the new location and removed from the old one unless running in
    /// `.dryRun` mode.
    ///
    /// - Parameters:
    ///   - oldAccessGroup: The previous Keychain access group, or `nil` if none was used.
    ///   - oldServiceName: The old service name under which items were stored.
    ///   - newAccessGroup: The new access group to migrate items into.
    ///   - newServiceName: Optionally override the new service name. Defaults to the old
    ///   `oldServiceName`.
    ///   - mode: Specifies whether to simulate (`.dryRun`) or perform (`.perform`) migration.
    ///
    /// - Returns: A `MigrationResult` detailing successes, failures, and mutation status.
    public static func migrate(
        from oldAccessGroup: String?,
        oldServiceName: String,
        to newAccessGroup: String?,
        newServiceName: String? = nil,
        mode: MigrationMode = .perform
    ) -> MigrationResult {

        let newService = newServiceName ?? oldServiceName

        let oldKeychain = Keychain(serviceName: oldServiceName, accessGroup: oldAccessGroup)
        let newKeychain = Keychain(serviceName: newService, accessGroup: newAccessGroup)

        var migrated: [String] = []
        var failed: [String: KeychainError] = [:]

        let keys = oldKeychain.allKeys()

        for keyString in keys {

            struct TempKey: KeychainKeyRepresentable {
                let rawValue: String
                init(rawValue v: String) { self.rawValue = v }
            }
            let tempKey = TempKey(rawValue: keyString)

            guard let data = oldKeychain.data(for: tempKey) else {
                failed[keyString] = .itemNotFound
                continue
            }

            if mode == .dryRun {
                migrated.append(keyString)
                continue
            }

            do {
                try newKeychain.setThrowing(data, for: tempKey)
            } catch let error as KeychainError {
                failed[keyString] = error
                continue
            } catch {
                failed[keyString] = .unhandledError(errSecInternalError)
                continue
            }

            oldKeychain.remove(for: tempKey)
            migrated.append(keyString)
        }

        return MigrationResult(
            migrated: migrated,
            failed: failed,
            didModify: mode == .perform
        )
    }
}
