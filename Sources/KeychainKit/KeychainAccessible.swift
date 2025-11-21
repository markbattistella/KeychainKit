//
// Project: KeychainKit
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import Foundation

/// Represents the accessibility level for a Keychain item.
///
/// These values determine when the item may be read from or written to, and whether it is
/// restricted to the current device.
public enum KeychainAccessible: Sendable {

    /// Item is accessible after the first device unlock following a reboot.
    case afterFirstUnlock

    /// Same as `afterFirstUnlock`, but restricted to the current device only.
    case afterFirstUnlockThisDeviceOnly

    /// Item is accessible only when a passcode is set and restricted to this device.
    case whenPasscodeSetThisDeviceOnly

    /// Item is accessible only while the device is unlocked.
    case whenUnlocked

    /// Same as `whenUnlocked`, but restricted to the current device only.
    case whenUnlockedThisDeviceOnly
}

extension KeychainAccessible {

    /// The associated Security framework attribute for the accessibility level.
    ///
    /// - Returns: The corresponding `kSecAttrAccessible*` constant.
    internal var secAttr: Any {
        switch self {
            case .afterFirstUnlock:
                return kSecAttrAccessibleAfterFirstUnlock
            case .afterFirstUnlockThisDeviceOnly:
                return kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            case .whenPasscodeSetThisDeviceOnly:
                return kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly
            case .whenUnlocked:
                return kSecAttrAccessibleWhenUnlocked
            case .whenUnlockedThisDeviceOnly:
                return kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        }
    }
}
