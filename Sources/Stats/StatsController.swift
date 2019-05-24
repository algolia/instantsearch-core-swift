//
//  StatsController.swift
//  InstantSearchCore
//
//  Created by Guy Daher on 23/05/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public struct StatsMetadata {
  let query: String?
  let totalHitsCount: Int
  let page: Int
  let pagesCount: Int
  let processingTimeMS: Int
  let areFacetsCountExhaustive: Bool?
}

public protocol StatsController: class {
  func renderWith<T>(statsMetadata: StatsMetadata, query: Query, filterState: FilterState, searchResults: SearchResults<T>)
}
