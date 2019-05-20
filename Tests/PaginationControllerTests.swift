//
//  PaginationControllerTests.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 14/03/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation
@testable import InstantSearchCore
import XCTest

struct TestPageMapConvertible<Item>: PageMapConvertible {
  
  typealias PageItem = Item
  
  var page: Int
  
  var pagesCount: Int
  
  var totalItemsCount: Int
  
  var pageItems: [Item]
  
}

class TestPaginationControllerDelegate: PaginatorDelegate {
  
  var requestedLoadPage: ((UInt) -> Void)?
  
  func didRequestLoadPage(withNumber number: UInt) {
    requestedLoadPage?(number)
  }
  
}

class PaginationControllerTests: XCTestCase {
  
  func testProcessing() {
    
    let paginator = Paginator<String>()
    
    XCTAssertNil(paginator.pageMap)
    
    // Adding a first page of dataset
    
    let page0 = TestPageMapConvertible(page: 0, pagesCount: 10, totalItemsCount: 100, pageItems: ["i1", "i2", "i3"])
    
    paginator.process(page0)
    
    guard let pageMap0 = paginator.pageMap else {
      XCTFail("PageMap cannot be nil after page processing")
      return
    }
    
    XCTAssertEqual(pageMap0.pageToItems, [0: ["i1", "i2", "i3"]])
    XCTAssertTrue(pageMap0.hasMorePages)
    XCTAssertEqual(pageMap0.latestPage, UInt(page0.page))
    XCTAssertEqual(pageMap0.totalPageCount, page0.pagesCount)
    XCTAssertEqual(pageMap0.totalItemsCount, page0.totalItemsCount)
    
    // Adding another page for same dataset
    
    let page1 = TestPageMapConvertible(page: 1, pagesCount: 10, totalItemsCount: 100, pageItems: ["i4", "i5", "i6"])
    
    paginator.process(page1)
    
    guard let pageMap1 = paginator.pageMap else {
      XCTFail("PageMap cannot be nil after page processing")
      return
    }
    
    XCTAssertEqual(pageMap1.pageToItems, [0: ["i1", "i2", "i3"], 1: ["i4", "i5", "i6"]])
    XCTAssertTrue(pageMap1.hasMorePages)
    XCTAssertEqual(pageMap1.latestPage, UInt(page1.page))
    XCTAssertEqual(pageMap1.totalPageCount, page1.pagesCount)
    XCTAssertEqual(pageMap1.totalItemsCount, page1.totalItemsCount)
    
  }
  
  func testLoadingNextPageIfEmpty() {
    
    let paginationController = Paginator<String>()
    let delegate = TestPaginationControllerDelegate()
    paginationController.delegate = delegate
    
    let exp = expectation(description: "Loading first page")
    
    delegate.requestedLoadPage = { page in
      XCTAssertEqual(page, 0)
      exp.fulfill()
    }
    
    paginationController.loadNextPageIfNeeded()
    
    waitForExpectations(timeout: 2, handler: .none)
    
  }
  
  func testLoadingNextPageIfNonEmpty() {
    
    let paginationController = Paginator<String>()
    let delegate = TestPaginationControllerDelegate()
    paginationController.delegate = delegate
    
    let exp = expectation(description: "")
    
    let page = TestPageMapConvertible(page: 0, pagesCount: 10, totalItemsCount: 100, pageItems: ["i1", "i2", "i3"])
    
    delegate.requestedLoadPage = { pageNumber in
      XCTAssertEqual(pageNumber, UInt(page.page + 1))
      exp.fulfill()
    }
    
    paginationController.process(page)
    paginationController.loadNextPageIfNeeded()
    
    waitForExpectations(timeout: 2, handler: .none)
    
  }
  
  func testLoadingNextPageWithCompleteDataset() {
    
    let paginationController = Paginator<String>()
    let delegate = TestPaginationControllerDelegate()
    paginationController.delegate = delegate
    
    let exp = expectation(description: "")
    exp.isInverted = true
    
    let page = TestPageMapConvertible(page: 0, pagesCount: 1, totalItemsCount: 100, pageItems: ["i1", "i2", "i3"])
    
    delegate.requestedLoadPage = { pageNumber in
      XCTAssertEqual(pageNumber, UInt(page.page + 1))
      exp.fulfill()
    }
    
    paginationController.process(page)
    paginationController.loadNextPageIfNeeded()
    
    waitForExpectations(timeout: 2, handler: .none)
    
  }
  
  func testLoadingNextPageDelegateCalledOnce() {
    
    let paginationController = Paginator<String>()
    
    let delegate = TestPaginationControllerDelegate()
    paginationController.delegate = delegate
    
    let exp = expectation(description: "")
    
    let page = TestPageMapConvertible(page: 0, pagesCount: 10, totalItemsCount: 100, pageItems: ["i1", "i2", "i3"])
    
    delegate.requestedLoadPage = { pageNumber in
      XCTAssertEqual(pageNumber, UInt(page.page + 1))
      exp.fulfill()
    }
    
    paginationController.process(page)
    paginationController.loadNextPageIfNeeded()
    paginationController.loadNextPageIfNeeded()
    
    waitForExpectations(timeout: 2, handler: .none)
    
  }
  
  
}
