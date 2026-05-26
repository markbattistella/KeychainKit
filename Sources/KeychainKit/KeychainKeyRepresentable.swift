//
// Project: KeychainKit
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import Foundation

/// A protocol for types that represent Keychain keys using a `String` raw value.
///
/// Conforming types can optionally provide a custom prefix used when constructing fully-qualified
/// Keychain keys.
public protocol KeychainKeyRepresentable: RawRepresentable, Sendable where RawValue == String {

  /// An optional custom prefix applied to all keys of the conforming type.
  ///
  /// If `nil`, a default prefix derived from the app’s bundle identifier is used.
  static var keyPrefix: String? { get }
}

extension KeychainKeyRepresentable {

  /// The default implementation returns `nil`, causing the type to fall back to the standard
  /// bundle-derived prefix.
  public static var keyPrefix: String? { nil }

  /// The fully-qualified Keychain key for this instance.
  ///
  /// This value is composed by joining the type’s computed prefix with the instance’s raw value.
  internal var value: String {
    "\(Self.prefix)\(rawValue)"
  }

  /// The computed prefix applied to all keys for the conforming type.
  ///
  /// - Uses `keyPrefix` when provided.
  /// - Otherwise, uses a default prefix derived from `KeychainDefaults.bundlePrefix`.
  ///
  /// The final format is: `<prefix>.keychain.`
  internal static var prefix: String {
    let base = keyPrefix ?? KeychainDefaults.bundlePrefix
    return "\(base).keychain."
  }
}
