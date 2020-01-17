//
//  FacetListSingleIndexSearcherConnectionTests.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 04/12/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation
@testable import InstantSearchCore
import XCTest

class FacetListSingleIndexSearcherConnectionTests: XCTestCase {

  let attribute: Attribute = "Test Attribute"
  let facets: [Facet] = .init(prefix: "v", count: 3)
  
  func testConnect() {
    let searcher = SingleIndexSearcher(appID: "", apiKey: "", indexName: "")
    let interactor = FacetListInteractor()
    
    let connection = FacetListInteractor.SingleIndexSearcherConnection(facetListInteractor: interactor, searcher: searcher, attribute: attribute)
    connection.connect()
    
    checkConnection(interactor: interactor,
                    searcher: searcher,
                    isConnected: true)
  }
  
  func testConnectMethod() {
    let searcher = SingleIndexSearcher(appID: "", apiKey: "", indexName: "")
    let interactor = FacetListInteractor()
    
    interactor.connectSearcher(searcher, with: attribute)
    
    checkConnection(interactor: interactor,
                    searcher: searcher,
                    isConnected: true)
  }
  
  func testDisconnect() {
    let searcher = SingleIndexSearcher(appID: "", apiKey: "", indexName: "")
    let interactor = FacetListInteractor()
    
    let connection = FacetListInteractor.SingleIndexSearcherConnection(facetListInteractor: interactor, searcher: searcher, attribute: attribute)
    connection.connect()
    connection.disconnect()
    
    checkConnection(interactor: interactor,
                    searcher: searcher,
                    isConnected: false)
  }
  
  func checkConnection(interactor: FacetListInteractor,
                       searcher: SingleIndexSearcher,
                       isConnected: Bool) {
    var results = SearchResults(hits: [], stats: .init())
    results.disjunctiveFacets = [attribute: facets]
    
    let onItemsChangedExpectation = expectation(description: "on items changed")
    onItemsChangedExpectation.isInverted = !isConnected
    
    interactor.onItemsChanged.subscribe(with: self) { (test, facets) in
      XCTAssertEqual(test.facets, facets)
      onItemsChangedExpectation.fulfill()
    }
    
    searcher.onResults.fire(results)
    
    waitForExpectations(timeout: 5, handler: .none)
  }
  
}
