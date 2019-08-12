//
//  MultiIndexSearcher+FilterState.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 04/08/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

extension MultiIndexSearcher {
  
  /**
   Establishes connection between searcher and filterState
   - Updates filters parameter of Searcher's `Query` at specified index according to a new `FilterState` content and relaunches search once `FilterState` changed
   - Parameter filterState: filter state to connect
   - Parameter index: index of query to attach to filter state
   */

  func connectFilterState(_ filterState: FilterState, withQueryAtIndex index: Int) {
    filterState.onChange.subscribe(with: self) { searcher, filterState in
      searcher.indexQueryStates[index].query.filters = FilterGroupConverter().sql(filterState.toFilterGroups())
      searcher.search()
    }
  }
  
}
