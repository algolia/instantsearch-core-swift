//
//  MultiHitsViewModel+Connectors.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 07/06/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public extension MultiHitsViewModel {
  
  func connectSearcher(_ searcher: MultiIndexSearcher) {
    
    zip(hitsViewModels.indices, searcher.pageLoaders).forEach {
      let (index, pageLoader) = $0
      hitsViewModels[index].pageLoader = pageLoader
    }
    
    searcher.onResults.subscribePast(with: self) { [weak self] searchResults in
      try? self?.update(searchResults.searchResults)
    }
    
    searcher.onError.subscribe(with: self) { [weak self] _  in
      let currentPages = searcher.indexSearchDatas.compactMap { $0.query.page }.map { Int($0) }
      let hitsViewModels = self?.hitsViewModels ?? []
      zip(hitsViewModels, currentPages).forEach { (hitsViewModel, page) in
        hitsViewModel.notifyPending(atIndex: page)
      }
    }
    
    searcher.onQueryChanged.subscribe(with: self) { [weak self] _ in
      self?.notifyQueryChanged()
    }
    
    let filterStates = searcher.indexSearchDatas.map { $0.filterState }
    
    zip(filterStates, hitsViewModels).forEach {
      let (filterState, hitsViewModel) = $0
      hitsViewModel.connectFilterState(filterState)
    }
    
  }
  
}
