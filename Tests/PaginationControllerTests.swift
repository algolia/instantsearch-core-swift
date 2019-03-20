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

struct TestMetaData: PageMetadata {
  
  let id: String
  let page: UInt
  
  func isAnotherPage(for data: TestMetaData) -> Bool {
    return data.id == id
  }
  
}


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
    
    let paginationController = Paginator<String, TestMetaData>()
    
    XCTAssertNil(paginationController.pageMap)
    
    // Adding a first page of dataset
    
    let page0 = TestPageMapConvertible(page: 0, pagesCount: 10, totalItemsCount: 100, pageItems: ["i1", "i2", "i3"])
    let data0 = TestMetaData(id: "test", page: 0)
    
    paginationController.process(page0, with: data0)
    
    guard let pageMap0 = paginationController.pageMap else {
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
    let data1 = TestMetaData(id: "test", page: 1)
    
    paginationController.process(page1, with: data1)
    
    guard let pageMap1 = paginationController.pageMap else {
      XCTFail("PageMap cannot be nil after page processing")
      return
    }
    
    XCTAssertEqual(pageMap1.pageToItems, [0: ["i1", "i2", "i3"], 1: ["i4", "i5", "i6"]])
    XCTAssertTrue(pageMap1.hasMorePages)
    XCTAssertEqual(pageMap1.latestPage, UInt(page1.page))
    XCTAssertEqual(pageMap1.totalPageCount, page1.pagesCount)
    XCTAssertEqual(pageMap1.totalItemsCount, page1.totalItemsCount)
    
    // Adding a page of a new dataset
    
    let page2 = TestPageMapConvertible(page: 1, pagesCount: 20, totalItemsCount: 200, pageItems: ["i7", "i8", "i9"])
    let data2 = TestMetaData(id: "another-test", page: 1)
    
    paginationController.process(page2, with: data2)
    
    guard let pageMap2 = paginationController.pageMap else {
      XCTFail("PageMap cannot be nil after page processing")
      return
    }
    
    XCTAssertEqual(pageMap2.pageToItems, [1: ["i7", "i8", "i9"]])
    XCTAssertTrue(pageMap2.hasMorePages)
    XCTAssertEqual(pageMap2.latestPage, UInt(page2.page))
    XCTAssertEqual(pageMap2.totalPageCount, page2.pagesCount)
    XCTAssertEqual(pageMap2.totalItemsCount, page2.totalItemsCount)
    
  }
  
  func testLoadingNextPageWithoutContext() {
    
    let paginationController = Paginator<String, TestMetaData>()
    let delegate = TestPaginationControllerDelegate()
    paginationController.delegate = delegate
    
    let exp = expectation(description: "This expectation mustn't be fullfilled, as pagination controller has no context for loading next page")
    exp.isInverted = true
    
    delegate.requestedLoadPage = { _ in
      exp.fulfill()
    }
    paginationController.loadNextPageIfNeeded()
    
    waitForExpectations(timeout: 2, handler: .none)
    
  }
  
  func testLoadingNextPageWithContext() {
    
    let paginationController = Paginator<String, TestMetaData>()
    let delegate = TestPaginationControllerDelegate()
    paginationController.delegate = delegate
    
    let exp = expectation(description: "")
    
    let page = TestPageMapConvertible(page: 0, pagesCount: 10, totalItemsCount: 100, pageItems: ["i1", "i2", "i3"])
    let data = TestMetaData(id: "q1", page: 0)
    
    delegate.requestedLoadPage = { pageNumber in
      XCTAssertEqual(pageNumber, UInt(page.page + 1))
      exp.fulfill()
    }
    
    paginationController.process(page, with: data)
    paginationController.loadNextPageIfNeeded()
    
    waitForExpectations(timeout: 2, handler: .none)
    
  }
  
  func testLoadingNextPageWithCompleteDataset() {
    
    let paginationController = Paginator<String, TestMetaData>()
    let delegate = TestPaginationControllerDelegate()
    paginationController.delegate = delegate
    
    let exp = expectation(description: "")
    exp.isInverted = true
    
    let page = TestPageMapConvertible(page: 0, pagesCount: 1, totalItemsCount: 100, pageItems: ["i1", "i2", "i3"])
    let data = TestMetaData(id: "q1", page: 0)
    
    delegate.requestedLoadPage = { pageNumber in
      XCTAssertEqual(pageNumber, UInt(page.page + 1))
      exp.fulfill()
    }
    
    paginationController.process(page, with: data)
    paginationController.loadNextPageIfNeeded()
    
    waitForExpectations(timeout: 2, handler: .none)
    
  }
  
  func testLoadingNextPageDelegateCalledOnce() {
    
    let paginationController = Paginator<String, TestMetaData>()
    
    let delegate = TestPaginationControllerDelegate()
    paginationController.delegate = delegate
    
    let exp = expectation(description: "")
    
    let page = TestPageMapConvertible(page: 0, pagesCount: 10, totalItemsCount: 100, pageItems: ["i1", "i2", "i3"])
    let data = TestMetaData(id: "q1", page: 0)
    
    delegate.requestedLoadPage = { pageNumber in
      XCTAssertEqual(pageNumber, UInt(page.page + 1))
      exp.fulfill()
    }
    
    paginationController.process(page, with: data)
    paginationController.loadNextPageIfNeeded()
    paginationController.loadNextPageIfNeeded()
    
    waitForExpectations(timeout: 2, handler: .none)
    
  }
  
  
}
