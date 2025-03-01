import XCTest
import Security
@testable import SimpleKeychain

class SimpleKeychainObjCTests: XCTestCase {
  var sut: SimpleKeychainObjC!
  let service = "com.auth0.simplekeychain.objc.tests"
  
  override func setUp() {
    super.setUp()
    sut = SimpleKeychainObjC(service: service)
    
    // Clear any existing items
    var error: NSError?
    _ = sut.deleteAll(error: &error)
  }
  
  override func tearDown() {
    var error: NSError?
    _ = sut.deleteAll(error: &error)
    sut = nil
    super.tearDown()
  }
  
  func testInitializationWithDefaultValues() {
    // Default initialization should succeed
    let keychain = SimpleKeychainObjC(service: service)
    XCTAssertNotNil(keychain)
  }
  
  func testInitializationWithCustomValues() {
    // Custom initialization with all parameters should succeed
    let accessFlags = NSNumber(value: SecAccessControlCreateFlags.userPresence.rawValue)
    let keychain = SimpleKeychainObjC(
      service: service,
      accessGroup: "Group",
      accessibility: .afterFirstUnlock,
      accessControlFlags: accessFlags,
      context: nil,
      synchronizable: true,
      attributes: ["testKey": "testValue"]
    )
    XCTAssertNotNil(keychain)
  }
  
  func testStoringAndRetrievingString() {
    let key = UUID().uuidString
    let value = "TestValue-\(UUID().uuidString)"
    var error: NSError?
    
    // Store the string
    let success = sut.setString(value, forKey: key, error: &error)
    XCTAssertTrue(success, "String should be stored successfully")
    XCTAssertNil(error, "Error should be nil when storing succeeds")
    
    // Retrieve the string
    let retrievedValue = sut.string(forKey: key, error: &error)
    XCTAssertEqual(retrievedValue, value, "Retrieved value should match stored value")
    XCTAssertNil(error, "Error should be nil when retrieving succeeds")
  }
  
  func testStoringAndRetrievingData() {
    let key = UUID().uuidString
    let originalString = "TestData-\(UUID().uuidString)"
    let value = originalString.data(using: .utf8)!
    var error: NSError?
    
    // Store the data
    let success = sut.setData(value, forKey: key, error: &error)
    XCTAssertTrue(success, "Data should be stored successfully")
    XCTAssertNil(error, "Error should be nil when storing succeeds")
    
    // Retrieve the data
    let retrievedData = sut.data(forKey: key, error: &error)
    XCTAssertNotNil(retrievedData, "Retrieved data should not be nil")
    XCTAssertNil(error, "Error should be nil when retrieving succeeds")
    
    // Convert back to string and compare
    let retrievedString = String(data: retrievedData!, encoding: .utf8)
    XCTAssertEqual(retrievedString, originalString, "Retrieved data should convert back to original string")
  }
  
  func testRetrievingNonExistentItem() {
    let nonExistentKey = "nonExistentKey-\(UUID().uuidString)"
    var error: NSError?
    
    // Try to retrieve a non-existent string
    let retrievedString = sut.string(forKey: nonExistentKey, error: &error)
    XCTAssertNil(retrievedString, "Retrieved string should be nil for non-existent key")
    XCTAssertNotNil(error, "Error should not be nil when item doesn't exist")
    XCTAssertEqual(error?.domain, "SimpleKeychain.SimpleKeychainError", "Error domain should match")
    
    // Reset error for next test
    error = nil
    
    // Try to retrieve non-existent data
    let retrievedData = sut.data(forKey: nonExistentKey, error: &error)
    XCTAssertNil(retrievedData, "Retrieved data should be nil for non-existent key")
    XCTAssertNotNil(error, "Error should not be nil when item doesn't exist")
  }
  
  func testDeletingItem() {
    let key = UUID().uuidString
    var error: NSError?
    
    // Store an item
    _ = sut.setString("testValue", forKey: key, error: &error)
    XCTAssertNil(error, "Error should be nil when storing succeeds")
    
    // Verify it exists
    var exists = sut.hasItem(forKey: key, error: &error)
    XCTAssertTrue(exists, "Item should exist after storing")
    XCTAssertNil(error, "Error should be nil when checking succeeds")
    
    // Delete the item
    let success = sut.deleteItem(forKey: key, error: &error)
    XCTAssertTrue(success, "Deletion should succeed")
    XCTAssertNil(error, "Error should be nil when deletion succeeds")
    
    // Verify it's gone
    exists = sut.hasItem(forKey: key, error: &error)
    XCTAssertFalse(exists, "Item should not exist after deletion")
  }
  
  func testDeletingAllItems() {
    let keys = [UUID().uuidString, UUID().uuidString, UUID().uuidString]
    var error: NSError?
    
    // Store multiple items
    for key in keys {
      _ = sut.setString("value for \(key)", forKey: key, error: &error)
      XCTAssertNil(error, "Error should be nil when storing succeeds")
    }
    
    // Delete all items
    let success = sut.deleteAll(error: &error)
    XCTAssertTrue(success, "Deleting all items should succeed")
    XCTAssertNil(error, "Error should be nil when deletion succeeds")
    
    // Verify all items are gone
    for key in keys {
      let exists = sut.hasItem(forKey: key, error: &error)
      XCTAssertFalse(exists, "Item \(key) should not exist after deleteAll")
    }
  }
  
  func testRetrievingAllKeys() {
    let keys = [UUID().uuidString, UUID().uuidString, UUID().uuidString]
    var error: NSError?
    
    // Store multiple items
    for key in keys {
      _ = sut.setString("value for \(key)", forKey: key, error: &error)
      XCTAssertNil(error, "Error should be nil when storing succeeds")
    }
    
    // Retrieve all keys
    let retrievedKeys = sut.keys(error: &error)
    XCTAssertNotNil(retrievedKeys, "Retrieved keys should not be nil")
    XCTAssertNil(error, "Error should be nil when retrieving keys succeeds")
    
    // Verify all our keys are included
    for key in keys {
      XCTAssertTrue(retrievedKeys!.contains(key), "Retrieved keys should contain \(key)")
    }
    
    // Verify count (note: there may be other items from other tests)
    XCTAssertGreaterThanOrEqual(retrievedKeys!.count, keys.count,
                                "Should retrieve at least as many keys as we stored")
  }
  
  func testErrorHandlingForDeleteNonExistentItem() {
    let nonExistentKey = "nonExistentKey-\(UUID().uuidString)"
    var error: NSError?
    
    // Try to delete a non-existent item
    let success = sut.deleteItem(forKey: nonExistentKey, error: &error)
    XCTAssertFalse(success, "Deleting non-existent item should fail")
    XCTAssertNotNil(error, "Error should not be nil when deleting non-existent item")
    XCTAssertEqual(error?.domain, "SimpleKeychain.SimpleKeychainError", "Error domain should match")
  }
  
  func testUpdatingExistingItem() {
    let key = UUID().uuidString
    let originalValue = "original value"
    let updatedValue = "updated value"
    var error: NSError?
    
    // Store original value
    _ = sut.setString(originalValue, forKey: key, error: &error)
    XCTAssertNil(error, "Error should be nil when storing succeeds")
    
    // Update with new value
    let success = sut.setString(updatedValue, forKey: key, error: &error)
    XCTAssertTrue(success, "Updating existing item should succeed")
    XCTAssertNil(error, "Error should be nil when updating succeeds")
    
    // Verify updated value
    let retrievedValue = sut.string(forKey: key, error: &error)
    XCTAssertEqual(retrievedValue, updatedValue, "Retrieved value should match updated value")
  }
}

// MARK: - Async Tests

extension SimpleKeychainObjCTests {
  // MARK: - Async Completion Tests
  
  func testAsyncStringStorage() {
    let expectation = XCTestExpectation(description: "Store string async")
    let key = UUID().uuidString
    let value = "AsyncTestValue-\(UUID().uuidString)"
    
    // Test async string storage
    sut.setString(value as NSString, forKey: key) { error in
      XCTAssertNil(error, "Error should be nil when storing succeeds")
      XCTAssertTrue(Thread.isMainThread, "Completion should be called on main thread")
      expectation.fulfill()
    }
    
    wait(for: [expectation], timeout: 5.0)
    
    // Verify the string was stored
    var error: NSError?
    let retrievedValue = sut.string(forKey: key, error: &error)
    XCTAssertEqual(retrievedValue, value, "Retrieved value should match stored value")
    XCTAssertNil(error, "Error should be nil when retrieving succeeds")
  }
  
  func testAsyncStringRetrieval() {
    let expectation = XCTestExpectation(description: "Retrieve string async")
    let key = UUID().uuidString
    let value = "AsyncRetrieveValue-\(UUID().uuidString)"
    
    // Store string synchronously
    var error: NSError?
    let success = sut.setString(value, forKey: key, error: &error)
    XCTAssertTrue(success, "String should be stored successfully")
    XCTAssertNil(error, "Error should be nil when storing succeeds")
    
    // Test async string retrieval
    sut.string(forKey: key) { retrievedValue, error in
      XCTAssertEqual(retrievedValue as String?, value, "Retrieved value should match stored value")
      XCTAssertNil(error, "Error should be nil when retrieving succeeds")
      XCTAssertTrue(Thread.isMainThread, "Completion should be called on main thread")
      expectation.fulfill()
    }
    
    wait(for: [expectation], timeout: 5.0)
  }
  
  func testAsyncDataStorage() {
    let expectation = XCTestExpectation(description: "Store data async")
    let key = UUID().uuidString
    let originalString = "AsyncDataValue-\(UUID().uuidString)"
    let data = originalString.data(using: .utf8)! as NSData
    
    // Test async data storage
    sut.setData(data, forKey: key) { error in
      XCTAssertNil(error, "Error should be nil when storing succeeds")
      XCTAssertTrue(Thread.isMainThread, "Completion should be called on main thread")
      expectation.fulfill()
    }
    
    wait(for: [expectation], timeout: 5.0)
    
    // Verify the data was stored
    var error: NSError?
    let retrievedData = sut.data(forKey: key, error: &error)
    XCTAssertNotNil(retrievedData, "Retrieved data should not be nil")
    
    // Convert back to string and compare
    let retrievedString = String(data: retrievedData!, encoding: .utf8)
    XCTAssertEqual(retrievedString, originalString, "Retrieved data should convert back to original string")
  }
  
  func testAsyncDataRetrieval() {
    let expectation = XCTestExpectation(description: "Retrieve data async")
    let key = UUID().uuidString
    let originalString = "AsyncRetrieveDataValue-\(UUID().uuidString)"
    let data = originalString.data(using: .utf8)!
    
    // Store data synchronously
    var error: NSError?
    let success = sut.setData(data, forKey: key, error: &error)
    XCTAssertTrue(success, "Data should be stored successfully")
    
    // Test async data retrieval
    sut.data(forKey: key) { retrievedData, error in
      XCTAssertNotNil(retrievedData, "Retrieved data should not be nil")
      XCTAssertNil(error, "Error should be nil when retrieving succeeds")
      XCTAssertTrue(Thread.isMainThread, "Completion should be called on main thread")
      
      // Convert back to string and compare
      if let data = retrievedData as Data? {
        let retrievedString = String(data: data, encoding: .utf8)
        XCTAssertEqual(retrievedString, originalString, "Retrieved data should convert back to original string")
      }
      
      expectation.fulfill()
    }
    
    wait(for: [expectation], timeout: 5.0)
  }
  
  func testAsyncItemDeletion() {
    let expectation = XCTestExpectation(description: "Delete item async")
    let key = UUID().uuidString
    
    // Store item synchronously
    var error: NSError?
    _ = sut.setString("value to delete", forKey: key, error: &error)
    XCTAssertNil(error, "Error should be nil when storing succeeds")
    
    // Verify it exists
    let exists = sut.hasItem(forKey: key, error: &error)
    XCTAssertTrue(exists, "Item should exist after storing")
    
    // Delete async
    sut.deleteItem(forKey: key) { error in
      XCTAssertNil(error, "Error should be nil when deletion succeeds")
      XCTAssertTrue(Thread.isMainThread, "Completion should be called on main thread")
      expectation.fulfill()
    }
    
    wait(for: [expectation], timeout: 5.0)
    
    // Verify it's gone
    let existsAfterDeletion = sut.hasItem(forKey: key, error: &error)
    XCTAssertFalse(existsAfterDeletion, "Item should not exist after deletion")
  }
  
  func testAsyncDeleteAll() {
    let expectation = XCTestExpectation(description: "Delete all items async")
    let keys = [UUID().uuidString, UUID().uuidString, UUID().uuidString]
    var error: NSError?
    
    // Store multiple items
    for key in keys {
      _ = sut.setString("value for \(key)", forKey: key, error: &error)
      XCTAssertNil(error, "Error should be nil when storing succeeds")
    }
    
    // Verify items exist
    for key in keys {
      let exists = sut.hasItem(forKey: key, error: &error)
      XCTAssertTrue(exists, "Item \(key) should exist after storing")
    }
    
    // Delete all async
    sut.deleteAll { error in
      XCTAssertNil(error, "Error should be nil when deletion succeeds")
      XCTAssertTrue(Thread.isMainThread, "Completion should be called on main thread")
      expectation.fulfill()
    }
    
    wait(for: [expectation], timeout: 5.0)
    
    // Verify all items are gone
    for key in keys {
      let exists = sut.hasItem(forKey: key, error: &error)
      XCTAssertFalse(exists, "Item \(key) should not exist after deleteAll")
    }
  }
  
  func testAsyncHasItem() {
    let expectation = XCTestExpectation(description: "Check item existence async")
    let key = UUID().uuidString
    var error: NSError?
    
    // Store an item
    _ = sut.setString("test has item", forKey: key, error: &error)
    XCTAssertNil(error, "Error should be nil when storing succeeds")
    
    // Check async if item exists
    sut.hasItem(forKey: key) { exists, error in
      XCTAssertTrue(exists, "Item should exist")
      XCTAssertNil(error, "Error should be nil when checking succeeds")
      XCTAssertTrue(Thread.isMainThread, "Completion should be called on main thread")
      expectation.fulfill()
    }
    
    wait(for: [expectation], timeout: 5.0)
  }
  
  func testAsyncHasItemForNonExistentKey() {
    let expectation = XCTestExpectation(description: "Check non-existent item async")
    let nonExistentKey = "nonExistentKey-\(UUID().uuidString)"
    
    // Check async if non-existent item exists
    sut.hasItem(forKey: nonExistentKey) { exists, error in
      XCTAssertFalse(exists, "Non-existent item should not exist")
      XCTAssertNil(error, "Error should be nil for non-existent item check")
      XCTAssertTrue(Thread.isMainThread, "Completion should be called on main thread")
      expectation.fulfill()
    }
    
    wait(for: [expectation], timeout: 5.0)
  }
  
  func testAsyncKeys() {
    let expectation = XCTestExpectation(description: "Get keys async")
    let keys = [UUID().uuidString, UUID().uuidString, UUID().uuidString]
    var error: NSError?
    
    // First delete all existing items
    _ = sut.deleteAll(error: &error)
    
    // Store items
    for key in keys {
      _ = sut.setString("value for \(key)", forKey: key, error: &error)
      XCTAssertNil(error, "Error should be nil when storing succeeds")
    }
    
    // Get keys async
    sut.keys { retrievedKeys, error in
      XCTAssertNotNil(retrievedKeys, "Retrieved keys should not be nil")
      XCTAssertNil(error, "Error should be nil when retrieving keys succeeds")
      XCTAssertTrue(Thread.isMainThread, "Completion should be called on main thread")
      
      // Verify all our keys are included
      if let retrievedKeys = retrievedKeys {
        for key in keys {
          XCTAssertTrue(retrievedKeys.contains(key), "Retrieved keys should contain \(key)")
        }
        
        XCTAssertEqual(retrievedKeys.count, keys.count, "Should have exactly our keys")
      }
      
      expectation.fulfill()
    }
    
    wait(for: [expectation], timeout: 5.0)
  }
  
  func testAsyncErrorHandling() {
    let expectation = XCTestExpectation(description: "Error handling for non-existent item")
    let nonExistentKey = "nonExistentKey-\(UUID().uuidString)"
    
    // Try to retrieve non-existent item async
    sut.string(forKey: nonExistentKey) { value, error in
      XCTAssertNil(value, "Value should be nil for non-existent key")
      XCTAssertNotNil(error, "Error should not be nil when item doesn't exist")
      XCTAssertEqual(error?.domain, "SimpleKeychain.SimpleKeychainError", "Error domain should match")
      XCTAssertTrue(Thread.isMainThread, "Completion should be called on main thread")
      expectation.fulfill()
    }
    
    wait(for: [expectation], timeout: 5.0)
  }
  
  func testAsyncConcurrentOperations() {
    let operationCount = 10
    let expectations = (0..<operationCount).map {
      XCTestExpectation(description: "Concurrent operation \($0)")
    }
    
    // Perform multiple concurrent operations
    for i in 0..<operationCount {
      let key = "concurrent-\(i)-\(UUID().uuidString)"
      let value = "value-\(i)"
      
      // Store async
      sut.setString(value as NSString, forKey: key) { error in
        XCTAssertNil(error, "Error should be nil when storing succeeds")
        
        // Retrieve async
        self.sut.string(forKey: key) { retrievedValue, error in
          XCTAssertEqual(retrievedValue as String?, value, "Retrieved value should match for operation \(i)")
          XCTAssertNil(error, "Error should be nil when retrieving succeeds")
          XCTAssertTrue(Thread.isMainThread, "Completion should be called on main thread")
          expectations[i].fulfill()
        }
      }
    }
    
    wait(for: expectations, timeout: 10.0)
  }
}
