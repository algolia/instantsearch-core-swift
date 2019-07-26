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
    
    searcher.onResults.subscribePast(with: self) { viewModel, searchResults in
      try? viewModel.update(searchResults)
    }
    
    searcher.onError.subscribe(with: self) { viewModel, arg in
      let (query, error) = arg
      viewModel.process(error, for: query)
    }
    
    searcher.onIndexChanged.subscribePast(with: self) { viewModel, _ in
      viewModel.notifyQueryChanged()
    }
    
    searcher.onQueryChanged.subscribePast(with: self) { viewModel, _ in
      viewModel.notifyQueryChanged()
    }
    
  }
  
}
