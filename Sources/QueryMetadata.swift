//
//  QueryMetadata.swift
//  InstantSearchCore-iOS
//
//  Created by Vladislav Fitc on 13/03/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public struct QueryMetadata: PageMetadata {
  
  // This is the query in the search bar
  let queryText: String?
  
  // This is all params that were applied (query, filters etc)
  let filters: String?
  
  public let page: UInt
  
  init(query: Query) {
    queryText = query.query
    filters = query.filters
    page = query.page ?? 0
  }
  
  public func isAnotherPage(for data: QueryMetadata) -> Bool {
    return queryText == data.queryText && filters == data.filters
  }
  
  func isLoadMoreRequest(lastQueryMetadata: QueryMetadata) -> Bool {
    return queryText == lastQueryMetadata.queryText && filters == lastQueryMetadata.filters
  }
  
}
