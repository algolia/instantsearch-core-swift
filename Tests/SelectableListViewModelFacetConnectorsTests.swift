//
//  SelectableListViewModelFacetConnectorsTests.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 20/05/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation
@testable import InstantSearchCore
import XCTest

class SelectableListViewModelFacetConnectorsTests: XCTestCase {
  
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
    
    let viewModel = FacetListViewModel(selectionMode: .single)
    
    viewModel.items = [
      .init(value: "cat1", count: 10, highlighted: nil),
      .init(value: "cat2", count: 5, highlighted: nil),
      .init(value: "cat3", count: 5, highlighted: nil),
    ]
    
    let filterState = FilterState()
    
    viewModel.connect(to: filterState, with: "categories", operator: .and)
    
    // ViewModel -> FilterState
    viewModel.computeSelections(selectingItemForKey: "cat1")
    XCTAssertTrue(filterState.contains(Filter.Facet.init(attribute: "categories", stringValue: "cat1"), inGroupWithID: .and(name: "categories")))
    
    // FilterState -> ViewModel
    
    filterState.notify(.add(filter: Filter.Facet(attribute: "categories", stringValue: "cat2"), toGroupWithID: .and(name: "categories")))
    
    XCTAssertEqual(viewModel.selections, ["cat1", "cat2"])
    
  }
  
  func testConnectSearcher() {
    let viewModel = FacetListViewModel(selectionMode: .single)

    let index = Client(appID: "", apiKey: "").index(withName: "i")
    let query = Query()
    let filterState = FilterState()
    let searcher = SingleIndexSearcher<String>(index:index , query: query, filterState: filterState, requestOptions: .none)
    
    viewModel.connect(to: searcher, with: "type")
        
    let bundle = Bundle(for: SelectableListViewModelFacetConnectorsTests.self)
    
    do {
      let results = try SearchResults<String>(jsonFile: "SearchResultFacets", bundle: bundle)
      
      searcher.onResultsChanged.fire((query, filterState.filters,.success(results)))

      let expectedFacets: Set<Facet> = [
        .init(value: "book", count: 357, highlighted: nil),
        .init(value: "electronics", count: 184, highlighted: nil),
        .init(value: "gifts", count: 27, highlighted: nil),
        .init(value: "office", count: 28, highlighted: nil),
      ]
      
      XCTAssertEqual(Set(viewModel.items), expectedFacets)
      
    } catch let error {
      XCTFail(error.localizedDescription)
    }
    
    
    
  }
  
  func testConnectController() {
    
    let viewModel = FacetListViewModel(selectionMode: .single)

    let controller = TestController()
    
    viewModel.connect(to: controller)
    
    let reloadExpectation = expectation(description: "reload")
    reloadExpectation.expectedFulfillmentCount = 2
    
    controller.didReload = {
      reloadExpectation.fulfill()
    }
    
    viewModel.items = [
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
    
    viewModel.selections = ["cat1", "cat3"]
    
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
