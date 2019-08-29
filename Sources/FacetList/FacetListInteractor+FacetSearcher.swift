//
//  FacetListInteractor+FacetSearcher.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 29/08/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public extension FacetListInteractor {
  
  struct FacetSearcherConnection: Connection {
    
    public let facetListInteractor: FacetListInteractor
    public let facetSearcher: FacetSearcher
    
    public func connect() {
      
      // When new facet search results then update items
      
      facetSearcher.onResults.subscribePast(with: facetListInteractor) { interactor, searchResults in
        interactor.items = searchResults.facetHits
      }
      
      // For the case of SFFV, very possible that we forgot to add the
      // attribute as searchable in `attributesForFaceting`.
      
      facetSearcher.onError.subscribe(with: facetListInteractor) { _, error in
        if let error = error.1 as? HTTPError, error.statusCode == StatusCode.badRequest.rawValue {
          assertionFailure(error.message ?? "")
        }
      }
      
    }
    
    public func disconnect() {
      facetSearcher.onResults.cancelSubscription(for: facetListInteractor)
      facetSearcher.onError.cancelSubscription(for: facetListInteractor)
    }
    
  }

}

public extension FacetListInteractor {
  
  @discardableResult func connectFacetSearcher(_ facetSearcher: FacetSearcher) -> FacetSearcherConnection {
    let connection = FacetSearcherConnection(facetListInteractor: self, facetSearcher: facetSearcher)
    connection.connect()
    return connection
  }
  
}
