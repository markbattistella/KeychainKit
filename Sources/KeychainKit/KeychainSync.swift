//
// Project: KeychainKit
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import Foundation

/// Indicates whether a Keychain item should sync with iCloud.
public enum KeychainSync: Sendable {

  /// Store the item only on the local device, without iCloud synchronisation.
  case localOnly

  /// Allow the item to be synchronised across devices via iCloud.
  case iCloud
}

extension KeychainSync {

  /// The Core Foundation attribute value representing the sync behaviour.
  ///
  /// - Returns: `kCFBooleanFalse` for `.localOnly` or `kCFBooleanTrue` for `.iCloud`.
  internal var attributeValue: Any {
    switch self {
    case .localOnly:
      return kCFBooleanFalse as Any
    case .iCloud:
      return kCFBooleanTrue as Any
    }
  }

  /// The Core Foundation query value that matches local and synchronisable Keychain items.
  internal static var anyAttributeValue: Any {
    kSecAttrSynchronizableAny
  }
}
