//
//  Searcher.swift
//  InstantSearchCore
//
//  Created by Guy Daher on 05/03/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public protocol Searcher: class {
  
  var query: String? { get set }
    
  var isLoading: Observer<Bool> { get }
  var onQueryChanged: Observer<String?> { get }
  
  func search()
  func cancel()
  
}

extension Searcher {
    
  func transform<T: Decodable>(content: [String: Any]?, error: Error?) -> Result<T, Error> {
    let result = Result(value: content, error: error)
    
    switch result {
    case .success(let value):
      do {
        let data = try JSONSerialization.data(withJSONObject: value, options: [])
        let decoder = JSONDecoder()
        
        let result = try decoder.decode(T.self, from: data)
        return .success(result)
      } catch let error {
        return .failure(error)
      }
      
    case .failure(let error):
      return .failure(error)
    }
    
  }

  /// Add the library's version to the client's user agents, if not already present.
  func updateClientUserAgents() {

    var userAgents: [LibraryVersion] = []

    let bundle = Bundle(for: type(of: self))
    if let version = bundle.infoDictionary?["CFBundleShortVersionString"] as? String,
      let name = bundle.infoDictionary?["CFBundleName"] as? String {
      let libraryVersion = LibraryVersion(name: name, version: version)
      userAgents.append(libraryVersion)
    }

    // Add the operating system's version to the user agents.
    if #available(iOS 8.0, OSX 10.0, tvOS 9.0, *) {
      let osVersion = ProcessInfo.processInfo.operatingSystemVersion
      var osVersionString = "\(osVersion.majorVersion).\(osVersion.minorVersion)"
      if osVersion.patchVersion != 0 {
        osVersionString += ".\(osVersion.patchVersion)"
      }
      if let osName = osName {
        userAgents.append(LibraryVersion(name: osName, version: osVersionString))
      }
    }

    userAgents.forEach(Client.addUserAgent)

  }
  
}

extension Searcher where Self: SequencerDelegate {
  public func didChangeOperationsState(hasPendingOperations: Bool) {
    isLoading.fire(hasPendingOperations)
  }
}

public protocol SearchResultObservable {
  
  associatedtype SearchResult
  
  var onResults: Observer<SearchResult> { get }
  
}

// MARK: - Miscellaneous

/// The operating system's name.
///
/// - returns: The operating system's name, or nil if it could not be determined.
///
internal var osName: String? {
  #if os(iOS)
  return "iOS"
  #elseif os(OSX)
  return "macOS"
  #elseif os(tvOS)
  return "tvOS"
  #elseif os(watchOS)
  return "watchOS"
  #else
  return nil
  #endif
}
