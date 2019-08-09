//
//  FacetListInteractor+Searcher.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 02/08/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public extension FacetListInteractor {
  
  func connectSearcher(_ searcher: SingleIndexSearcher, with attribute: Attribute) {
    whenNewSearchResultsThenUpdateItems(of: searcher, attribute)
    searcher.indexQueryState.query.updateQueryFacets(with: attribute)
  }
  
  func connectFacetSearcher(_ facetSearcher: FacetSearcher) {
    whenNewFacetSearchResultsThenUpdateItems(of: facetSearcher)
  }
  
}

private extension FacetListInteractor {
  
  func whenNewFacetSearchResultsThenUpdateItems(of facetSearcher: FacetSearcher) {
    
    facetSearcher.onResults.subscribePast(with: self) { interactor, searchResults in
      interactor.items = searchResults.facetHits
    }
    
    facetSearcher.onError.subscribe(with: self) { _, error in
      if let error = error.1 as? HTTPError, error.statusCode == StatusCode.badRequest.rawValue {
        // For the case of SFFV, very possible that we forgot to add the
        // attribute as searchable in `attributesForFaceting`.
        assertionFailure(error.message ?? "")
      }
    }
    
  }
  
  func whenNewSearchResultsThenUpdateItems(of searcher: SingleIndexSearcher, _ attribute: Attribute) {
    searcher.onResults.subscribePast(with: self) { interactor, searchResults in
      interactor.items = searchResults.disjunctiveFacets?[attribute] ?? searchResults.facets?[attribute] ?? []
    }
  }
  
}
