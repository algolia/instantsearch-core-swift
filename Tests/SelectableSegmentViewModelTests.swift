//
//  SelectableSegmentViewModelTests.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 20/05/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation
@testable import InstantSearchCore
import XCTest

class SelectableSegmentViewModelTests: XCTestCase {
  
  typealias VM = SelectableSegmentInteractor<String, String>
  
  func testConstruction() {
    
    let viewModel = VM(items: ["k1": "i1", "k2": "i2", "k3": "i3"])
    
    XCTAssertEqual(viewModel.items, ["k1": "i1", "k2": "i2", "k3": "i3"])
    XCTAssertNil(viewModel.selected)
    
  }
  
  func testSwitchItems() {
    
    let viewModel = VM(items: ["k1": "i1", "k2": "i2", "k3": "i3"])

    let switchItemsExpectation = expectation(description: "switch items")
    
    viewModel.onItemsChanged.subscribe(with: self) { newItems in
      XCTAssertEqual(newItems, ["k4": "i4"])
      switchItemsExpectation.fulfill()
    }
    
    viewModel.items = ["k4": "i4"]
    
    waitForExpectations(timeout: 2, handler: nil)
    
  }
  
  func testSelection() {
    
    let viewModel = VM(items: ["k1": "i1", "k2": "i2", "k3": "i3"])

    let selectionExpectation = expectation(description: "selection")
    
    viewModel.onSelectedChanged.subscribe(with: self) { selectedKey in
      XCTAssertEqual(selectedKey, "k3")
      selectionExpectation.fulfill()
    }
    
    viewModel.selected = "k3"
    
    XCTAssertEqual(viewModel.selected, "k3")
    
    waitForExpectations(timeout: 2, handler: nil)
    
  }
  
  func testSelectionComputed() {
    
    let viewModel = VM(items: ["k1": "i1", "k2": "i2", "k3": "i3"])

    let selectionComputedExpectation = expectation(description: "selection computed")
    
    viewModel.onSelectedComputed.subscribe(with: self) { computedSelection in
      XCTAssertEqual(computedSelection, "k3")
      selectionComputedExpectation.fulfill()
    }
    
    viewModel.computeSelected(selecting: "k3")
    
    waitForExpectations(timeout: 2, handler: .none)

  }
  
  func nilSelectedComputedTest() {
    let viewModel = VM(items: ["k1": "i1", "k2": "i2", "k3": "i3"])
    
    let selectionComputedExp = expectation(description: "selection computed")
    
    viewModel.onSelectedComputed.subscribe(with: self) { computedSelection in
      XCTAssertNil(computedSelection)
      selectionComputedExp.fulfill()
    }
    
    viewModel.computeSelected(selecting: nil)
    
    waitForExpectations(timeout: 2, handler: .none)
  }
  
}
