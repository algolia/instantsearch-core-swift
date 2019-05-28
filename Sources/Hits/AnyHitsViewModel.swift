//
//  AnyHitsViewModel.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 15/03/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

/** This is a type-erasure protocol for HitsViewModel which makes possible
    to create a collections of hits ViewModels with different record types.
*/

protocol AnyHitsViewModel {
  
  /// Updates search results with a search results with a hit of JSON type.
  /// Internally it tries to convert JSON to a record type of hits ViewModel
  /// - Parameter searchResult:
  /// - Parameter queryMetaData:
  /// - Throws: HitsViewModel.Error.incompatibleRecordType if the derived record type mismatches the record type of corresponding hits ViewModel

  func update(withGeneric searchResults: SearchResults<JSON>, with query: Query) throws
  
  /// Returns a hit for row of a desired type
  /// - Throws: HitsViewModel.Error.incompatibleRecordType if the derived record type mismatches the record type of corresponding hits ViewModel
  
  func genericHitAtIndex<R: Decodable>(_ index: Int) throws -> R?
  
  func rawHitAtIndex(_ index: Int) -> [String: Any]?
  func numberOfHits() -> Int
  func loadMoreResults()

}

extension HitsViewModel: AnyHitsViewModel {

  func update(withGeneric searchResults: SearchResults<JSON>, with query: Query) throws {
      let encoder = JSONEncoder()
      let data = try encoder.encode(searchResults)
      let decoder = JSONDecoder()
      let typedSearchResults = try decoder.decode(SearchResults<Record>.self, from: data)
      self.update(typedSearchResults, with: query)
  }

  func genericHitAtIndex<R: Decodable>(_ row: Int) throws -> R? {
    
    guard let hit = hit(atIndex: row) else {
      return .none
    }
    
    if let castedHit = hit as? R {
      return castedHit
    } else {
      throw Error.incompatibleRecordType
    }

  }
  
  func genericHitForRow(_ row: Int) throws -> JSON? {
    
    guard let hit = hit(atIndex: row) else {
      return .none
    }
    
    if let castedHit = hit as? JSON {
      return castedHit
    } else {
      return try JSON(hit)
    }
    
  }
  
  public enum Error: Swift.Error, LocalizedError {
    case incompatibleRecordType
    
    var localizedDescription: String {
      return "Unexpected record type: \(String(describing: Record.self))"
    }
    
  }

}

/// This extension is to optimize generic search results update
/// It omits unnecessary JSON to JSON conversion

extension HitsViewModel where Record == JSON {
  
  func update(withGeneric searchResults: SearchResults<JSON>, with query: Query) throws {
    self.update(searchResults, with: query)
  }
  
}
