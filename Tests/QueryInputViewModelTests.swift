//
//  QueryInputInteractorTests.swift
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
      onQueryChanged?(query)
    }
  }
  
  var onQueryChanged: ((String?) -> Void)?
  var onQuerySubmitted: ((String?) -> Void)?
  
  func setQuery(_ query: String?) {
    self.query = query
  }
  
  func submitQuery() {
    onQuerySubmitted?(query)
  }
  
  
}

class QueryInputInteractorTests: XCTestCase {
  
  func testOnQueryChangedEvent() {
    
    let interactor = QueryInputInteractor()
    
    let onQueryChangedExpectation = expectation(description: "on query changed")
    
    let changedQuery = "q1"
    
    interactor.onQueryChanged.subscribe(with: self) { _, query in
      XCTAssertEqual(query, changedQuery)
      onQueryChangedExpectation.fulfill()
    }
    
    interactor.query = changedQuery
    
    waitForExpectations(timeout: 2, handler: nil)
    
  }
  
  func testOnQuerySubmittedEvent() {
    
    let interactor = QueryInputInteractor()
    let onQuerySubmittedExpectation = expectation(description: "on query submitted")
    let submittedQuery = "q2"

    interactor.onQuerySubmitted.subscribe(with: self) { _, query in
      XCTAssertEqual(submittedQuery, query)
      onQuerySubmittedExpectation.fulfill()
    }
    
    interactor.query = submittedQuery
    interactor.submitQuery()
    
    waitForExpectations(timeout: 2, handler: nil)
    
  }
  
  func testSearcherQuerySet() {
    let searcher = TestSearcher()
    let interactor = QueryInputInteractor()
    let query = "q1"
    searcher.query = query
    interactor.connectSearcher(searcher, searchTriggeringMode: .searchOnSubmit)
    XCTAssertEqual(interactor.query, query)
  }
  
  func testSearchAsYouTypeSearcherConnect() {
    let searcher = TestSearcher()
    let interactor = QueryInputInteractor()
    let query = "q1"
    
    let launchSearchExpectation = expectation(description: "launched search")
    
    let querySubmittedExpectation = expectation(description: "submitted expectation")
    querySubmittedExpectation.isInverted = true
    
    interactor.onQuerySubmitted.subscribe(with: self) { _, _ in
      querySubmittedExpectation.fulfill()
    }
  
    searcher.didLaunchSearch = {
      XCTAssertEqual(searcher.query, query)
      launchSearchExpectation.fulfill()
    }
    
    interactor.connectSearcher(searcher, searchTriggeringMode: .searchAsYouType)
    
    interactor.query = query
    
    waitForExpectations(timeout: 2, handler: nil)
  }
  
  func testSubmitToSearcherSearcherConnect() {
    let searcher = TestSearcher()
    let interactor = QueryInputInteractor()
    let query = "q1"
    
    let launchSearchExpectation = expectation(description: "launched search")

    searcher.didLaunchSearch = {
      XCTAssertEqual(searcher.query, query)
      launchSearchExpectation.fulfill()
    }
    
    interactor.connectSearcher(searcher, searchTriggeringMode: .searchOnSubmit)
    
    interactor.query = query
    interactor.submitQuery()
    
    waitForExpectations(timeout: 2, handler: nil)

  }
  
  func testConnectController() {
    
    let controller = TestQueryInputController()
    let interactor = QueryInputInteractor()
    let presetQuery = "q1"
    interactor.query = presetQuery
    
    interactor.connectController(controller)
    
    XCTAssertEqual(controller.query, presetQuery)
    
    controller.query = "q2"
    
    XCTAssertEqual(interactor.query, "q2")
    
    controller.query = "q3"
  
    let querySubmittedExpectation = expectation(description: "query submitted")
    
    interactor.onQuerySubmitted.subscribe(with: self) { _, query in
      XCTAssertEqual(query, "q3")
      querySubmittedExpectation.fulfill()
    }
    
    controller.submitQuery()
    
    waitForExpectations(timeout: 2, handler: nil)
    
  }
  
}
