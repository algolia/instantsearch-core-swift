//
//  Searcher+StatsController.swift
//  InstantSearchCore
//
//  Created by Guy Daher on 23/05/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public extension SingleIndexSearcher {
  func connectController(_ statsController: StatsController) {

    onResultsChanged.subscribe(with: self) { (_, result) in
      if case .success(let results) = result {
        statsController.renderWith(query: results.query, totalHitsCount: results.totalHitsCount, page: results.page, pagesCount: results.pagesCount, processingTimeMS: results.processingTimeMS, areFacetsCountExhaustive: results.areFacetsCountExhaustive)
      }
    }
  }
}
