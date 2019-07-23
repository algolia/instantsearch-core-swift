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
  
    searcher.onResults.subscribePast(with: self) { (searchResults) in

      if let hierarchicalFacets = searchResults.hierarchicalFacets {
        self.item = self.hierarchicalAttributes.map { hierarchicalFacets[$0] }.compactMap { $0 }
      } else if let firstHierarchicalAttribute = self.hierarchicalAttributes.first {
        self.item = searchResults.facets?[firstHierarchicalAttribute].flatMap { [$0] } ?? []
      } else {
        self.item = []
      }
    }

  }
}
