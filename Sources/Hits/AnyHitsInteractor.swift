//
//  AnyHitsInteractor.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 15/03/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

/** This is a type-erasure protocol for HitsInteractor which makes possible
    to create a collections of hits interactors with different record types.
*/

public protocol AnyHitsInteractor: class {
  
  var pageLoader: PageLoadable? { get set }
  
  /// Updates search results with a search results with a hit of JSON type.
  /// Internally it tries to convert JSON to a record type of hits Interactor
  /// - Parameter searchResults:
  /// - Throws: HitsInteractor.Error.incompatibleRecordType if the derived record type mismatches the record type of corresponding hits Interactor

  func update(_ searchResults: SearchResults) throws
  
  /// Returns a hit for row of a desired type
  /// - Throws: HitsInteractor.Error.incompatibleRecordType if the derived record type mismatches the record type of corresponding hits Interactor
  
  func genericHitAtIndex<R: Decodable>(_ index: Int) throws -> R?
  
  /// Returns a hit for row as dictionary
  
  func rawHitAtIndex(_ index: Int) -> [String: Any]?
  
  /// Returns number of hits
  func numberOfHits() -> Int
  
  func notifyQueryChanged()
  func notifyPending(atIndex index: Int)

}
