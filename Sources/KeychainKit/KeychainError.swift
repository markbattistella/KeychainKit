//
// Project: KeychainKit
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import Foundation

/// Errors thrown during Keychain operations.
public enum KeychainError: Error, Sendable {

  /// Failed to encode a `String` into data for storage.
  case stringEncodingFailed

  /// Failed to encode an object to JSON before storing it.
  case jsonEncodingFailed

  /// Failed to decode JSON data retrieved from the Keychain.
  case jsonDecodingFailed

  /// No matching item was found in the Keychain.
  case itemNotFound

  /// An item already exists at the requested Keychain location.
  case duplicateItem

  /// Access to the Keychain was denied or authorisation failed.
  case authorizationFailed

  /// The provided type is not supported for Keychain storage.
  ///
  /// - Parameter String: A description of the unsupported type.
  case unsupportedType(String)

  /// An unhandled `OSStatus` value was returned by the Keychain API.
  case unhandledError(OSStatus)

  /// Maps a raw `OSStatus` value from the Keychain API to a specific error case.
  ///
  /// - Parameter status: The Keychain status code returned by the system.
  init(status: OSStatus) {
    switch status {
    case errSecItemNotFound:
      self = .itemNotFound
    case errSecDuplicateItem:
      self = .duplicateItem
    case errSecAuthFailed:
      self = .authorizationFailed
    default:
      self = .unhandledError(status)
    }
  }
}
