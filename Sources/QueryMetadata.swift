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
  
  init(queryText: String? = .none, filters: String? = .none, page: UInt) {
    self.queryText = queryText
    self.filters = filters
    self.page = page
  }
  
  public func isAnotherPage(for data: QueryMetadata) -> Bool {
    return queryText == data.queryText && filters == data.filters
  }
  
  func isLoadMoreRequest(lastQueryMetadata: QueryMetadata) -> Bool {
    return queryText == lastQueryMetadata.queryText && filters == lastQueryMetadata.filters
  }
  
}

extension QueryMetadata: CustomDebugStringConvertible {
  
  public var debugDescription: String {
    return "Query: \(queryText ?? "") page: \(page) filters: \(filters ?? "[]")"
  }
  
}
