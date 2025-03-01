import Foundation

// MARK: - Async Get

public extension SimpleKeychain {
  /// Asynchronously retrieves a `String` value from the Keychain.
  ///
  /// - Parameter key: Key of the Keychain item to retrieve.
  /// - Returns: The `String` value.
  /// - Throws: A ``SimpleKeychainError`` when the SimpleKeychain operation fails.
  func string(forKey key: String) async throws -> String {
    try await withCheckedThrowingContinuation { continuation in
      keychainQueue.async {
        do {
          let result = try self.string(forKey: key)
          continuation.resume(returning: result)
        } catch {
          continuation.resume(throwing: error)
        }
      }
    }
  }
  
  /// Asynchronously retrieves a `Data` value from the Keychain.
  ///
  /// - Parameter key: Key of the Keychain item to retrieve.
  /// - Returns: The `Data` value.
  /// - Throws: A ``SimpleKeychainError`` when the SimpleKeychain operation fails.
  func data(forKey key: String) async throws -> Data {
    try await withCheckedThrowingContinuation { continuation in
      keychainQueue.async {
        do {
          let result = try self.data(forKey: key)
          continuation.resume(returning: result)
        } catch {
          continuation.resume(throwing: error)
        }
      }
    }
  }  
}

// MARK: - Async Set

public extension SimpleKeychain {
  /// Asynchronously saves a `String` value to the Keychain.
  ///
  /// - Parameter string: Value to save in the Keychain.
  /// - Parameter key: Key for the Keychain item.
  /// - Throws: A ``SimpleKeychainError`` when the SimpleKeychain operation fails.
  func set(_ string: String, forKey key: String) async throws {
    try await withCheckedThrowingContinuation { continuation in
      keychainQueue.async {
        do {
          try self.set(string, forKey: key)
          continuation.resume()
        } catch {
          continuation.resume(throwing: error)
        }
      }
    }
  }
  
  /// Asynchronously saves a `Data` value to the Keychain.
  ///
  /// - Parameter data: Value to save in the Keychain.
  /// - Parameter key: Key for the Keychain item.
  /// - Throws: A ``SimpleKeychainError`` when the SimpleKeychain operation fails.
  func set(_ data: Data, forKey key: String) async throws {
    try await withCheckedThrowingContinuation { continuation in
      keychainQueue.async {
        do {
          try self.set(data, forKey: key)
          continuation.resume()
        } catch {
          continuation.resume(throwing: error)
        }
      }
    }
  }
}

// MARK: - Async Delete

public extension SimpleKeychain {
  /// Asynchronously deletes an item from the Keychain.
  ///
  /// - Parameter key: Key of the Keychain item to delete.
  /// - Throws: A ``SimpleKeychainError`` when the SimpleKeychain operation fails.
  func deleteItem(forKey key: String) async throws {
    try await withCheckedThrowingContinuation { continuation in
      keychainQueue.async {
        do {
          try self.deleteItem(forKey: key)
          continuation.resume()
        } catch {
          continuation.resume(throwing: error)
        }
      }
    }
  }
  
  /// Asynchronously deletes all items from the Keychain for the service and access group.
  ///
  /// - Throws: A ``SimpleKeychainError`` when the SimpleKeychain operation fails.
  func deleteAll() async throws {
    try await withCheckedThrowingContinuation { continuation in
      keychainQueue.async {
        do {
          try self.deleteAll()
          continuation.resume()
        } catch {
          continuation.resume(throwing: error)
        }
      }
    }
  }
}


// MARK: - Async Queries

public extension SimpleKeychain {
  /// Asynchronously checks if an item is stored in the Keychain.
  ///
  /// - Parameter key: Key of the Keychain item to check.
  /// - Returns: Whether the item is stored in the Keychain or not.
  /// - Throws: A ``SimpleKeychainError`` when the SimpleKeychain operation fails.
  func hasItem(forKey key: String) async throws -> Bool {
    try await withCheckedThrowingContinuation { continuation in
      keychainQueue.async {
        do {
          let result = try self.hasItem(forKey: key)
          continuation.resume(returning: result)
        } catch {
          continuation.resume(throwing: error)
        }
      }
    }
  }
  
  /// Asynchronously retrieves the keys of all items stored in the Keychain.
  ///
  /// - Returns: A `String` array containing the keys.
  /// - Throws: A ``SimpleKeychainError`` when the SimpleKeychain operation fails.
  func keys() async throws -> [String] {
    try await withCheckedThrowingContinuation { continuation in
      keychainQueue.async {
        do {
          let result = try self.keys()
          continuation.resume(returning: result)
        } catch {
          continuation.resume(throwing: error)
        }
      }
    }
  }
}
