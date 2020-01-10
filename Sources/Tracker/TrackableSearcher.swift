//
//  TrackableSearcher.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 19/12/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

protocol QueryIDContainer: class {
  var queryID: String? { get set }
}

extension HitsTracker: QueryIDContainer {}

public enum TrackableSearcher {
  
  case singleIndex(SingleIndexSearcher)
  case multiIndex(MultiIndexSearcher, pointer: Int)
  
  var indexName: String {
    switch self {
    case .singleIndex(let searcher):
      return searcher.indexQueryState.index.name
      
    case .multiIndex(let searcher, pointer: let index):
      return searcher.indexQueryStates[index].index.name
    }
  }
  
  func setClickAnalyticsOn(_ on: Bool) {
    switch self {
    case .singleIndex(let searcher):
      return searcher.indexQueryState.query.clickAnalytics = on
      
    case .multiIndex(let searcher, pointer: let index):
      return searcher.indexQueryStates[index].query.clickAnalytics = on
    }
  }
  
  func subscribeForQueryIDChange<S: QueryIDContainer>(_ subscriber: S) {
    switch self {
    case .singleIndex(let searcher):
      searcher.onResults.subscribe(with: subscriber) { (subscriber, results) in
        subscriber.queryID = results.queryID
      }
    case .multiIndex(let searcher, pointer: let index):
      searcher.onResults.subscribe(with: subscriber) { (subscriber, results) in
        subscriber.queryID = results.searchResults[index].queryID
      }
    }

  }
  
}
