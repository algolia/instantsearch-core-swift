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

  func update(withGeneric searchResults: SearchResults<JSON>, with queryMetadata: QueryMetadata) throws
  
  /// Returns a hit for row of a desired type
  /// - Throws: HitsViewModel.Error.incompatibleRecordType if the derived record type mismatches the record type of corresponding hits ViewModel
  
  func genericHitForRow<R: Decodable>(_ row: Int) throws -> R?
  
  func rawHitForRow(_ row: Int) -> [String: Any]?
  func numberOfRows() -> Int
  func loadMoreResults()

}

extension HitsViewModel: AnyHitsViewModel {

  func update(withGeneric searchResults: SearchResults<JSON>, with queryMetadata: QueryMetadata) throws {
      let encoder = JSONEncoder()
      let data = try encoder.encode(searchResults)
      let decoder = JSONDecoder()
      let typedSearchResults = try decoder.decode(SearchResults<RecordType>.self, from: data)
      self.update(typedSearchResults, with: queryMetadata)
  }

  func genericHitForRow<R: Decodable>(_ row: Int) throws -> R? {
    
    guard let hit = hitForRow(row) else {
      return .none
    }
    
    if let castedHit = hit as? R {
      return castedHit
    } else {
      throw Error.incompatibleRecordType
    }

  }
  
  public enum Error: Swift.Error, LocalizedError {
    case incompatibleRecordType
    
    var localizedDescription: String {
      return "Unexpected record type: \(String(describing: RecordType.self))"
    }
    
  }

}

/// This extension is to optimize generic search results update
/// It omits unnecessary JSON to JSON conversion

extension HitsViewModel where RecordType == JSON {
  
  func update(withGeneric searchResults: SearchResults<JSON>, with queryMetadata: QueryMetadata) throws {
    self.update(searchResults, with: queryMetadata)
  }
  
}
