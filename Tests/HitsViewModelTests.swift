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

extension Index {
  
  static var test: Index = Client(appID: "", apiKey: "").index(withName: "")
  
}

class TestInfiniteScrollingController: InfiniteScrollable {
  
  var lastPageIndex: Int?
  
  var pageLoader: PageLoadable?
  
  var pendingPages = Set<Int>()
  
  var didCalculatePages: ((Int, Int) -> Void)?
  
  func calculatePagesAndLoad<T>(currentRow: Int, offset: Int, pageMap: PageMap<T>) {
    didCalculatePages?(currentRow, offset)
  }
  
  func notifyPending(pageIndex: Int) {
    pendingPages.remove(pageIndex)
  }
  
  func notifyPendingAll() {
    pendingPages.removeAll()
  }
  
}

class HitsViewModelTests: XCTestCase {
  
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
    
    XCTAssertNoThrow(try vm.update(results))
    
    XCTAssertEqual(vm.numberOfHits(), 3)
    XCTAssertEqual(vm.hit(atIndex: 0), "h1")
    XCTAssertEqual(vm.hit(atIndex: 1), "h2")
    XCTAssertEqual(vm.hit(atIndex: 2), "h3")
    
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
    
    XCTAssertNoThrow(try vm.update(results))
    
    XCTAssertEqual(vm.numberOfHits(), 0)
    
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
    
    XCTAssertNoThrow(try vm.update(results))
    
    XCTAssertEqual(vm.numberOfHits(), hits.count)
    
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
    
    XCTAssertNoThrow(try vm.update(results))
    
    let rawHit = vm.rawHitAtIndex(5)?.first
    XCTAssertEqual(rawHit?.key, "5")
    XCTAssertEqual(rawHit?.value as? String, "5")
    
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
    
    vm.onRequestChanged.subscribe(with: self) { _ in
      onRequestChangedExpectation.fulfill()
    }
    
    vm.notifyQueryChanged()
    
    XCTAssertNil(pc.pageMap)
    XCTAssertTrue(isc.pendingPages.isEmpty)
    
    waitForExpectations(timeout: 2, handler: nil)
    
  }
  
  func testConnectFilterState() {
    
    let pc = Paginator<JSON>()
    
    let page1 = ["i1", "i2", "i3"].map { JSON.string($0) }
    pc.pageMap = PageMap([1:  page1])
    
    let isc = TestInfiniteScrollingController()
    isc.pendingPages = [0, 2]
    
    let vm = HitsInteractor(
      settings: .init(infiniteScrolling: .on(withOffset: 10), showItemsOnEmptyQuery: true),
      paginationController: pc,
      infiniteScrollingController: isc)
    
    let fs = FilterState()
    
    vm.connectFilterState(fs)
    
    let exp = expectation(description: "change query when filter state changed")
    
    vm.onRequestChanged.subscribe(with: self) { _ in
      exp.fulfill()
    }
    
    fs.add(Filter.Tag("t"), toGroupWithID: .and(name: ""))
    fs.notifyChange()
    
    waitForExpectations(timeout: 2, handler: nil)
    
  }
  
  func testConnectSearcher() {
    
    let pc = Paginator<JSON>()
    
    let page1 = ["i1", "i2", "i3"].map { JSON.string($0) }
    pc.pageMap = PageMap([1:  page1])
    
    let isc = TestInfiniteScrollingController()
    isc.pendingPages = [0, 2]
    
    let vm = HitsInteractor(
      settings: .init(infiniteScrolling: .on(withOffset: 10), showItemsOnEmptyQuery: true),
      paginationController: pc,
      infiniteScrollingController: isc)
    
    let searcher = SingleIndexSearcher(index: .test)
    
    vm.connectSearcher(searcher)
    
    XCTAssertTrue(searcher === isc.pageLoader)
    
    let queryChangedExpectation = expectation(description: "query changed")
    
    vm.onRequestChanged.subscribe(with: self) { _ in
      queryChangedExpectation.fulfill()
    }
    
    searcher.query = "query"
    searcher.indexQueryState.query.page = 0
    isc.pendingPages = [0]
    
    let resultsUpdatedExpectation = expectation(description: "results updated")
    
    vm.onResultsUpdated.subscribe(with: self) { _ in
      resultsUpdatedExpectation.fulfill()
      XCTAssertTrue(isc.pendingPages.isEmpty)
    }
    
    let searchResults = SearchResults(hits: [.string("r")], stats: .init())
    searcher.onResults.fire(searchResults)
    
    isc.pendingPages = [0]
    searcher.onError.fire((searcher.indexQueryState.query, NSError()))
    XCTAssertTrue(isc.pendingPages.isEmpty)
    
    waitForExpectations(timeout: 2, handler: nil)
    
  }
  
}

