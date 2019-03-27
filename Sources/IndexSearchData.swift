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
  let index: Index
  
  /// Query describing a search request
  let query: Query
  
  /// FilterBuilder describing query filters
  let filterBuilder: FilterBuilder
  
  func applyFilters() {
    query.filters = filterBuilder.build()
  }
  
}

extension IndexQuery {
  
  convenience init(indexSearchData: IndexSearchData) {
    self.init(index: indexSearchData.index, query: indexSearchData.query)
  }
  
}

extension Array where Element == IndexSearchData {
  
  init(indices: [InstantSearchClient.Index], query: Query, filterBuilder: FilterBuilder) {
    self = indices.map { IndexSearchData(index: $0, query: query, filterBuilder: filterBuilder) }
  }
  
}
