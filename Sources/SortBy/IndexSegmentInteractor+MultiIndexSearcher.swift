//
//  IndexSegmentInteractor+MultiIndexSearcher.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 12/09/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public extension IndexSegmentInteractor {
  
  func connectSearcher(searcher: MultiIndexSearcher, toQueryAtIndex queryIndex: Int) {
    
    if let selected = selected, let index = items[selected] {
      searcher.indexQueryStates[queryIndex].index = index
      searcher.indexQueryStates[queryIndex].query.page = 0
    }
    
    onSelectedComputed.subscribePast(with: self) { interactor, computed in
      if
        let selected = computed,
        let index = interactor.items[selected] {
        self.selected = selected
        searcher.indexQueryStates[queryIndex].index = index
        searcher.indexQueryStates[queryIndex].query.page = 0
        searcher.search()
      }
    }
    
  }
  
}
