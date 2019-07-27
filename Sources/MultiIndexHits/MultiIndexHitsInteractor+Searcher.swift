//
//  MultiIndexHitsInteractor+Searcher.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 07/06/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public extension MultiIndexHitsInteractor {
  
  func connectSearcher(_ searcher: MultiIndexSearcher) {
    
    zip(hitsInteractors.indices, searcher.pageLoaders).forEach {
      let (index, pageLoader) = $0
      hitsInteractors[index].pageLoader = pageLoader
    }
    
    searcher.onResults.subscribePast(with: self) { interactor, searchResults in
      do {
        try interactor.update(searchResults.searchResults)
      } catch let error {
        interactor.onError.fire(error)
      }
    }
    
    searcher.onError.subscribe(with: self) { interactor, args in
      let (queries, error) = args
      interactor.process(error, for: queries)
    }
    
    searcher.onQueryChanged.subscribe(with: self) { interactor, _ in
      interactor.notifyQueryChanged()
    }
        
  }
  
}
