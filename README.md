<!-- markdownlint-disable MD033 MD041 -->
<div align="center">

# KeychainKit

![Swift Versions](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fmarkbattistella%2FKeychainKit%2Fbadge%3Ftype%3Dswift-versions)

![Platforms](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fmarkbattistella%2FKeychainKit%2Fbadge%3Ftype%3Dplatforms)

![Licence](https://img.shields.io/badge/Licence-MIT-white?labelColor=blue&style=flat)

</div>

`KeychainKit` is a Swift package that provides a clean, type-safe, and extensible API for securely storing, retrieving, and managing values in the system Keychain. It supports primitives, collections, `Codable` types, synchronisation options, accessibility controls, and automated migration between service names and access groups.

## Features

- **Type-safe Keychain Keys:** Define strongly typed keys by conforming to `KeychainKeyRepresentable`, with automatic prefixing.
- **Secure Storage for Multiple Types:** Built-in support for:
  - `Bool`, `Int`, `Float`, `Double`
  - `String`, `Data`, `Date`, `URL`
  - Arrays and dictionaries
  - Any `Codable` type
- **Flexible Synchronisation:** Control whether items sync via iCloud (`KeychainSync`).
- **Accessibility Options:** Adjust Keychain accessibility via `KeychainAccessible`.
- **Utility Functions:** Persistent references, accessibility lookup, existence checks, and full key listing.
- **Migration Support:** Built-in method to migrate Keychain contents between service names and access groups.
- **Automatic Prefixing:** Derived from your bundle identifier with optional custom prefixes.

## Installation

Add `KeychainKit` to your Swift project using Swift Package Manager.

```swift
dependencies: [
  .package(url: "https://github.com/markbattistella/KeychainKit", from: "26.0.0")
]
```

### Requirements

- Swift 6.0+
- iOS 14.0+, macOS 11.0+, Mac Catalyst 14.0+, tvOS 14.0+, watchOS 7.0+, or visionOS 1.0+

## Usage

### Defining Keys

Define your Keychain keys using an enum conforming to `KeychainKeyRepresentable`:

```swift
enum KeychainKey: String, KeychainKeyRepresentable {
    case authToken
    case userProfile
    case lastLogin
}
```

Optionally override the prefix:

```swift
enum SecureKey: String, KeychainKeyRepresentable {
    static let keyPrefix: String? = "com.example.custom"

    case sessionID
}
```

### Storing Values

Store primitive types, strings, data, or any `Encodable` value:

```swift
let keychain = Keychain.standard

keychain.set("abc123", for: KeychainKey.authToken)
keychain.set(Date(), for: KeychainKey.lastLogin)
keychain.set(123, for: KeychainKey.userProfile)
```

Or using the throwing version:

```swift
try keychain.setThrowing(User(id: 9, name: "Jane"), for: KeychainKey.userProfile)
```

### Retrieving Values

Retrieve values using convenient typed accessors:

```swift
let token = keychain.string(for: KeychainKey.authToken)
let loginDate = keychain.date(for: KeychainKey.lastLogin)
let user: User? = keychain.value(for: KeychainKey.userProfile)
```

### Working with URLs, Arrays, and Dictionaries

```swift
let website = keychain.url(for: KeychainKey.authToken)

let scores: [Int]? = keychain.array(for: KeychainKey.userProfile)
let metadata: [String: String]? = keychain.dictionary(for: KeychainKey.userProfile)
```

### Using iCloud Keychain Sync

```swift
keychain.set("abc123", for: KeychainKey.authToken, sync: .iCloud)
let token = keychain.string(for: KeychainKey.authToken, sync: .iCloud)
```

Storage defaults to `.localOnly`. Reads and removals can pass a specific `sync` value, or omit it
to match both local and synchronisable items where supported by Keychain.

### Controlling Accessibility

```swift
try keychain.setThrowing(
    "secret",
    for: KeychainKey.authToken,
    accessible: .whenPasscodeSetThisDeviceOnly
)

let level = keychain.accessibility(for: KeychainKey.authToken)
```

### Listing and Checking Keys

```swift
let allKeys = keychain.allKeys()
let cloudKeys = keychain.allKeys(sync: .iCloud)
let exists = keychain.exists(for: KeychainKey.authToken)
```

### Removing Items

```swift
keychain.remove(for: KeychainKey.authToken)
keychain.removeLocalAndCloud(for: KeychainKey.authToken) // local + iCloud
keychain.removeAll() // all keys under current serviceName
keychain.removeAll(sync: .localOnly) // local keys only
```

### Migration

`KeychainKit` supports migrating Keychain contents between service names or access groups:

```swift
let result = Keychain.migrate(
    from: "old.group",
    oldServiceName: "old.service",
    to: "new.group",
    newServiceName: "new.service",
    mode: .perform
)

print(result.migrated)
print(result.failed)
```

Migration preserves the fully-qualified account names returned by `allKeys()`, so key prefixes are
not applied a second time while copying values between services or access groups. `didModify` is
`true` only when `.perform` actually migrates at least one item.

Use `.dryRun` to simulate migration without making changes:

```swift
let result = Keychain.migrate(
    from: "old.group",
    oldServiceName: "old.service",
    to: "new.group",
    mode: .dryRun
)
```

## License

`KeychainKit` is available under the MIT license. See the LICENCE file for more information.
