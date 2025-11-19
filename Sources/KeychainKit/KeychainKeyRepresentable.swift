//
// Project: KeychainKit
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import Foundation

public protocol KeychainKeyRepresentable: RawRepresentable where RawValue == String {
    static var accessGroup: String? { get }
}

extension KeychainKeyRepresentable {

    public static var accessGroup: String? { nil }

    public var fullKey: String {
        "\(Self.prefix)\(rawValue)"
    }

    internal static var prefix: String {
        if let identifier = Bundle.main.bundleIdentifier {
            return "\(identifier).keychain."
        }
        return "com.markbattistella.packages.keychainKit.keychain."
    }
}
