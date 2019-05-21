//
//  SelectableViewModelTests.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 20/05/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation
@testable import InstantSearchCore
import XCTest

class SelectableViewModelTests: XCTestCase {
  
  typealias VM = SelectableViewModel<String>
  
  func testConstruction() {
    
    let viewModel = SelectableViewModel(item: "i")
    
    XCTAssertFalse(viewModel.isSelected)
    XCTAssertEqual(viewModel.item, "i")
    
  }
  
  func testSwitchItem() {
    
    let viewModel = SelectableViewModel(item: "i")

    let switchItemExpectation = expectation(description: "item changed")
    
    viewModel.onItemChanged.subscribe(with: self) { newItem in
      XCTAssertEqual(newItem, "o")
      switchItemExpectation.fulfill()
    }
    
    viewModel.item = "o"
    
    waitForExpectations(timeout: 2, handler: nil)
  }
  
  func testSelection() {
    
    let viewModel = SelectableViewModel(item: "i")

    let selectionExpectation = expectation(description: "item selected")
    let deselectionExpectation = expectation(description: "item deselected")
    
    viewModel.onSelectedChanged.subscribe(with: self) { isSelected in
      if isSelected {
        selectionExpectation.fulfill()
      } else {
        deselectionExpectation.fulfill()
      }
    }
    
    viewModel.isSelected = true
    viewModel.isSelected = false
    
    waitForExpectations(timeout: 2, handler: nil)
    
  }
  
  func testSelectedComputed() {
    
    let viewModel = SelectableViewModel(item: "i")

    let selectedComputedExpectation = expectation(description: "computed selected")

    viewModel.onSelectedComputed.subscribe(with: self) { isSelected in
      XCTAssertEqual(isSelected, false)
      selectedComputedExpectation.fulfill()
    }
    
    viewModel.computeIsSelected(selecting: false)
    
    waitForExpectations(timeout: 2, handler: nil)
    
  }
  
}
