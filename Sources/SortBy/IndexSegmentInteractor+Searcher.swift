//
//  IndexSegmentInteractor+Searcher.swift
//  InstantSearchCore
//
//  Created by Guy Daher on 06/06/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public extension IndexSegmentInteractor {
  func connectSearcher(searcher: SingleIndexSearcher) {
    if let selected = selected, let index = items[selected] {
      searcher.indexQueryState.index = index
      
    }

    onSelectedComputed.subscribePast(with: self) { interactor, computed in
      if
        let selected = computed,
        let index = interactor.items[selected] {
        searcher.indexQueryState.index = index
        searcher.search()
      }
    }
  }
}
