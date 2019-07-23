//
//  SelectableInteractorConnectorsTests.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 20/05/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation
@testable import InstantSearchCore
import XCTest

class TestSelectableController<Item>: SelectableController {
  
  var item: Item?
  var onClick: ((Bool) -> Void)?
  
  var isSelected: Bool = false
  
  func setSelected(_ isSelected: Bool) {
    self.isSelected = isSelected
  }
  
  func setItem(_ item: Item) {
    self.item = item
  }
  
  func toggle() {
    isSelected = !isSelected
    onClick?(isSelected)
  }
  
}

class SelectableInteractorConnectorsTests: XCTestCase {
  
  func testConnectFilterState() {
    
    let filterState = FilterState()
    
    let interactor = SelectableInteractor<Filter.Tag>(item: "tag")
  
    interactor.connectFilterState(filterState)
    
    // Interactor to FilterState
    
    XCTAssertTrue(filterState.filters.isEmpty)
    
    interactor.computeIsSelected(selecting: true)
    
    let groupID: FilterGroup.ID = .or(name: "_tags", filterType: .tag)
    
    
    XCTAssertTrue(filterState.filters.contains(Filter.Tag("tag"), inGroupWithID: groupID))
    
    interactor.computeIsSelected(selecting: false)
    
    XCTAssertTrue(filterState.filters.isEmpty)
  
    // FilterState to Interactor
    
    filterState.notify(.add(filter: Filter.Tag("tag"), toGroupWithID: groupID))
    
    XCTAssertTrue(interactor.isSelected)
    
  }
  
  func testConnectController() {
    
    let interactor = SelectableInteractor<Filter.Tag>(item: "tag")
    
    interactor.isSelected = true

    let controller = TestSelectableController<Filter.Tag>()
    
    interactor.connectController(controller)
    
    // Pre-selection transmission
    
    XCTAssertTrue(controller.isSelected)
    
    // Interactor -> Controller
    
    interactor.isSelected = false
    
    XCTAssertFalse(controller.isSelected)
    
    // Controller -> Interactor
    
    let selectedComputedExpectation = expectation(description: "selected computed")
    
    interactor.onSelectedComputed.subscribe(with: self) { isSelected in
      XCTAssertTrue(isSelected)
      selectedComputedExpectation.fulfill()
    }
    
    controller.toggle()
    
    waitForExpectations(timeout: 2, handler: nil)
  }
  
}
