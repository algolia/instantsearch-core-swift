//
//  HitsViewModelTests.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 14/03/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation
@testable import InstantSearchCore
import XCTest

class HitsViewModelTests: XCTestCase {
  
  func testConstructionWithExplicitSettings() {
    
    let vm = HitsViewModel<String>(infiniteScrolling: .off, showItemsOnEmptyQuery: false)
    
    if case .off = vm.settings.infiniteScrolling {
    } else { XCTFail() }
    XCTAssertFalse(vm.settings.showItemsOnEmptyQuery)
    
    let vm1 = HitsViewModel<String>(infiniteScrolling: .on(withOffset: 1000), showItemsOnEmptyQuery: true)

    
    if case .on(let offset) = vm1.settings.infiniteScrolling {
      XCTAssertEqual(offset, 1000)
    } else { XCTFail() }
    XCTAssertTrue(vm1.settings.showItemsOnEmptyQuery)
    
  }
  
  func testUpdateAndContent() {
    
    let vm = HitsViewModel<String>()
    
    let queryText = "test query"
    let results = SearchResults(hits: ["h1", "h2", "h3"], query: queryText, params: "test parameters", queryID: "test query id", page: 0, pagesCount: 1, hitsPerPage: 3)
    let query = Query()
    query.query = queryText
    query.filters = "test filters"
    query.page = 0
    
    let metadata = QueryMetadata(query: query)
    
    XCTAssertFalse(vm.hasMoreResults)
    XCTAssertEqual(vm.numberOfHits(), 0)
    XCTAssertEqual(vm.hit(atIndex: 0), .none)
    
    vm.update(results, with: metadata)
    
    XCTAssertFalse(vm.hasMoreResults)
    XCTAssertEqual(vm.numberOfHits(), 3)
    XCTAssertEqual(vm.hit(atIndex: 0), "h1")
    XCTAssertEqual(vm.hit(atIndex: 1), "h2")
    XCTAssertEqual(vm.hit(atIndex: 2), "h3")
    
  }
  
  func testLoadMoreTriggering() {
    
    let paginationController = Paginator<String>()
    let testDelegate = TestPaginationControllerDelegate()
    paginationController.delegate = testDelegate
    let exp = expectation(description: "Next page request")
    testDelegate.requestedLoadPage = { pageNumber in
      XCTAssertEqual(pageNumber, 1)
      exp.fulfill()
    }
    
    let hits = (0..<20).map(String.init)
    let queryText = "q1"
    let results = SearchResults(hits: hits, query: queryText, params: "test parameters", queryID: "test query id", page: 0, pagesCount: 10, hitsPerPage: 20)
    
    let query = Query()
    query.query = queryText
    query.filters = ""
    query.page = 0
    
    let metadata = QueryMetadata(query: query)
    let infiniteScrollingOffset: UInt = 5
    let vm = HitsViewModel(settings: .init(infiniteScrolling: .on(withOffset: infiniteScrollingOffset)), paginationController: paginationController)
    
    vm.update(results, with: metadata)
    
    _ = vm.hit(atIndex: hits.count - Int(infiniteScrollingOffset))
    
    waitForExpectations(timeout: 3, handler: .none)
    
  }
  
  func testLoadMoreTriggeringIfDesactivated() {
    
    let paginationController = Paginator<String>()
    let testDelegate = TestPaginationControllerDelegate()
    paginationController.delegate = testDelegate
    let exp = expectation(description: "Next page request")
    exp.isInverted = true
    testDelegate.requestedLoadPage = { pageNumber in
      XCTAssertEqual(pageNumber, 1)
      exp.fulfill()
    }
    
    let hits = (0..<20).map(String.init)
    let queryText = "q1"
    let results = SearchResults(hits: hits, query: queryText, params: "test parameters", queryID: "test query id", page: 0, pagesCount: 10, hitsPerPage: 20)
    
    let query = Query()
    query.query = queryText
    query.filters = ""
    query.page = 0
    
    let metadata = QueryMetadata(query: query)
    
    let vm = HitsViewModel(settings: .init(infiniteScrolling: .off), paginationController: paginationController)
    
    vm.update(results, with: metadata)
    
    _ = vm.hit(atIndex: hits.count - 1)
    
    waitForExpectations(timeout: 3, handler: .none)

  }
  
  func testLoadMoreManualTriggeringIfDesactivated() {
    
    let paginationController = Paginator<String>()
    let testDelegate = TestPaginationControllerDelegate()
    paginationController.delegate = testDelegate
    let exp = expectation(description: "Next page request")

    testDelegate.requestedLoadPage = { pageNumber in
      XCTAssertEqual(pageNumber, 1)
      exp.fulfill()
    }
    
    let hits = (0..<20).map(String.init)
    let queryText = "q1"
    let results = SearchResults(hits: hits, query: queryText, params: "test parameters", queryID: "test query id", page: 0, pagesCount: 10, hitsPerPage: 20)
    
    let query = Query()
    query.query = queryText
    query.filters = ""
    query.page = 0
    
    let metadata = QueryMetadata(query: query)
    
    let vm = HitsViewModel(settings: .init(infiniteScrolling: .off), paginationController: paginationController)
    
    vm.update(results, with: metadata)
    
    vm.loadMoreResults()
    
    waitForExpectations(timeout: 3, handler: .none)
    
  }
  
  func testHitsAppearanceOnEmptyQueryIfDesactivated() {
    
    let paginationController = Paginator<String>()
    let testDelegate = TestPaginationControllerDelegate()
    paginationController.delegate = testDelegate
    
    let hits = (0..<20).map(String.init)
    let queryText = ""
    let results = SearchResults(hits: hits, query: queryText, params: "test parameters", queryID: "test query id", page: 0, pagesCount: 10, hitsPerPage: 20)
    
    let query = Query()
    query.query = queryText
    query.filters = ""
    query.page = 0
    
    let metadata = QueryMetadata(query: query)
    
    let vm = HitsViewModel(settings: .init(showItemsOnEmptyQuery: false), paginationController: paginationController)
    
    vm.update(results, with: metadata)
    
    XCTAssertEqual(vm.numberOfHits(), 0)
    
  }
  
  func testHitsAppearanceOnEmptyQueryIfActivated() {
    
    let paginationController = Paginator<String>()
    let testDelegate = TestPaginationControllerDelegate()
    paginationController.delegate = testDelegate
    
    let hits = (0..<20).map(String.init)
    let queryText = ""
    let results = SearchResults(hits: hits, query: queryText, params: "test parameters", queryID: "test query id", page: 0, pagesCount: 10, hitsPerPage: 20)
    
    let query = Query()
    query.query = queryText
    query.filters = ""
    query.page = 0
    
    let metadata = QueryMetadata(query: query)
    
    let vm = HitsViewModel(settings: .init(showItemsOnEmptyQuery: true), paginationController: paginationController)
    
    vm.update(results, with: metadata)
    
    XCTAssertEqual(vm.numberOfHits(), hits.count)
    
  }

  
}

