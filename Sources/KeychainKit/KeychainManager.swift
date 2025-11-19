//
// Project: KeychainKit
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import Foundation
import Security

public final class KeychainManager: Sendable {

    public static let shared = KeychainManager()
    private init() {}

    // MARK: - Typed Setters

    @discardableResult
    public func set(
        _ value: String,
        for key: any KeychainKeyRepresentable,
        sync: KeychainSync = .localOnly
    ) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        return set(data, for: key, sync: sync)
    }

    @discardableResult
    public func set(
        _ value: Bool,
        for key: any KeychainKeyRepresentable,
        sync: KeychainSync = .localOnly
    ) -> Bool {
        let data = Data([value ? 1 : 0])
        return set(data, for: key, sync: sync)
    }

    @discardableResult
    public func set(
        _ value: Int,
        for key: any KeychainKeyRepresentable,
        sync: KeychainSync = .localOnly
    ) -> Bool {
        set(String(value), for: key, sync: sync)
    }

    @discardableResult
    public func set(
        _ value: Double,
        for key: any KeychainKeyRepresentable,
        sync: KeychainSync = .localOnly
    ) -> Bool {
        set(String(value), for: key, sync: sync)
    }

    @discardableResult
    public func set(
        _ value: Float,
        for key: any KeychainKeyRepresentable,
        sync: KeychainSync = .localOnly
    ) -> Bool {
        set(String(value), for: key, sync: sync)
    }

    @discardableResult
    public func set(
        _ value: Date,
        for key: any KeychainKeyRepresentable,
        sync: KeychainSync = .localOnly
    ) -> Bool {
        guard let data = try? JSONEncoder().encode(value) else { return false }
        return set(data, for: key, sync: sync)
    }

    @discardableResult
    public func set<T: Encodable>(
        _ value: T,
        for key: any KeychainKeyRepresentable,
        sync: KeychainSync = .localOnly
    ) -> Bool {
        guard let data = try? JSONEncoder().encode(value) else { return false }
        return set(data, for: key, sync: sync)
    }

    @discardableResult
    public func set(
        _ value: [String: Any],
        for key: any KeychainKeyRepresentable,
        sync: KeychainSync = .localOnly
    ) -> Bool {
        guard let data = try? JSONSerialization.data(withJSONObject: value) else { return false }
        return set(data, for: key, sync: sync)
    }

    // MARK: - Codable Value Getter

    public func value<T: Decodable>(
        for key: any KeychainKeyRepresentable,
        sync: KeychainSync = .localOnly
    ) -> T? {
        decode(for: key, sync: sync)
    }

    // MARK: - Core Data Setter

    @discardableResult
    public func set(
        _ data: Data,
        for key: any KeychainKeyRepresentable,
        sync: KeychainSync
    ) -> Bool {
        // Delete existing item in the same scope before adding new one
        _ = delete(key, sync: sync)

        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.fullKey,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]

        if let group = type(of: key).accessGroup {
            query[kSecAttrAccessGroup as String] = group
        }
        if let syncAttr = sync.attributeValue {
            query[kSecAttrSynchronizable as String] = syncAttr
        }

        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }

    // MARK: - Typed Getters

    public func string(
        for key: any KeychainKeyRepresentable,
        sync: KeychainSync = .localOnly
    ) -> String? {
        guard let data = data(for: key, sync: sync) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    public func bool(
        for key: any KeychainKeyRepresentable,
        sync: KeychainSync = .localOnly
    ) -> Bool? {
        guard let byte = data(for: key, sync: sync)?.first else { return nil }
        return byte == 1
    }

    public func integer(
        for key: any KeychainKeyRepresentable,
        sync: KeychainSync = .localOnly
    ) -> Int? {
        guard let string = string(for: key, sync: sync) else { return nil }
        return Int(string)
    }

    public func float(
        for key: any KeychainKeyRepresentable,
        sync: KeychainSync = .localOnly
    ) -> Float? {
        guard let string = string(for: key, sync: sync) else { return nil }
        return Float(string)
    }

    public func double(
        for key: any KeychainKeyRepresentable,
        sync: KeychainSync = .localOnly
    ) -> Double? {
        guard let string = string(for: key, sync: sync) else { return nil }
        return Double(string)
    }

    public func date(
        for key: any KeychainKeyRepresentable,
        sync: KeychainSync = .localOnly
    ) -> Date? {
        guard let data = data(for: key, sync: sync) else { return nil }
        return try? JSONDecoder().decode(Date.self, from: data)
    }

    public func array<T: Decodable>(
        for key: any KeychainKeyRepresentable,
        sync: KeychainSync = .localOnly
    ) -> [T]? {
        decode(for: key, sync: sync)
    }

    public func dictionary(
        for key: any KeychainKeyRepresentable,
        sync: KeychainSync = .localOnly
    ) -> [String: Any]? {
        guard let data = data(for: key, sync: sync) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
    }

    public func decode<T: Decodable>(
        for key: any KeychainKeyRepresentable,
        sync: KeychainSync = .localOnly
    ) -> T? {
        guard let data = data(for: key, sync: sync) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    // MARK: - Raw Data Getter

    public func data(
        for key: any KeychainKeyRepresentable,
        sync: KeychainSync = .localOnly
    ) -> Data? {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.fullKey,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        if let group = type(of: key).accessGroup {
            query[kSecAttrAccessGroup as String] = group
        }
        if let syncAttr = sync.attributeValue {
            query[kSecAttrSynchronizable as String] = syncAttr
        }

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        return status == errSecSuccess ? (result as? Data) : nil
    }

    // MARK: - Delete

    @discardableResult
    public func delete(
        _ key: any KeychainKeyRepresentable,
        sync: KeychainSync = .localOnly
    ) -> Bool {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.fullKey
        ]

        if let group = type(of: key).accessGroup {
            query[kSecAttrAccessGroup as String] = group
        }
        if let syncAttr = sync.attributeValue {
            query[kSecAttrSynchronizable as String] = syncAttr
        }

        let result = SecItemDelete(query as CFDictionary)
        return result == errSecSuccess || result == errSecItemNotFound
    }
}
