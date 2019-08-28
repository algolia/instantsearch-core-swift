//
//  SingleIndexSearcher+FilterState.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 04/08/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public extension SingleIndexSearcher {
  
  /**
   Establishes connection between searcher and filterState
   - Sets `FilterState` as a disjunctive and hierarchical faceting delegate
   - Updates filters parameter of Searcher's `Query` according to a new `FilterState` content and relaunches search once `FilterState` changed
   - Parameter filterState: filter state to connect
   */
  
  struct FilterStateConnection: Connection {
    
    let singleIndexSearcher: SingleIndexSearcher
    let filterState: FilterState
        
    func connect() {
      singleIndexSearcher.disjunctiveFacetingDelegate = filterState
      singleIndexSearcher.hierarchicalFacetingDelegate = filterState
      
      filterState.onChange.subscribePast(with: singleIndexSearcher) { searcher, filterState in
        searcher.indexQueryState.query.filters = FilterGroupConverter().sql(filterState.toFilterGroups())
        searcher.indexQueryState.query.page = 0
        searcher.search()
      }
    }
    
    func disconnect() {
      singleIndexSearcher.disjunctiveFacetingDelegate = nil
      singleIndexSearcher.hierarchicalFacetingDelegate = nil
      filterState.onChange.cancelSubscription(for: singleIndexSearcher)
    }
    
  }
  
}

public extension SingleIndexSearcher {
  
  func connectFilterState(_ filterState: FilterState) -> FilterStateConnection {
    let connection = FilterStateConnection(singleIndexSearcher: self, filterState: filterState)
    connection.connect()
    return connection
  }
  
}
