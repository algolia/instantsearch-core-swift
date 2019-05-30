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
  
  var pageSize: Int

  var pageItems: [Item]
  
}

class TestPaginationControllerDelegate: PaginatorDelegate {
  
  var requestedLoadPage: ((Int) -> Void)?
  
  func didRequestLoadPage(withIndex pageIndex: Int) {
    requestedLoadPage?(pageIndex)
  }
  
}

class PaginationControllerTests: XCTestCase {
  
  func testProcessing() {
    
    let paginator = Paginator<String>()
    
    XCTAssertNil(paginator.pageMap)
    
    // Adding a first page of dataset
    
    let page0 = TestPageMapConvertible(page: 0, pageSize: 3, pageItems: ["i1", "i2", "i3"])
    
    paginator.process(page0)
    
    guard let pageMap0 = paginator.pageMap else {
      XCTFail("PageMap cannot be nil after page processing")
      return
    }
    
    XCTAssertEqual(pageMap0.items, [0: ["i1", "i2", "i3"]])
    XCTAssertEqual(pageMap0.latestPageIndex, page0.page)
    XCTAssertEqual(pageMap0.items.count, 1)
    XCTAssertEqual(pageMap0.totalItemsCount, 3)
    
    // Adding another page for same dataset
    
    let page1 = TestPageMapConvertible(page: 1, pageSize: 3, pageItems: ["i4", "i5", "i6"])
    
    paginator.process(page1)
    
    guard let pageMap1 = paginator.pageMap else {
      XCTFail("PageMap cannot be nil after page processing")
      return
    }
    
    XCTAssertEqual(pageMap1.items, [0: ["i1", "i2", "i3"], 1: ["i4", "i5", "i6"]])
    XCTAssertEqual(pageMap1.latestPageIndex, page1.page)
    XCTAssertEqual(pageMap1.loadedPagesCount, 2)
    XCTAssertEqual(pageMap1.totalItemsCount, 6)
    
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
    
    let page = TestPageMapConvertible(page: 0, pageSize: 3, pageItems: ["i1", "i2", "i3"])
    
    delegate.requestedLoadPage = { pageNumber in
      XCTAssertEqual(pageNumber, page.page + 1)
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
    
    let page = TestPageMapConvertible(page: 0, pageSize: 3, pageItems: ["i1", "i2", "i3"])
    
    delegate.requestedLoadPage = { pageNumber in
      XCTAssertEqual(pageNumber, page.page + 1)
      exp.fulfill()
    }
    
    paginationController.process(page)
    paginationController.loadNextPageIfNeeded()
    paginationController.loadNextPageIfNeeded()
    
    waitForExpectations(timeout: 2, handler: .none)
    
  }
  
}
