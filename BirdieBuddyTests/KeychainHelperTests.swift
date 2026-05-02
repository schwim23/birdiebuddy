import Testing
import Foundation
@testable import BirdieBuddy

@Suite("KeychainHelper round-trip", .serialized)
struct KeychainHelperTests {
    private let key = "test.keychain.entry"

    init() { KeychainHelper.delete(key) }

    @Test("write then read returns the saved value")
    func roundTrip() {
        KeychainHelper.save("hello", for: key)
        #expect(KeychainHelper.read(key) == "hello")
        KeychainHelper.delete(key)
    }

    @Test("write twice keeps the latest value (overwrite, not append)")
    func overwrite() {
        KeychainHelper.save("first", for: key)
        KeychainHelper.save("second", for: key)
        #expect(KeychainHelper.read(key) == "second")
        KeychainHelper.delete(key)
    }

    @Test("delete removes the entry; read returns nil")
    func deleteEntry() {
        KeychainHelper.save("temp", for: key)
        KeychainHelper.delete(key)
        #expect(KeychainHelper.read(key) == nil)
    }

    @Test("read of missing key returns nil")
    func missingKey() {
        #expect(KeychainHelper.read("nonexistent.\(UUID().uuidString)") == nil)
    }
}
