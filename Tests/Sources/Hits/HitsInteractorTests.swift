//
//  HitsInteractorTests.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 14/03/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation
@testable import InstantSearchCore
import XCTest

extension Index {
  
  static var test: Index = Client(appID: "", apiKey: "").index(withName: "")
  
}

class HitsInteractorTests: XCTestCase {
  
  func testConstructionWithExplicitSettings() {
    
    let vm = HitsInteractor<String>(infiniteScrolling: .off, showItemsOnEmptyQuery: false)
    
    if case .off = vm.settings.infiniteScrolling {
    } else { XCTFail() }
    XCTAssertFalse(vm.settings.showItemsOnEmptyQuery)
    
    let vm1 = HitsInteractor<String>(infiniteScrolling: .on(withOffset: 1000), showItemsOnEmptyQuery: true)
    
    if case .on(let offset) = vm1.settings.infiniteScrolling {
      XCTAssertEqual(offset, 1000)
    } else { XCTFail() }
    XCTAssertTrue(vm1.settings.showItemsOnEmptyQuery)
    
  }
  
  func testUpdateAndContent() {
    
    let vm = HitsInteractor<String>(infiniteScrolling: .off, showItemsOnEmptyQuery: true)
    
    let queryText = "test query"
    let hits = ["h1", "h2", "h3"].map { JSON.string($0) }
    let results = SearchResults(hits: hits, stats: .init())
    let query = Query()
    query.query = queryText
    query.filters = "test filters"
    query.page = 0
        
    XCTAssertEqual(vm.numberOfHits(), 0)
    XCTAssertEqual(vm.hit(atIndex: 0), .none)
    
    let exp = expectation(description: "on results updated")
    
    vm.onResultsUpdated.subscribe(with: self) { (_, _) in
      XCTAssertEqual(vm.numberOfHits(), 3)
      XCTAssertEqual(vm.hit(atIndex: 0), "h1")
      XCTAssertEqual(vm.hit(atIndex: 1), "h2")
      XCTAssertEqual(vm.hit(atIndex: 2), "h3")
      exp.fulfill()
    }
    
    vm.update(results)
        
    waitForExpectations(timeout: 3, handler: .none)
        
  }

  func testHitsAppearanceOnEmptyQueryIfDesactivated() {
    
    let paginator = Paginator<String>()
    
    let hits = (0..<20).map(String.init).map { JSON.string($0) }
    let queryText = ""
    let results = SearchResults(hits: hits, stats: .init())
    
    let query = Query()
    query.query = queryText
    query.filters = ""
    query.page = 0
    
    let vm = HitsInteractor(
      settings: .init(showItemsOnEmptyQuery: false),
      paginationController: paginator,
      infiniteScrollingController: TestInfiniteScrollingController())
    
    let exp = expectation(description: "on results updated")

    vm.onResultsUpdated.subscribe(with: self) { (_, _) in
      XCTAssertEqual(vm.numberOfHits(), 0)
      exp.fulfill()
    }
    
    vm.update(results)
    
    waitForExpectations(timeout: 3, handler: .none)
  }
  
  func testHitsAppearanceOnEmptyQueryIfActivated() {
    
    let paginationController = Paginator<String>()
    let infiniteScrollingController = TestInfiniteScrollingController()
    
    let hits = (0..<20).map(String.init).map { JSON.string($0) }
    let queryText = ""
    let results = SearchResults(hits: hits, stats: .init())
    
    let query = Query()
    query.query = queryText
    query.filters = ""
    query.page = 0
    
    let vm = HitsInteractor(
      settings: .init(showItemsOnEmptyQuery: true),
      paginationController: paginationController,
      infiniteScrollingController: infiniteScrollingController
    )
    
    let exp = expectation(description: "on results updated")

    vm.onResultsUpdated.subscribe(with: self) { (_, _) in
      XCTAssertEqual(vm.numberOfHits(), hits.count)
      exp.fulfill()
    }
    
    vm.update(results)

    waitForExpectations(timeout: 3, handler: .none)
  }
  
  func testRawHitAtIndex() {
    
    let paginationController = Paginator<JSON>()
    let infiniteScrollingController = TestInfiniteScrollingController()
    
    let hits = (0..<20).map { JSON.dictionary([String($0): JSON.string("\($0)")]) }
    let results = SearchResults(hits: hits, stats: .init())

    
    let vm = HitsInteractor(
      settings: .init(showItemsOnEmptyQuery: true),
      paginationController: paginationController,
      infiniteScrollingController: infiniteScrollingController
    )
    
    let exp = expectation(description: "on results updated")
    
    vm.onResultsUpdated.subscribe(with: self) { (_, _) in
      let rawHit = vm.rawHitAtIndex(5)?.first
      XCTAssertEqual(rawHit?.key, "5")
      XCTAssertEqual(rawHit?.value as? String, "5")
      exp.fulfill()
    }
    
    vm.update(results)
    
    waitForExpectations(timeout: 3, handler: .none)
  }
  
  func testInfiniteScrollingTriggering() {
    
    let pc = Paginator<JSON>()
    
    let page1 = ["i1", "i2", "i3"].map { JSON.string($0) }
    pc.pageMap = PageMap([1:  page1])
    
    let isc = TestInfiniteScrollingController()
    
    let loadPagesTriggered = expectation(description: "load pages triggered")
    
    let vm = HitsInteractor(
      settings: .init(infiniteScrolling: .on(withOffset: 10), showItemsOnEmptyQuery: true),
      paginationController: pc,
      infiniteScrollingController: isc)
    
    isc.didCalculatePages = { _, _ in
      loadPagesTriggered.fulfill()
    }
    
    _ = vm.hit(atIndex: 4)
    
    waitForExpectations(timeout: 2, handler: nil)
    
  }
  
  func testChangeQuery() {
    
    let pc = Paginator<JSON>()
    
    let page1 = ["i1", "i2", "i3"].map { JSON.string($0) }
    pc.pageMap = PageMap([1:  page1])
    
    let isc = TestInfiniteScrollingController()
    isc.pendingPages = [0, 2]
    
    let vm = HitsInteractor(
      settings: .init(infiniteScrolling: .on(withOffset: 10), showItemsOnEmptyQuery: true),
      paginationController: pc,
      infiniteScrollingController: isc)
    
    let onRequestChangedExpectation = expectation(description: "on request changed")
    
    vm.onRequestChanged.subscribe(with: self) { _, _ in
      
      XCTAssertTrue(pc.isInvalidated)
      XCTAssertTrue(isc.pendingPages.isEmpty)

      onRequestChangedExpectation.fulfill()
    }
    
    vm.notifyQueryChanged()
        
    waitForExpectations(timeout: 3, handler: nil)
    
  }
  
 
  
  
}

