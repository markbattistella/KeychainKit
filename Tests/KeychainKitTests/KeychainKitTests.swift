//
// Project: KeychainKit
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import Foundation
import Testing

@testable import KeychainKit

private enum TestKey: String, KeychainKeyRepresentable {
  static let keyPrefix: String? = "com.markbattistella.keychainkit.tests"

  case token
  case website
}

@Suite("KeychainKit", .serialized)
struct KeychainKitTests {

  @Test("URL values stored through generic set round-trip through url(for:)")
  func urlRoundTripsThroughTypedAccessor() throws {
    let keychain = makeKeychain()
    defer { keychain.removeAll() }

    let url = try #require(URL(string: "https://example.com/docs?section=security"))

    try keychain.setThrowing(url, for: TestKey.website)

    #expect(keychain.url(for: TestKey.website) == url)
    let decoded: URL? = keychain.value(for: TestKey.website)
    #expect(decoded == url)
  }

  @Test("Migration uses full account keys returned by allKeys without double prefixing")
  func migrationDoesNotDoublePrefixReturnedAccountKeys() throws {
    let oldKeychain = makeKeychain(label: "old")
    let newKeychain = makeKeychain(label: "new")
    defer {
      oldKeychain.removeAll()
      newKeychain.removeAll()
    }

    try oldKeychain.setThrowing("secret-token", for: TestKey.token)

    #expect(oldKeychain.allKeys().contains(TestKey.token.value))

    let result = Keychain.migrate(
      from: nil,
      oldServiceName: oldKeychain.serviceName,
      to: nil,
      newServiceName: newKeychain.serviceName,
      mode: .perform
    )

    #expect(result.failed.isEmpty)
    #expect(result.migrated.contains(TestKey.token.value))
    #expect(result.didModify)
    #expect(oldKeychain.string(for: TestKey.token) == nil)
    #expect(newKeychain.string(for: TestKey.token) == "secret-token")
  }

  @Test("Dry-run migration reports keys without moving data")
  func dryRunMigrationDoesNotModifyKeychains() throws {
    let oldKeychain = makeKeychain(label: "old")
    let newKeychain = makeKeychain(label: "new")
    defer {
      oldKeychain.removeAll()
      newKeychain.removeAll()
    }

    try oldKeychain.setThrowing("secret-token", for: TestKey.token)

    let result = Keychain.migrate(
      from: nil,
      oldServiceName: oldKeychain.serviceName,
      to: nil,
      newServiceName: newKeychain.serviceName,
      mode: .dryRun
    )

    #expect(result.failed.isEmpty)
    #expect(result.migrated.contains(TestKey.token.value))
    #expect(result.didModify == false)
    #expect(oldKeychain.string(for: TestKey.token) == "secret-token")
    #expect(newKeychain.string(for: TestKey.token) == nil)
  }

  @Test("Perform migration reports no modification when there are no keys")
  func emptyMigrationDoesNotReportModification() {
    let oldKeychain = makeKeychain(label: "old")
    let newKeychain = makeKeychain(label: "new")
    defer {
      oldKeychain.removeAll()
      newKeychain.removeAll()
    }

    let result = Keychain.migrate(
      from: nil,
      oldServiceName: oldKeychain.serviceName,
      to: nil,
      newServiceName: newKeychain.serviceName,
      mode: .perform
    )

    #expect(result.failed.isEmpty)
    #expect(result.migrated.isEmpty)
    #expect(result.didModify == false)
  }

  private func makeKeychain(label: String = "default") -> Keychain {
    let serviceName = "com.markbattistella.keychainkit.tests.\(label).\(UUID().uuidString)"
    let keychain = Keychain(serviceName: serviceName)
    keychain.removeAll()
    return keychain
  }
}
