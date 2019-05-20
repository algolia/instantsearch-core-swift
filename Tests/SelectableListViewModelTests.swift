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
  
  func testOnItemsChanged() {
    let viewModel = VM(items: [], selectionMode: .single)
    
    let items = ["s1", "s2", "s3"]
    let exp = expectation(description: "on items changed observer call")
    
    let cbTester = CallbackTester<[String]> { dispatchedItems in
      XCTAssertEqual(dispatchedItems, items)
      exp.fulfill()
    }
    
    viewModel.onItemsChanged.subscribe(with: cbTester, callback: cbTester.callback)
    
    viewModel.items = items
    
    waitForExpectations(timeout: 2, handler: .none)
  }
  
  func testOnSelectionsChanged() {
    let viewModel = VM(items: ["s1", "s2", "s3"], selectionMode: .single)
    
    let selections = Set(["s2"])
    let exp = expectation(description: "on selections changed observer call")
    
    let cbTester = CallbackTester<Set<String>> { dispatchedSelections in
      XCTAssertEqual(dispatchedSelections, selections)
      exp.fulfill()
    }
    
    viewModel.onSelectionsChanged.subscribe(with: cbTester, callback: cbTester.callback)
    
    viewModel.selections = selections
    
    waitForExpectations(timeout: 2, handler: .none)
  }
  
  func testOnSelectionsComputedSingle() {
    
    let viewModel = VM(items: ["s1", "s2", "s3"], selectionMode: .single)
    viewModel.selections = ["s2"]
    let deselectionExpectation = expectation(description: "deselection expectation")
    
    let deselectionTester = CallbackTester<Set<String>> { dispatchedSelections in
      XCTAssert(dispatchedSelections.isEmpty)
      deselectionExpectation.fulfill()
    }
    
    viewModel.onSelectionsComputed.subscribe(with: deselectionTester, callback: deselectionTester.callback)
    
    viewModel.computeSelections(selectingItemForKey: "s2")
    
    waitForExpectations(timeout: 2, handler: .none)
    
    viewModel.onSelectionsComputed.cancelAllSubscriptions()
    
    let selectionExpectation  = expectation(description: "selection expectation")

    let selectionTester = CallbackTester<Set<String>> { dispatchedSelections in
      XCTAssertEqual(dispatchedSelections, ["s1"])
      selectionExpectation.fulfill()
    }
    
    viewModel.onSelectionsComputed.subscribe(with: selectionTester, callback: selectionTester.callback)
    
    viewModel.computeSelections(selectingItemForKey: "s1")

    waitForExpectations(timeout: 2, handler: .none)
    
    viewModel.onSelectionsComputed.cancelAllSubscriptions()

    let replacementExpectation  = expectation(description: "replacement expectation")

    let replacementTester = CallbackTester<Set<String>> { dispatchedSelections in
      XCTAssertEqual(dispatchedSelections, ["s3"])
      replacementExpectation.fulfill()
    }
    
    viewModel.onSelectionsComputed.subscribe(with: replacementTester, callback: replacementTester.callback)

    viewModel.computeSelections(selectingItemForKey: "s3")

    waitForExpectations(timeout: 2, handler: .none)
    
  }
  
  func testOnSelectionsComputedMultiple() {
    
    let viewModel = VM(items: ["s1", "s2", "s3"], selectionMode: .multiple)
    viewModel.selections = ["s2"]
    let deselectionExpectation = expectation(description: "deselection expectation")
    
    let deselectionTester = CallbackTester<Set<String>> { dispatchedSelections in
      XCTAssert(dispatchedSelections.isEmpty)
      deselectionExpectation.fulfill()
    }
    
    viewModel.onSelectionsComputed.subscribe(with: deselectionTester, callback: deselectionTester.callback)
    
    viewModel.computeSelections(selectingItemForKey: "s2")
    
    waitForExpectations(timeout: 2, handler: .none)
    
    viewModel.onSelectionsComputed.cancelAllSubscriptions()
    
    let selectionExpectation  = expectation(description: "selection expectation")
    
    let selectionTester = CallbackTester<Set<String>> { dispatchedSelections in
      XCTAssertEqual(dispatchedSelections, ["s1", "s2"])
      selectionExpectation.fulfill()
    }
    
    viewModel.onSelectionsComputed.subscribe(with: selectionTester, callback: selectionTester.callback)
    
    viewModel.computeSelections(selectingItemForKey: "s1")
    
    waitForExpectations(timeout: 2, handler: .none)
    
    viewModel.onSelectionsComputed.cancelAllSubscriptions()
    
    let additionExpectation  = expectation(description: "addition expectation")
    
    let additionTester = CallbackTester<Set<String>> { dispatchedSelections in
      XCTAssertEqual(dispatchedSelections, ["s2", "s3"])
      additionExpectation.fulfill()
    }
    
    viewModel.onSelectionsComputed.subscribe(with: additionTester, callback: additionTester.callback)
    
    viewModel.computeSelections(selectingItemForKey: "s3")
    
    waitForExpectations(timeout: 2, handler: .none)
    
  }
  
}
