//
//  IndexQueryState.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 27/03/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation
@_exported import AlgoliaSearchClientSwift
/// Structure containing all necessary components to perform a search

public struct IndexQueryState {
  
  /// Index in which search will be performed
  public var index: Index
  
  /// Query describing a search request
  public var query: Query
  
  public init(index: Index, query: Query = .init()) {
    self.index = index
    self.query = query
  }
  
}

extension IndexQueryState: Builder {}

extension Array where Element == IndexQueryState {
  
  init(indices: [AlgoliaSearchClientSwift.Index], query: Query = .init()) {
    self = indices.map { IndexQueryState(index: $0, query: query) }
  }
  
}
