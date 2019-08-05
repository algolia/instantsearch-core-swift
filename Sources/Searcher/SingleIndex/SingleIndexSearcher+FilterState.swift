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
  
  func connectFilterState(_ filterState: FilterState) {
    
    disjunctiveFacetingDelegate = filterState
    hierarchicalFacetingDelegate = filterState
    
    filterState.onChange.subscribePast(with: self) { searcher, filterState in
      searcher.indexQueryState.query.filters = FilterGroupConverter().sql(filterState.toFilterGroups())
      searcher.search()
    }
    
  }
  
}
