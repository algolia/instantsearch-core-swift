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
  
  func testSelection() {
    
    let viewModel = SelectableViewModel(item: "i")

    let selectionExpectation = expectation(description: "selectionExpectation")
    let deselectionExpectation = expectation(description: "deselectionExpectation")
    
    let selectionObserver = CallbackTester<Bool> { isSelected in
      if isSelected {
        selectionExpectation.fulfill()
      } else {
        deselectionExpectation.fulfill()
      }
    }
    
    viewModel.onSelectedChanged.subscribe(with: selectionObserver, callback: selectionObserver.callback)
    
    viewModel.isSelected = true
    viewModel.isSelected = false
    
    waitForExpectations(timeout: 2, handler: nil)
    
  }
  
  func testSelectedComputed() {
    
    let viewModel = SelectableViewModel(item: "i")

    let selectedComputedExpectation = expectation(description: "selected computed expectation")

    let selectedComputedObserver = CallbackTester<Bool> { isSelected in
      XCTAssertEqual(isSelected, false)
      selectedComputedExpectation.fulfill()
    }
    
    viewModel.onSelectedComputed.subscribe(with: selectedComputedObserver, callback: selectedComputedObserver.callback)
    
    viewModel.computeIsSelected(selecting: false)
    
    waitForExpectations(timeout: 2, handler: nil)
    
  }
  
}
