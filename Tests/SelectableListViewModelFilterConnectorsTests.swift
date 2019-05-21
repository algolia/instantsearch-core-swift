//
//  SelectableListViewModelFilterConnectorsTests.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 21/05/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation
@testable import InstantSearchCore
import XCTest

class SelectableListViewModelFilterConnectorsTests: XCTestCase {
  
  func testConstructors() {
    
    let facetFilterListViewModel = FilterListViewModel.Facet()
    XCTAssertEqual(facetFilterListViewModel.selectionMode, .multiple)
    
    let numericFilterListViewModel = FilterListViewModel.Numeric()
    XCTAssertEqual(numericFilterListViewModel.selectionMode, .single)

    let tagFilterListViewModel = FilterListViewModel.Tag()
    XCTAssertEqual(tagFilterListViewModel.selectionMode, .multiple)

  }
  
  func testFilterStateConnector() {
    
    let viewModel = FilterListViewModel.Tag()
    
    viewModel.items = [
      "tag1", "tag2", "tag3"
    ]

    let filterState = FilterState()
    
    filterState.notify(.add(filter: Filter.Tag(value: "tag3"), toGroupWithID: .or(name: "")))
    
    viewModel.connectFilterState(filterState, operator: .or)
    
    // FilterState -> ViewModel preselection
    
    XCTAssertEqual(viewModel.selections, ["tag3"])
    
    // FilterState -> ViewModel
    
    filterState.notify(.add(filter: Filter.Tag(value: "tag1")
      , toGroupWithID: .or(name: "")))
    
    XCTAssertEqual(viewModel.selections, ["tag1", "tag3"])
   
    // ViewModel -> FilterState
    
    viewModel.computeSelections(selectingItemForKey: "tag2")
    
    XCTAssertTrue(filterState.contains(Filter.Tag(value: "tag2"), inGroupWithID: .or(name: "")))
    
  }
  
  class TestController<F: FilterType>: SelectableListController {
    
    typealias Item = F
    
    var onClick: ((F) -> Void)?
    var didReload: (() -> Void)?
    
    var selectableItems: [(item: F, isSelected: Bool)] = []
    
    func setSelectableItems(selectableItems: [(item: F, isSelected: Bool)]) {
      self.selectableItems = selectableItems
    }
    
    func reload() {
      didReload?()
    }
    
    func clickOn(_ item: F) {
      onClick?(item)
    }
    
  }
  
  func testControllerConnector() {
    
    let viewModel = FilterListViewModel.Tag()
    let controller = TestController<Filter.Tag>()
    
    viewModel.items = ["tag1", "tag2", "tag3"]
    viewModel.selections = ["tag2"]
    
    viewModel.connectController(controller)
    
    // Test preselection
    
    XCTAssertEqual(controller.selectableItems.map { $0.0 }, [
      Filter.Tag(value: "tag1"),
      Filter.Tag(value: "tag2"),
      Filter.Tag(value: "tag3"),
    ])
    
    XCTAssertEqual(controller.selectableItems.map { $0.1 }, [
      false,
      true,
      false,
    ])
    
    // Items change
    
    let itemsChangedReloadExpectation = expectation(description: "items changed reload expectation")
    
    controller.didReload = itemsChangedReloadExpectation.fulfill
    
    viewModel.items = ["tag1", "tag2", "tag3", "tag4"]
    
    XCTAssertEqual(controller.selectableItems.map { $0.0 }, [
      Filter.Tag(value: "tag1"),
      Filter.Tag(value: "tag2"),
      Filter.Tag(value: "tag3"),
      Filter.Tag(value: "tag4"),
    ])
    
    XCTAssertEqual(controller.selectableItems.map { $0.1 }, [
      false,
      true,
      false,
      false
    ])
    
    waitForExpectations(timeout: 2, handler: nil)
    
    // Selection change
    
    let selectionsChangedReloadExpectation = expectation(description: "selections changed reload expectation")
    
    controller.didReload = selectionsChangedReloadExpectation.fulfill
    
    viewModel.selections = ["tag3", "tag4"]
    
    XCTAssertEqual(controller.selectableItems.map { $0.0 }, [
      Filter.Tag(value: "tag1"),
      Filter.Tag(value: "tag2"),
      Filter.Tag(value: "tag3"),
      Filter.Tag(value: "tag4"),
      ])
    
    XCTAssertEqual(controller.selectableItems.map { $0.1 }, [
      false,
      false,
      true,
      true
    ])

    waitForExpectations(timeout: 2, handler: nil)
    
    // Selection computation on click
    
    let selectionsComputedExpectation = expectation(description: "selections computed")
    
    viewModel.onSelectionsComputed.subscribe(with: self) { selectedTags in
      XCTAssertEqual(selectedTags, ["tag1", "tag3", "tag4"])
      selectionsComputedExpectation.fulfill()
    }
    
    controller.clickOn("tag1")
    
    waitForExpectations(timeout: 2, handler: nil)
    
  }
  
}
