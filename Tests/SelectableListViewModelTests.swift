//
//  SelectableListViewModelTests.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 20/05/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation
@testable import InstantSearchCore
import XCTest

class SelectableListViewModelTests: XCTestCase {
  
  typealias VM = SelectableListViewModel<String, String>
  
  func testConstruction() {
    
    let viewModel = VM(items: [], selectionMode: .single)
    
    XCTAssert(viewModel.items.isEmpty)
    XCTAssertEqual(viewModel.selectionMode, .single)
    
    let anotherViewModel = VM(items: ["s1", "s2"], selectionMode: .multiple)
    
    XCTAssertEqual(anotherViewModel.items, ["s1", "s2"])
    XCTAssertEqual(anotherViewModel.selectionMode, .multiple)
    
  }
  
  func testSwitchItems() {
    
    let viewModel = VM(items: [], selectionMode: .single)
    
    let items = ["s1", "s2", "s3"]
    let switchItemsExpectation = expectation(description: "switch items")
        
    viewModel.onItemsChanged.subscribe(with: self) { newItems in
      XCTAssertEqual(newItems, items)
      switchItemsExpectation.fulfill()
    }
    
    viewModel.items = items
    
    waitForExpectations(timeout: 2, handler: .none)
  }
  
  func testOnSelectionsChanged() {
    let viewModel = VM(items: ["s1", "s2", "s3"], selectionMode: .single)
    
    let selections = Set(["s2"])
    let selectionChangedExpectatiom = expectation(description: "selection")
    
    viewModel.onSelectionsChanged.subscribe(with: self) { dispatchedSelections in
      XCTAssertEqual(dispatchedSelections, selections)
      selectionChangedExpectatiom.fulfill()
    }
    
    viewModel.selections = selections
    
    waitForExpectations(timeout: 2, handler: .none)
  }
  
  func testOnSelectionsComputedSingle() {
    
    let viewModel = VM(items: ["s1", "s2", "s3"], selectionMode: .single)
    viewModel.selections = ["s2"]
    let deselectionExpectation = expectation(description: "deselection")
    
    viewModel.onSelectionsComputed.subscribe(with: self) { dispatchedSelections in
      XCTAssert(dispatchedSelections.isEmpty)
      deselectionExpectation.fulfill()
    }
    
    viewModel.computeSelections(selectingItemForKey: "s2")
    
    waitForExpectations(timeout: 2, handler: .none)
    
    viewModel.onSelectionsComputed.cancelAllSubscriptions()
    
    let selectionExpectation  = expectation(description: "selection expectation")
    
    viewModel.onSelectionsComputed.subscribe(with: self) { dispatchedSelections in
      XCTAssertEqual(dispatchedSelections, ["s1"])
      selectionExpectation.fulfill()
    }
    
    viewModel.computeSelections(selectingItemForKey: "s1")

    waitForExpectations(timeout: 2, handler: .none)
    
    viewModel.onSelectionsComputed.cancelAllSubscriptions()

    let replacementExpectation  = expectation(description: "replacement expectation")
    
    viewModel.onSelectionsComputed.subscribe(with: self) { dispatchedSelections in
      XCTAssertEqual(dispatchedSelections, ["s3"])
      replacementExpectation.fulfill()
    }

    viewModel.computeSelections(selectingItemForKey: "s3")

    waitForExpectations(timeout: 2, handler: .none)
    
  }
  
  func testOnSelectionsComputedMultiple() {
    
    let viewModel = VM(items: ["s1", "s2", "s3"], selectionMode: .multiple)
    viewModel.selections = ["s2"]
    let deselectionExpectation = expectation(description: "deselection expectation")
    
    viewModel.onSelectionsComputed.subscribe(with: self) { dispatchedSelections in
      XCTAssert(dispatchedSelections.isEmpty)
      deselectionExpectation.fulfill()
    }
    
    viewModel.computeSelections(selectingItemForKey: "s2")
    
    waitForExpectations(timeout: 2, handler: .none)
    
    viewModel.onSelectionsComputed.cancelAllSubscriptions()
    
    let selectionExpectation = expectation(description: "selection expectation")
    
    viewModel.onSelectionsComputed.subscribe(with: self) { dispatchedSelections in
      XCTAssertEqual(dispatchedSelections, ["s1", "s2"])
      selectionExpectation.fulfill()
    }
    
    viewModel.computeSelections(selectingItemForKey: "s1")
    
    waitForExpectations(timeout: 2, handler: .none)
    
    viewModel.onSelectionsComputed.cancelAllSubscriptions()
    
    let additionExpectation = expectation(description: "addition expectation")
    
    viewModel.onSelectionsComputed.subscribe(with: self) { dispatchedSelections in
      XCTAssertEqual(dispatchedSelections, ["s2", "s3"])
      additionExpectation.fulfill()
    }
    
    viewModel.computeSelections(selectingItemForKey: "s3")
    
    waitForExpectations(timeout: 2, handler: .none)
    
  }
  
}
