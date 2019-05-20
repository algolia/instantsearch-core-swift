//
//  SelectableViewModelConnectorsTests.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 20/05/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation
@testable import InstantSearchCore
import XCTest

class TestSelectableController: SelectableController {
  
  typealias Item = String
  
  var onClick: ((Bool) -> Void)?
  
  var isSelected: Bool = false
  
  func setSelected(_ isSelected: Bool) {
    self.isSelected = isSelected
  }
  
  func toggle() {
    isSelected = !isSelected
    onClick?(isSelected)
  }
  
}

class SelectableViewModelConnectorsTests: XCTestCase {
  
  func testConnectFilterState() {
    
    let filterState = FilterState()
    
    let viewModel = SelectableViewModel<Filter.Tag>(item: "tag")
    
    viewModel.connectFilterState(filterState)
    
    // ViewModel to FilterState
    
    XCTAssertTrue(filterState.filters.isEmpty)
    
    viewModel.computeIsSelected(selecting: true)
    
    XCTAssertTrue(filterState.filters.contains(Filter.Tag("tag"), inGroupWithID: FilterGroup.ID.or(name: "_tags")))
    
    viewModel.computeIsSelected(selecting: false)
    
    XCTAssertTrue(filterState.filters.isEmpty)
  
    // FilterState to ViewModel
    
    filterState.notify(.add(filter: Filter.Tag("tag"), toGroupWithID: FilterGroup.ID.or(name: "_tags")))
    
    XCTAssertTrue(viewModel.isSelected)
    
  }
  
  func testConnectController() {
    
    let viewModel = SelectableViewModel<Filter.Tag>(item: "tag")
    
    viewModel.isSelected = true

    let controller = TestSelectableController()
    
    viewModel.connectViewController(controller)
    
    // Pre-selection transmission
    
    XCTAssertTrue(controller.isSelected)
    
    // ViewModel -> Controller
    
    viewModel.isSelected = false
    
    XCTAssertFalse(controller.isSelected)
    
    // Controller -> ViewModel
    
    let selectedComputedExpectation = expectation(description: "selected computed")
    
    viewModel.onSelectedComputed.subscribe(with: self) { isSelected in
      XCTAssertTrue(isSelected)
      selectedComputedExpectation.fulfill()
    }
    
    controller.toggle()
    
    waitForExpectations(timeout: 2, handler: nil)
  }
  
}
