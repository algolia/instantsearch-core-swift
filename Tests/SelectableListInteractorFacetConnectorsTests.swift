//
//  SelectableListInteractorFacetConnectorsTests.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 20/05/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation
@testable import InstantSearchCore
import XCTest

class SelectableListInteractorFacetConnectorsTests: XCTestCase {
  
  class TestController: FacetListController {
    
    typealias Item = Facet

    var onClick: ((Facet) -> Void)?
    var didReload: (() -> Void)?
    var selectableItems: [(item: Facet, isSelected: Bool)] = []
    
    func setSelectableItems(selectableItems: [(item: Facet, isSelected: Bool)]) {
      self.selectableItems = selectableItems
    }
    
    func reload() {
      didReload?()
    }
    
  }
  
  func testConnectFilterState() {
    
    let interactor = FacetListInteractor(selectionMode: .single)
    
    interactor.items = [
      .init(value: "cat1", count: 10, highlighted: nil),
      .init(value: "cat2", count: 5, highlighted: nil),
      .init(value: "cat3", count: 5, highlighted: nil),
    ]
    
    let filterState = FilterState()
    
    interactor.connectFilterState(filterState, with: "categories", operator: .and)
    
    let groupID: FilterGroup.ID = .and(name: "categories")
    
    // Interactor -> FilterState
    interactor.computeSelections(selectingItemForKey: "cat1")
        
    XCTAssertTrue(filterState.contains(Filter.Facet(attribute: "categories", stringValue: "cat1"), inGroupWithID: groupID))
    
    // FilterState -> Interactor
    
    filterState.notify(.add(filter: Filter.Facet(attribute: "categories", stringValue: "cat2"), toGroupWithID: groupID))
    
    XCTAssertEqual(interactor.selections, ["cat1", "cat2"])
    
  }
  
  func testConnectSearcher() {
    let interactor = FacetListInteractor(selectionMode: .single)

    let query = Query()
    let searcher = SingleIndexSearcher(index: .test, query: query, requestOptions: .none)
    
    interactor.connectSearcher(searcher, with: "type")
    
    let bundle = Bundle(for: SelectableListInteractorFacetConnectorsTests.self)
    
    do {
      let results = try SearchResults(jsonFile: "SearchResultFacets", bundle: bundle)
      
      searcher.onResults.fire(results)

      let expectedFacets: Set<Facet> = [
        .init(value: "book", count: 357, highlighted: nil),
        .init(value: "electronics", count: 184, highlighted: nil),
        .init(value: "gifts", count: 27, highlighted: nil),
        .init(value: "office", count: 28, highlighted: nil),
      ]
      
      XCTAssertEqual(Set(interactor.items), expectedFacets)
      
    } catch let error {
      XCTFail(error.localizedDescription)
    }
    
    
    
  }
  
  func testConnectController() {
    
    let interactor = FacetListInteractor(selectionMode: .single)

    let controller = TestController()
    
    interactor.connectController(controller)
    
    let reloadExpectation = expectation(description: "reload")
    reloadExpectation.expectedFulfillmentCount = 2
    
    controller.didReload = {
      reloadExpectation.fulfill()
    }
    
    interactor.items = [
      .init(value: "cat1", count: 10, highlighted: nil),
      .init(value: "cat2", count: 20, highlighted: nil),
      .init(value: "cat3", count: 30, highlighted: nil)
    ]
    
    let expectedItems = [
      (item: Facet(value: "cat1", count: 10, highlighted: nil), isSelected: false),
      (item: Facet(value: "cat2", count: 20, highlighted: nil), isSelected: false),
      (item: Facet(value: "cat3", count: 30, highlighted: nil), isSelected: false),
    ]
    
    XCTAssertEqual(controller.selectableItems.map { $0.0 }, expectedItems.map { $0.0 })
    XCTAssertEqual(controller.selectableItems.map { $0.1 }, expectedItems.map { $0.1 })
    
    interactor.selections = ["cat1", "cat3"]
    
    let expectedItems2 = [
      (item: Facet(value: "cat1", count: 10, highlighted: nil), isSelected: true),
      (item: Facet(value: "cat2", count: 20, highlighted: nil), isSelected: false),
      (item: Facet(value: "cat3", count: 30, highlighted: nil), isSelected: true),
    ]
    
    XCTAssertEqual(controller.selectableItems.map { $0.0 }, expectedItems2.map { $0.0 })
    XCTAssertEqual(controller.selectableItems.map { $0.1 }, expectedItems2.map { $0.1 })
    
    waitForExpectations(timeout: 2, handler: nil)
    
  }
  
}
