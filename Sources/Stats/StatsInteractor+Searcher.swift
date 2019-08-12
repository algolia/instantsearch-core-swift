//
//  StatsInteractor+Searcher.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 29/07/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public extension StatsInteractor {
  
  func connectSearcher(_ searcher: SingleIndexSearcher) {
    
    searcher.onResults.subscribePast(with: self) { interactor, searchResults in
      interactor.item = searchResults.stats
    }
    
    searcher.onError.subscribe(with: self) { interactor, _ in
      interactor.item = .none
    }
  }

}
