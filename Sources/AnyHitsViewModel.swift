//
//  AnyHitsViewModel.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 15/03/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

protocol AnyHitsViewModel {
  
  func update(withGeneric searchResults: SearchResults<JSON>, with queryMetadata: QueryMetadata) throws
  func genericHitForRow<R: Decodable>(_ row: Int) throws -> R?
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
