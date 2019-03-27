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
  
  /// FilterBuilder describing query filters
  public let filterBuilder: FilterBuilder
  
  /// Build filters
  func applyFilters() {
    query.filters = filterBuilder.build()
  }
  
  public init(index: Index, query: Query = Query(), filterBuilder: FilterBuilder = FilterBuilder()) {
    self.index = index
    self.query = query
    self.filterBuilder = filterBuilder
  }
  
}

extension IndexQuery {
  
  convenience init(indexSearchData: IndexSearchData) {
    self.init(index: indexSearchData.index, query: indexSearchData.query)
  }
  
}

extension Array where Element == IndexSearchData {
  
  init(indices: [InstantSearchClient.Index], query: Query = Query(), filterBuilder: FilterBuilder = FilterBuilder()) {
    self = indices.map { IndexSearchData(index: $0, query: query, filterBuilder: filterBuilder) }
  }
  
}
