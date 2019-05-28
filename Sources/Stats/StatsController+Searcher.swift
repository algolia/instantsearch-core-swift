//
//  Searcher+StatsController.swift
//  InstantSearchCore
//
//  Created by Guy Daher on 23/05/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public extension StatsController {
  func connectTo<T>(_ searcher: SingleIndexSearcher<T>) {

    searcher.onResultsChanged.subscribePast(with: self) { (query, _, result) in
      if case .success(let results) = result {
        let statsMedata = StatsMetadata(query: results.query, totalHitsCount: results.totalHitsCount, page: results.page, pagesCount: results.pagesCount, processingTimeMS: results.processingTimeMS, areFacetsCountExhaustive: results.areFacetsCountExhaustive)
          self.renderWith(statsMetadata: statsMedata, query: query, filterState: FilterState(), searchResults: results)
      }
    }
  }
}
