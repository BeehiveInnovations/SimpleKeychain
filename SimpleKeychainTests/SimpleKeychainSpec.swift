import XCTest
import LocalAuthentication

@testable import SimpleKeychain

let PublicKeyTag = "public"
let PrivateKeyTag = "private"
let KeychainService = "com.auth0.simplekeychain.tests"

class SimpleKeychainTests: XCTestCase {
    var sut: SimpleKeychain!
    
    override func setUp() {
        super.setUp()
        sut = SimpleKeychain()
    }
    
    override func tearDown() {
        try? sut.deleteAll()
        sut = nil
        super.tearDown()
    }
    
    func testInitializationWithDefaultValues() {
        XCTAssertEqual(sut.accessGroup, nil)
        XCTAssertEqual(sut.service, Bundle.main.bundleIdentifier)
        XCTAssertEqual(sut.accessibility, Accessibility.afterFirstUnlock)
        XCTAssertEqual(sut.accessControlFlags, nil)
        XCTAssertEqual(sut.isSynchronizable, false)
        XCTAssertTrue(sut.attributes.isEmpty)
    }
    
    func testInitializationWithCustomValues() {
        sut = SimpleKeychain(service: KeychainService,
                             accessGroup: "Group",
                             accessibility: .whenUnlocked,
                             accessControlFlags: .userPresence,
                             synchronizable: true,
                             attributes: ["foo": "bar"])
        
        XCTAssertEqual(sut.accessGroup, "Group")
        XCTAssertEqual(sut.service, KeychainService)
        XCTAssertEqual(sut.accessibility, Accessibility.whenUnlocked)
        XCTAssertEqual(sut.accessControlFlags, .userPresence)
        XCTAssertEqual(sut.isSynchronizable, true)
        XCTAssertEqual(sut.attributes.count, 1)
        XCTAssertEqual(sut.attributes["foo"] as? String, "bar")
    }
    
    #if canImport(LocalAuthentication) && !os(tvOS)
    func testInitializationWithCustomLocalAuthenticationContext() {
        let context = LAContext()
        sut = SimpleKeychain(context: context)
        XCTAssertEqual(sut.context, context)
    }
    #endif
    
    func testStoringStringItemUnderNewKey() {
        let key = UUID().uuidString
        XCTAssertNoThrow(try sut.set("foo", forKey: key))
    }
    
    func testStoringStringItemUnderExistingKey() {
        let key = UUID().uuidString
        try? sut.set("foo", forKey: key)
        XCTAssertNoThrow(try sut.set("bar", forKey: key))
    }
    
    func testStoringDataItemUnderNewKey() {
        let key = UUID().uuidString
        XCTAssertNoThrow(try sut.set(Data(), forKey: key))
    }
    
    func testStoringDataItemUnderExistingKey() {
        let key = UUID().uuidString
        try? sut.set(Data(), forKey: key)
        XCTAssertNoThrow(try sut.set(Data(), forKey: key))
    }
    
    func testDeletingItem() {
        let key = UUID().uuidString
        try? sut.set("foo", forKey: key)
        XCTAssertNoThrow(try sut.deleteItem(forKey: key))
    }
    
    func testDeletingNonExistingItem() {
        XCTAssertThrowsError(try sut.deleteItem(forKey: "SHOULDNOTEXIST"))
    }
    
    func testDeletingAllItems() {
        let key = UUID().uuidString
        try? sut.set("foo", forKey: key)
        try? sut.deleteAll()
        XCTAssertThrowsError(try sut.string(forKey: key))
    }
    
    #if os(macOS)
    func testIncludingLimitAllAttributeWhenDeletingAllItems() {
        var limit: String?
        sut.remove = { query in
            let key = kSecMatchLimit as String
            limit = (query as NSDictionary).value(forKey: key) as? String
            return errSecSuccess
        }
        try? sut.deleteAll()
        XCTAssertEqual(limit, kSecMatchLimitAll as String)
    }
    #else
    func testNotIncludingLimitAllAttributeWhenDeletingAllItems() {
        var limit: String? = ""
        sut.remove = { query in
            let key = kSecMatchLimit as String
            limit = (query as NSDictionary).value(forKey: key) as? String
            return errSecSuccess
        }
        try? sut.deleteAll()
        XCTAssertNil(limit)
    }
    #endif
    
    func testRetrievingStringItem() {
        let key = UUID().uuidString
        try? sut.set("foo", forKey: key)
        XCTAssertEqual(try? sut.string(forKey: key), "foo")
    }
    
    func testRetrievingDataItem() {
        let key = UUID().uuidString
        try? sut.set("foo", forKey: key)
        XCTAssertNotNil(try? sut.data(forKey: key))
    }
    
    func testRetrievingNonExistingStringItem() {
        XCTAssertThrowsError(try sut.string(forKey: "SHOULDNOTEXIST")) { error in
            XCTAssertEqual(error as? SimpleKeychainError, .itemNotFound)
        }
    }
    
    func testRetrievingNonExistingDataItem() {
        XCTAssertThrowsError(try sut.data(forKey: "SHOULDNOTEXIST")) { error in
            XCTAssertEqual(error as? SimpleKeychainError, .itemNotFound)
        }
    }
    
    func testRetrievingStringItemThatCannotBeDecoded() {
        let key = UUID().uuidString
        let message = "Unable to convert the retrieved item to a String value"
        let expectedError = SimpleKeychainError(code: .unknown(message: message))
        sut.retrieve = { _, result in
            result?.pointee = .some(NSData(data: withUnsafeBytes(of: Date()) { Data($0) }))
            return errSecSuccess
        }
        XCTAssertThrowsError(try sut.string(forKey: key)) { error in
            XCTAssertEqual(error as? SimpleKeychainError, expectedError)
        }
    }
    
    func testRetrievingInvalidDataItem() {
        let key = UUID().uuidString
        let message = "Unable to cast the retrieved item to a Data value"
        let expectedError = SimpleKeychainError(code: .unknown(message: message))
        sut.retrieve = { _, result in
            result?.pointee = .some(NSDate())
            return errSecSuccess
        }
        XCTAssertThrowsError(try sut.string(forKey: key)) { error in
            XCTAssertEqual(error as? SimpleKeychainError, expectedError)
        }
    }
    
    func testCheckingStoredItem() {
        let key = UUID().uuidString
        try? sut.set("foo", forKey: key)
        XCTAssertTrue(try sut.hasItem(forKey: key))
    }
    
    func testCheckingNonExistingItem() {
        XCTAssertFalse(try sut.hasItem(forKey: "SHOULDNOTEXIST"))
    }
    
    func testRetrievingKeys() {
        var keys: [String] = []
        try? sut.deleteAll()
        keys.append(UUID().uuidString)
        keys.append(UUID().uuidString)
        keys.append(UUID().uuidString)
        for (i, key) in keys.enumerated() {
            try? sut.set("foo\(i)", forKey: key)
        }
        XCTAssertEqual(try sut.keys(), keys)
    }
    
    func testRetrievingEmptyKeys() {
        var keys: [String] = []
        try? sut.deleteAll()
        keys.append(UUID().uuidString)
        keys.append(UUID().uuidString)
        keys.append(UUID().uuidString)
        for (i, key) in keys.enumerated() {
            try? sut.set("foo\(i)", forKey: key)
        }
        for key in keys {
            XCTAssertNotNil(try? sut.data(forKey: key))
        }
        XCTAssertEqual(try sut.keys().count, keys.count)
        try? sut.deleteAll()
        let expectedError = SimpleKeychainError.itemNotFound
        for key in keys {
            XCTAssertThrowsError(try sut.data(forKey: key)) { error in
                XCTAssertEqual(error as? SimpleKeychainError, expectedError)
            }
        }
        XCTAssertEqual(try sut.keys().count, 0)
    }
    
    func testRetrievingInvalidAttributes() {
        let message = "Unable to cast the retrieved items to a [[String: Any]] value"
        let expectedError = SimpleKeychainError(code: .unknown(message: message))
        sut.retrieve = { _, result in
            result?.pointee = .some(NSDate())
            return errSecSuccess
        }
        XCTAssertThrowsError(try sut.keys()) { error in
            XCTAssertEqual(error as? SimpleKeychainError, expectedError)
        }
    }
    
    func testBaseQueryContainsDefaultAttributes() {
        let query = sut.baseQuery()
        XCTAssertEqual(query[kSecClass as String] as? String, kSecClassGenericPassword as String)
        XCTAssertEqual(query[kSecAttrService as String] as? String, sut.service)
        XCTAssertNil(query[kSecAttrAccount as String] as? String)
        XCTAssertNil(query[kSecValueData as String] as? Data)
        XCTAssertNil(query[kSecAttrAccessGroup as String] as? String)
        XCTAssertNil(query[kSecAttrSynchronizable as String] as? Bool)
        #if canImport(LocalAuthentication) && !os(tvOS)
        XCTAssertNil(query[kSecUseAuthenticationContext as String] as? LAContext)
        #endif
    }
    
    func testBaseQueryIncludesAdditionalAttributes() {
        let key = "foo"
        let value = "bar"
        sut = SimpleKeychain(attributes: [key: value])
        let query = sut.baseQuery()
        XCTAssertEqual(query[key] as? String, value)
    }
    
    func testBaseQuerySupersedesAdditionalAttributes() {
        let key = kSecAttrService as String
        let value = "foo"
        sut = SimpleKeychain(attributes: [key: value])
        let query = sut.baseQuery()
        XCTAssertEqual(query[key] as? String, sut.service)
    }
    
    func testBaseQueryIncludesAccountAttribute() {
        let key = "foo"
        let query = sut.baseQuery(withKey: key)
        XCTAssertEqual(query[kSecAttrAccount as String] as? String, key)
    }
    
    func testBaseQueryIncludesDataAttribute() {
        let data = Data()
        let query = sut.baseQuery(data: data)
        XCTAssertEqual(query[kSecValueData as String] as? Data, data)
    }
    
    func testBaseQueryIncludesAccessGroupAttribute() {
        sut = SimpleKeychain(accessGroup: "foo")
        let query = sut.baseQuery()
        XCTAssertEqual(query[kSecAttrAccessGroup as String] as? String, sut.accessGroup)
    }
    
    func testBaseQueryIncludesSynchronizableAttribute() {
        sut = SimpleKeychain(synchronizable: true)
        let query = sut.baseQuery()
        XCTAssertEqual(query[kSecAttrSynchronizable as String] as? Bool, sut.isSynchronizable)
    }
    
    #if canImport(LocalAuthentication) && !os(tvOS)
    func testBaseQueryIncludesContextAttribute() {
        sut = SimpleKeychain(context: LAContext())
        let query = sut.baseQuery()
        XCTAssertEqual(query[kSecUseAuthenticationContext as String] as? LAContext, sut.context)
    }
    #endif
    
    func testGetAllQueryContainsBaseQuery() {
        let baseQuery = sut.baseQuery()
        let query = sut.getAllQuery
        XCTAssertTrue(query.containsBaseQuery(baseQuery))
    }
    
    func testGetAllQueryContainsReturnAttribute() {
        let query = sut.getAllQuery
        XCTAssertEqual(query[kSecReturnAttributes as String] as? Bool, true)
    }
    
    func testGetAllQueryContainsLimitAttribute() {
        let query = sut.getAllQuery
        XCTAssertEqual(query[kSecMatchLimit as String] as? String, kSecMatchLimitAll as String)
    }
    
    func testGetOneQueryContainsBaseQuery() {
        let key = "foo"
        let baseQuery = sut.baseQuery(withKey: key)
        let query = sut.getOneQuery(byKey: key)
        XCTAssertTrue(query.containsBaseQuery(baseQuery))
    }
    
    func testGetOneQueryContainsDataAttribute() {
        let query = sut.getOneQuery(byKey: "foo")
        XCTAssertEqual(query[kSecReturnData as String] as? Bool, true)
    }
    
    func testGetOneQueryContainsLimitAttribute() {
        let query = sut.getOneQuery(byKey: "foo")
        XCTAssertEqual(query[kSecMatchLimit as String] as? String, kSecMatchLimitOne as String)
    }
    
    func testSetQueryContainsBaseQuery() {
        let key = "foo"
        let data = Data()
        let baseQuery = sut.baseQuery(withKey: key, data: data)
        let query = sut.setQuery(forKey: key, data: data)
        XCTAssertTrue(query.containsBaseQuery(baseQuery))
    }
    
    func testSetQueryIncludesAccessControlAttribute() {
        sut = SimpleKeychain(accessControlFlags: .userPresence)
        let query = sut.setQuery(forKey: "foo", data: Data())
        XCTAssertNotNil(query[kSecAttrAccessControl as String])
    }
    
    #if os(macOS)
    func testSetQueryDoesNotIncludeAccessibilityAttributeByDefault() {
        let query = sut.setQuery(forKey: "foo", data: Data())
        XCTAssertNil(query[kSecAttrAccessible as String] as? String)
    }
    
    func testSetQueryIncludesAccessibilityAttributeWhenICloudSharingIsEnabled() {
        sut = SimpleKeychain(synchronizable: true)
        let query = sut.setQuery(forKey: "foo", data: Data())
        let expectedAccessibility = sut.accessibility.rawValue as String
        XCTAssertEqual(query[kSecAttrAccessible as String] as? String, expectedAccessibility)
    }
    
    func testSetQueryIncludesAccessibilityAttributeWhenDataProtectionIsEnabled() {
        let attributes = [kSecUseDataProtectionKeychain as String: kCFBooleanTrue as Any]
        sut = SimpleKeychain(attributes: attributes)
        let query = sut.setQuery(forKey: "foo", data: Data())
        let expectedAccessibility = sut.accessibility.rawValue as String
        XCTAssertEqual(query[kSecAttrAccessible as String] as? String, expectedAccessibility)
    }
    #else
    func testSetQueryIncludesAccessibilityAttribute() {
        let query = sut.setQuery(forKey: "foo", data: Data())
        let expectedAccessibility = sut.accessibility.rawValue as String
        XCTAssertEqual(query[kSecAttrAccessible as String] as? String, expectedAccessibility)
    }
    #endif
}

// MARK: - Async Tests

extension SimpleKeychainTests {
  // MARK: Async String Tests
  
  func testAsyncStoringAndRetrievingStringItem() async throws {
    let key = UUID().uuidString
    let value = "async-test-value"
    
    // Store the string asynchronously
    try await sut.set(value, forKey: key)
    
    // Retrieve the string asynchronously
    let retrievedValue = try await sut.string(forKey: key)
    
    XCTAssertEqual(retrievedValue, value, "Retrieved value should match stored value")
  }
  
  func testAsyncStoringStringItemUnderExistingKey() async throws {
    let key = UUID().uuidString
    let originalValue = "original-value"
    let updatedValue = "updated-value"
    
    try await sut.set(originalValue, forKey: key)
    try await sut.set(updatedValue, forKey: key)
    
    let retrievedValue = try await sut.string(forKey: key)
    XCTAssertEqual(retrievedValue, updatedValue, "Retrieved value should match updated value")
  }
  
  func testAsyncRetrievingNonExistingStringItem() async {
    let nonExistentKey = "ASYNC-NONEXISTENT-" + UUID().uuidString
    
    await XCTAssertThrowsErrorAsync(try await sut.string(forKey: nonExistentKey)) { error in
      XCTAssertEqual(error as? SimpleKeychainError, .itemNotFound)
    }
  }
  
  // MARK: Async Data Tests
  
  func testAsyncStoringAndRetrievingDataItem() async throws {
    let key = UUID().uuidString
    let value = "data-test-value".data(using: .utf8)!
    
    try await sut.set(value, forKey: key)
    let retrievedData = try await sut.data(forKey: key)
    
    XCTAssertEqual(retrievedData, value, "Retrieved data should match stored data")
  }
  
  func testAsyncRetrievingNonExistingDataItem() async {
    let nonExistentKey = "ASYNC-NONEXISTENT-" + UUID().uuidString
    
    await XCTAssertThrowsErrorAsync(try await sut.data(forKey: nonExistentKey)) { error in
      XCTAssertEqual(error as? SimpleKeychainError, .itemNotFound)
    }
  }
  
  // MARK: Async Delete Tests
  
  func testAsyncDeletingItem() async throws {
    let key = UUID().uuidString
    try await sut.set("value-to-delete", forKey: key)
    
    // Verify item exists
    let exists = try await sut.hasItem(forKey: key)
    XCTAssertTrue(exists, "Item should exist before deletion")
    
    // Delete item
    try await sut.deleteItem(forKey: key)
    
    // Verify item is gone
    let existsAfterDeletion = try await sut.hasItem(forKey: key)
    XCTAssertFalse(existsAfterDeletion, "Item should not exist after deletion")
  }
  
  func testAsyncDeletingNonExistingItem() async {
    let nonExistentKey = "ASYNC-NONEXISTENT-" + UUID().uuidString
    
    await XCTAssertThrowsErrorAsync(try await sut.deleteItem(forKey: nonExistentKey)) { error in
      XCTAssertEqual(error as? SimpleKeychainError, .itemNotFound)
    }
  }
  
  func testAsyncDeletingAllItems() async throws {
    // Store multiple items
    let keys = [UUID().uuidString, UUID().uuidString, UUID().uuidString]
    for (i, key) in keys.enumerated() {
      try await sut.set("value-\(i)", forKey: key)
    }
    
    // Verify all items exist
    for key in keys {
      let exists = try await sut.hasItem(forKey: key)
      XCTAssertTrue(exists, "Item \(key) should exist before deleteAll")
    }
    
    // Delete all items
    try await sut.deleteAll()
    
    // Verify all items are gone
    for key in keys {
      let exists = try await sut.hasItem(forKey: key)
      XCTAssertFalse(exists, "Item \(key) should not exist after deleteAll")
    }
  }
  
  // MARK: Async Query Tests
  
  func testAsyncCheckingStoredItem() async throws {
    let key = UUID().uuidString
    try await sut.set("check-me", forKey: key)
    
    let exists = try await sut.hasItem(forKey: key)
    XCTAssertTrue(exists, "Item should exist")
  }
  
  func testAsyncCheckingNonExistingItem() async throws {
    let nonExistentKey = "ASYNC-NONEXISTENT-" + UUID().uuidString
    
    let exists = try await sut.hasItem(forKey: nonExistentKey)
    XCTAssertFalse(exists, "Nonexistent item should return false")
  }
  
  func testAsyncRetrievingKeys() async throws {
    // Clean start
    try? await sut.deleteAll()
    
    // Store items with known keys
    var keys: [String] = []
    for i in 0..<3 {
      let key = "async-key-\(i)-\(UUID().uuidString)"
      keys.append(key)
      try await sut.set("value-\(i)", forKey: key)
    }
    
    // Retrieve all keys
    let retrievedKeys = try await sut.keys()
    
    // Verify all our keys are included
    for key in keys {
      XCTAssertTrue(retrievedKeys.contains(key), "Retrieved keys should contain \(key)")
    }
    
    // Verify count matches
    XCTAssertEqual(retrievedKeys.count, keys.count, "Should have exactly our keys")
  }
  
  func testAsyncRetrievingEmptyKeys() async throws {
    // Ensure keychain is empty
    try await sut.deleteAll()
    
    // Get keys from empty keychain
    let keys = try await sut.keys()
    
    // Verify empty array is returned
    XCTAssertEqual(keys.count, 0, "Empty keychain should return empty keys array")
  }
  
  // MARK: Concurrency Tests
  
  func testConcurrentAsyncOperations() async throws {
    // Test that multiple concurrent operations work correctly
    let operationCount = 10
    let baseKey = UUID().uuidString
    
    // Create tasks for concurrent writes
    await withTaskGroup(of: Void.self) { group in
      for i in 0..<operationCount {
        group.addTask {
          do {
            try await self.sut.set("value-\(i)", forKey: "\(baseKey)-\(i)")
          } catch {
            XCTFail("Concurrent set failed: \(error)")
          }
        }
      }
    }
    
    // Verify all writes succeeded
    var retrievedValues = [String]()
    for i in 0..<operationCount {
      let value = try await sut.string(forKey: "\(baseKey)-\(i)")
      retrievedValues.append(value)
    }
    
    // Verify all values match expected
    for i in 0..<operationCount {
      XCTAssertEqual(retrievedValues[i], "value-\(i)", "Retrieved value should match for concurrent operation \(i)")
    }
  }
}

// Helper extension for XCTest to support async assertions
extension XCTest {
  func XCTAssertThrowsErrorAsync<T>(
    _ expression: @autoclosure () async throws -> T,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line,
    _ errorHandler: (_ error: Error) -> Void = { _ in }
  ) async {
    do {
      _ = try await expression()
      XCTFail(message(), file: file, line: line)
    } catch {
      errorHandler(error)
    }
  }
}

public extension Dictionary where Key == String, Value == Any {
    func containsBaseQuery(_ baseQuery: [String: Any]) -> Bool {
        let filtered = self.filter { element in
            return baseQuery.keys.contains(element.key)
        }
        return filtered == baseQuery
    }
}

public func ==(lhs: [String: Any], rhs: [String: Any]) -> Bool {
    return NSDictionary(dictionary: lhs).isEqual(to: rhs)
}

