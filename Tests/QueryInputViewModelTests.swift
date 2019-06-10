//
//  QueryInputViewModelTests.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 28/05/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation
import XCTest
@testable import InstantSearchCore

class TestSearcher: Searcher {
  
  var query: String? {
    didSet {
      guard oldValue != query else { return }
      onQueryChanged.fire(query)
    }
  }
  
  var didLaunchSearch: (() -> Void)?
  
  var isLoading: Observer<Bool> = Observer()
  
  var onQueryChanged: Observer<String?> = Observer()
  
  func search() {
    didLaunchSearch?()
  }
  
  func cancel() {
  }
  
}

class TestQueryInputController: QueryInputController {
  
  var query: String? {
    didSet {
      guard oldValue != query else { return }
      onQueryChanged(query)
    }
  }
  
  var onQueryChanged: (String?) -> Void = { _ in }
  
  var onQuerySubmitted: (String?) -> Void = { _ in }
  
  func setQuery(_ query: String?) {
    self.query = query
  }
  
  func submitQuery() {
    onQuerySubmitted(query)
  }
  
  
}

class QueryInputViewModelTests: XCTestCase {
  
  func testOnQueryChangedEvent() {
    
    let viewModel = QueryInputViewModel()
    
    let onQueryChangedExpectation = expectation(description: "on query changed")
    
    let changedQuery = "q1"
    
    viewModel.onQueryChanged.subscribe(with: self) { query in
      XCTAssertEqual(query, changedQuery)
      onQueryChangedExpectation.fulfill()
    }
    
    viewModel.query = changedQuery
    
    waitForExpectations(timeout: 2, handler: nil)
    
  }
  
  func testOnQuerySubmittedEvent() {
    
    let viewModel = QueryInputViewModel()
    let onQuerySubmittedExpectation = expectation(description: "on query submitted")
    let submittedQuery = "q2"

    viewModel.onQuerySubmitted.subscribe(with: self) { query in
      XCTAssertEqual(submittedQuery, query)
      onQuerySubmittedExpectation.fulfill()
    }
    
    viewModel.query = submittedQuery
    viewModel.submitQuery()
    
    waitForExpectations(timeout: 2, handler: nil)
    
  }
  
  func testSearcherQuerySet() {
    let searcher = TestSearcher()
    let viewModel = QueryInputViewModel()
    let query = "q1"
    searcher.query = query
    viewModel.connectSearcher(searcher, searchAsYouType: false)
    XCTAssertEqual(viewModel.query, query)
  }
  
  func testSearchAsYouTypeSearcherConnect() {
    let searcher = TestSearcher()
    let viewModel = QueryInputViewModel()
    let query = "q1"
    
    let launchSearchExpectation = expectation(description: "launched search")
    
    let querySubmittedExpectation = expectation(description: "submitted expectation")
    querySubmittedExpectation.isInverted = true
    
    viewModel.onQuerySubmitted.subscribe(with: self) { _ in
      querySubmittedExpectation.fulfill()
    }
  
    searcher.didLaunchSearch = {
      XCTAssertEqual(searcher.query, query)
      launchSearchExpectation.fulfill()
    }
    
    viewModel.connectSearcher(searcher, searchAsYouType: true)
    
    viewModel.query = query
    
    waitForExpectations(timeout: 2, handler: nil)
  }
  
  func testSubmitToSearcherSearcherConnect() {
    let searcher = TestSearcher()
    let viewModel = QueryInputViewModel()
    let query = "q1"
    
    let launchSearchExpectation = expectation(description: "launched search")

    searcher.didLaunchSearch = {
      XCTAssertEqual(searcher.query, query)
      launchSearchExpectation.fulfill()
    }
    
    viewModel.connectSearcher(searcher, searchAsYouType: false)
    
    viewModel.query = query
    viewModel.submitQuery()
    
    waitForExpectations(timeout: 2, handler: nil)

  }
  
  func testConnectController() {
    
    let controller = TestQueryInputController()
    let viewModel = QueryInputViewModel()
    let presetQuery = "q1"
    viewModel.query = presetQuery
    
    viewModel.connectController(controller)
    
    XCTAssertEqual(controller.query, presetQuery)
    
    controller.query = "q2"
    
    XCTAssertEqual(viewModel.query, "q2")
    
    controller.query = "q3"
  
    let querySubmittedExpectation = expectation(description: "query submitted")
    
    viewModel.onQuerySubmitted.subscribe(with: self) { query in
      XCTAssertEqual(query, "q3")
      querySubmittedExpectation.fulfill()
    }
    
    controller.submitQuery()
    
    waitForExpectations(timeout: 2, handler: nil)
    
  }
  
}
