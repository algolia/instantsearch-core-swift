//
//  HitsInteractor+Connectors.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 04/06/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

extension HitsInteractor {
  
  public func connectSearcher(_ searcher: SingleIndexSearcher) {
    
    pageLoader = searcher
    
    searcher.onResults.subscribePast(with: self) { interactor, searchResults in
      try? interactor.update(searchResults)
    }
    
    searcher.onError.subscribe(with: self) { interactor, arg in
      let (query, error) = arg
      interactor.process(error, for: query)
    }
    
    searcher.onIndexChanged.subscribePast(with: self) { interactor, _ in
      interactor.notifyQueryChanged()
    }
    
    searcher.onQueryChanged.subscribePast(with: self) { interactor, _ in
      interactor.notifyQueryChanged()
    }
    
  }
  
}
