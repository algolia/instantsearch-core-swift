//
//  HierarchicalViewModel+Searcher.swift
//  InstantSearchCore
//
//  Created by Guy Daher on 03/07/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

//public extension HierarchicalViewModel {
//  func connectSearcher(searcher: SingleIndexSearcher) {
//    hierarchicalAttributes.forEach(searcher.indexSearchData.query.updateQueryFacets)
//
//    searcher.onResults.subscribePast(with: self) { (searchResults) in
//      guard let firstHierarchicalAttribute = self.hierarchicalAttributes.first else { return }
//      let
//      let hierarchicalFacets = searchResults.hierarchicalFacets ?? searchResults.facets?[firstHierarchicalAttribute] ?? []
//    }
//
//  }
//}
