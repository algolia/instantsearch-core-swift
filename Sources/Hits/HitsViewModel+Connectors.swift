//
//  HitsViewModel+Connectors.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 04/06/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

extension AnyHitsViewModel {
  
  public func connectFilterState(_ filterState: FilterState) {
    filterState.onChange.subscribePast(with: self) { [weak self] _ in
      self?.notifyQueryChanged()
    }
  }
  
}

extension HitsViewModel {
  
  public func connectSearcher(_ searcher: SingleIndexSearcher) {
    
    pageLoader = searcher
    
    searcher.onResults.subscribePast(with: self) { [weak self] searchResults in
      try? self?.update(searchResults)
    }
    
    searcher.onError.subscribe(with: self) { [weak self] (arg) in
      let (query, error) = arg
      self?.process(error, for: query)
    }
    
    searcher.onIndexChanged.subscribePast(with: self) { [weak self] _ in
      self?.notifyQueryChanged()
    }
    
    searcher.onQueryChanged.subscribePast(with: self) { [weak self] _ in
      self?.notifyQueryChanged()
    }
    
  }
  
}
