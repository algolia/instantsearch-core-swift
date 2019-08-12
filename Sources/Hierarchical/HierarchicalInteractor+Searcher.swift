//
//  HierarchicalInteractor+Searcher.swift
//  InstantSearchCore
//
//  Created by Guy Daher on 03/07/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public extension HierarchicalInteractor {
  func connectSearcher(searcher: SingleIndexSearcher) {
    hierarchicalAttributes.forEach(searcher.indexQueryState.query.updateQueryFacets)
  
    searcher.onResults.subscribePast(with: self) { interactor, searchResults in

      if let hierarchicalFacets = searchResults.hierarchicalFacets {
        interactor.item = interactor.hierarchicalAttributes.map { hierarchicalFacets[$0] }.compactMap { $0 }
      } else if let firstHierarchicalAttribute = interactor.hierarchicalAttributes.first {
        interactor.item = searchResults.facets?[firstHierarchicalAttribute].flatMap { [$0] } ?? []
      } else {
        interactor.item = []
      }
    }

  }
}
