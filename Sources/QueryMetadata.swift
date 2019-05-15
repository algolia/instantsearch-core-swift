//
//  QueryMetadata.swift
//  InstantSearchCore-iOS
//
//  Created by Vladislav Fitc on 13/03/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public struct QueryMetadata {
  
  // Text of the query
  public let queryText: String?
  
  // Raw fitlers string
  public let filters: String?
  
  // Results page number
  public let page: UInt
  
  public init(query: Query) {
    queryText = query.query
    filters = query.filters
    page = query.page ?? 0
  }
  
  public init(queryText: String? = .none, filters: String? = .none, page: UInt) {
    self.queryText = queryText
    self.filters = filters
    self.page = page
  }
  
  public func isAnotherPage(for data: QueryMetadata) -> Bool {
    return queryText == data.queryText && filters == data.filters
  }
  
}

extension QueryMetadata: CustomDebugStringConvertible {
  
  public var debugDescription: String {
    return "Query: \(queryText ?? "") page: \(page) filters: \(filters ?? "[]")"
  }
  
}
