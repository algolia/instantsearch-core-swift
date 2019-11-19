//
//  FacetSearcher+FilterState.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 05/08/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public extension FacetSearcher {
  
  /**
   Establishes connection between searcher and filterState
   - Updates filters parameter of Searcher's `Query` according to a new `FilterState` content and relaunches search once `FilterState` changed
   - Parameter filterState: filter state to connect
   */
  
  func connectFilterState(_ filterState: FilterState, triggerSearchOnFilterStateChange: Bool = true) {
    filterState.onChange.subscribePast(with: self) { searcher, filterState in
      searcher.indexQueryState.query.filters = FilterGroupConverter().sql(filterState.toFilterGroups())

      if triggerSearchOnFilterStateChange {
        searcher.search()
      }
    }
  }
  
}
