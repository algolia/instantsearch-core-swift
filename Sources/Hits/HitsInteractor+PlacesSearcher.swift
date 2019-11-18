//
//  HitsInteractor+PlacesSearcher.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 29/08/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

extension HitsInteractor where Record == Hit<Place> {
  
  public func connectPlacesSearcher(_ searcher: PlacesSearcher) {
    
    self.pageLoader = searcher
    
    searcher.onResults.subscribePast(with: self) { interactor, searchResults in
      interactor.update(searchResults)
    }

    searcher.onError.subscribe(with: self) { _, _ in
      //TODO: when pagination added, notify pending query in infinite scrolling controller
    }
    
    searcher.onQueryChanged.subscribe(with: self) { (interactor, _) in
      interactor.notifyQueryChanged()
    }
    
  }
  
}
