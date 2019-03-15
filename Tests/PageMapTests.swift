//
//  PageMapTests.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 14/03/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation
@testable import InstantSearchCore
import XCTest

class PageMapTests: XCTestCase {
  
  func testConstructionWithSequence() {
    
    let pageMap = PageMap<String>(["i1", "i2", "i3"])
    
    XCTAssertEqual(pageMap.pageToItems, [0: ["i1", "i2", "i3"]])
    XCTAssertEqual(pageMap.latestPage, 0)
    XCTAssertEqual(pageMap.totalPageCount, 1)
    XCTAssertEqual(pageMap.totalItemsCount, 3)
    
  }
  
  func testConstructionWithDictionary() {
    
    XCTAssertNil(PageMap<String>([:]))
    
    let dictionary = [0: ["i1", "i2"], 1: ["i3", "i4", "i5"]]
    guard let pageMap = PageMap(dictionary) else {
      XCTFail("PageMap must be correctly constructed")
      return
    }
    
    XCTAssertEqual(pageMap.pageToItems, dictionary)
    XCTAssertEqual(pageMap.latestPage, 1)
    XCTAssertEqual(pageMap.totalPageCount, 2)
    XCTAssertEqual(pageMap.totalItemsCount, 5)
    
  }
  
  func testIteration() {
    
    let dictionary = [0: ["i3", "i4", "i5"], 1: ["i1", "i2"]]
    
    let itemsSequence = dictionary.sorted { $0.key < $1.key }.map { $0.value }.flatMap { $0 }
    
    guard let pageMap = PageMap(dictionary) else {
      XCTFail("PageMap must be correctly constructed")
      return
    }
    
    for (index, element) in pageMap.enumerated() {
      XCTAssertEqual(itemsSequence[index], element)
    }
    
  }
  
  func testInsertion() {
    
    let p0 = ["i1", "i2", "i3"]
    let p1 = ["i4", "i5", "i6"]
    let pageMap = PageMap(p0)
    
    let updatedPageMap = pageMap.inserting(p1, withNumber: 1)
    
    XCTAssertEqual(updatedPageMap.pageToItems, [0: p0, 1: p1])
    XCTAssertEqual(updatedPageMap.latestPage, 1)
    XCTAssertEqual(updatedPageMap.totalPageCount, 2)
    XCTAssertEqual(updatedPageMap.totalItemsCount, 6)
    
  }
  
  func testInsertionKeepingMissingPage() {
    
    let p0 = ["i4", "i5", "i6"]
    let p2 = ["i10", "i11", "i12"]
    
    var pageMap = PageMap(p0)
    
    XCTAssertEqual(pageMap.pageToItems, [0: p0])
    XCTAssertEqual(pageMap.latestPage, 0)
    XCTAssertEqual(pageMap.totalPageCount, 1)
    XCTAssertEqual(pageMap.totalItemsCount, 3)
    
    pageMap.insert(p2, withNumber: 2)
    
    XCTAssertEqual(pageMap.pageToItems, [0: p0, 2: p2])
    XCTAssertEqual(pageMap.latestPage, 2)
    XCTAssertEqual(pageMap.totalPageCount, 3)
    XCTAssertEqual(pageMap.totalItemsCount, 6)
    
    let itemsSequence = p0 + p2
    
    for (index, element) in pageMap.enumerated() {
      XCTAssertEqual(itemsSequence[index], element)
    }
    
  }
  
  func testHasMorePages() {
    
    let p0 = ["i4", "i5", "i6"]
    var pageMap = PageMap(p0)
    
    XCTAssertFalse(pageMap.hasMorePages)
    
    pageMap.totalPageCount = 100
    pageMap.totalItemsCount = 1000
    
    XCTAssertTrue(pageMap.hasMorePages)
    
  }
  
  func testContainsItem() {
    
    let p0 = ["i4", "i5", "i6"]
    let pageMap = PageMap(p0)
    
    XCTAssertTrue(pageMap.containsItem(atIndex: 1))
    XCTAssertFalse(pageMap.containsItem(atIndex: 4))
    XCTAssertEqual(pageMap[0], "i4")
    XCTAssertEqual(pageMap[1], "i5")
    XCTAssertEqual(pageMap[2], "i6")
    
  }
  
  func testPageMapConvertibleInit() {
    
    let testPageMapConvertible = TestPageMapConvertible(page: 5, pagesCount: 10, totalItemsCount: 500, pageItems: ["i1", "i11", "i21"])
    let pageMap = PageMap(testPageMapConvertible)
    
    XCTAssertEqual(pageMap.pageToItems, [5: ["i1", "i11", "i21"]])
    
  }
  
}
