//
// Project: KeychainKit
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import Foundation

/// A namespace providing default values and helpers for Keychain usage.
internal enum KeychainDefaults {

    /// A prefix used for Keychain keys, derived from the app’s bundle identifier.
    ///
    /// - Returns: The app’s bundle identifier with leading and trailing periods trimmed. If the
    /// bundle identifier is unavailable, a predefined fallback prefix
    /// (`"com.markbattistella.packages.keychainKit"`) is used instead.
    static var bundlePrefix: String {
        if let bundle = Bundle.main.bundleIdentifier {
            return bundle.trimmingCharacters(in: .init(charactersIn: "."))
        } else {
            return "com.markbattistella.packages.keychainKit"
        }
    }
}
