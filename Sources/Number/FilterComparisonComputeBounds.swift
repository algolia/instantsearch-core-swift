//
//  FilterComparisonComputeBounds.swift
//  InstantSearchCore
//
//  Created by Guy Daher on 04/06/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

extension Boundable {

  public func connectSearcher(_ searcher: SingleIndexSearcher, attribute: Attribute) {
    searcher.indexSearchData.query.updateQueryFacets(with: attribute)

    searcher.onResults.subscribePastOnce(with: self) { [weak self] searchResults in
      self?.computeBoundsFromFacetStats(attribute: attribute, facetStats: searchResults.facetStats)
    }
  }

  func computeBoundsFromFacetStats(attribute: Attribute, facetStats: [Attribute: SearchResults.FacetStats]?) {
    guard let facetStats = facetStats, let facetStatsOfAttribute = facetStats[attribute] else {
      applyBounds(bounds: nil)
      return
    }

    applyBounds(bounds: Number(facetStatsOfAttribute.min)...Number(facetStatsOfAttribute.max))
  }
}
