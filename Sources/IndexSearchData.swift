//
//  IndexSearchData.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 27/03/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

/// Structure containing all necessary components to perform a search

public struct IndexSearchData {
  
  /// Index in which search will be performed
  public let index: Index
  
  /// Query describing a search request
  public let query: Query
  
  /// FilterState describing query filters
  public let filterState: FilterState
  
  /// Build filters
  func applyFilters() {
    query.filters = filterState.toFilterGroups().compactMap({ $0 as? FilterGroupType & SQLSyntaxConvertible }).sqlForm
  }
  
  public init(index: Index, query: Query = .init(), filterState: FilterState = .init()) {
    self.index = index
    self.query = query
    self.filterState = filterState
  }
  
}

extension IndexQuery {
  
  convenience init(indexSearchData: IndexSearchData) {
    self.init(index: indexSearchData.index, query: indexSearchData.query)
  }
  
}

extension Array where Element == IndexSearchData {
  
  init(indices: [InstantSearchClient.Index], query: Query = .init(), filterState: FilterState = .init()) {
    self = indices.map { IndexSearchData(index: $0, query: query, filterState: filterState) }
  }
  
}
