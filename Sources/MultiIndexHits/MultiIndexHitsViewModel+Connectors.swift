//
//  MultiIndexHitsViewModel+Connectors.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 07/06/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public extension MultiIndexHitsViewModel {
  
  func connectSearcher(_ searcher: MultiIndexSearcher) {
    
    zip(hitsViewModels.indices, searcher.pageLoaders).forEach {
      let (index, pageLoader) = $0
      hitsViewModels[index].pageLoader = pageLoader
    }
    
    searcher.onResults.subscribePast(with: self) { [weak self] searchResults in
      do {
        try self?.update(searchResults.searchResults)
      } catch let error {
        self?.onError.fire(error)
      }
    }
    
    searcher.onError.subscribe(with: self) { [weak self] (queries, error)  in
      self?.process(error, for: queries)
    }
    
    searcher.onQueryChanged.subscribe(with: self) { [weak self] _ in
      self?.notifyQueryChanged()
    }
        
  }
  
}
