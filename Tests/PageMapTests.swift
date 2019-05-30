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
    
    XCTAssertEqual(pageMap.items, [0: ["i1", "i2", "i3"]])
    XCTAssertEqual(pageMap.latestPageIndex, 0)
    XCTAssertEqual(pageMap.loadedPagesCount, 1)
    XCTAssertEqual(pageMap.totalItemsCount, 3)
    
  }
  
  func testConstructionWithDictionary() {
    
    XCTAssertNil(PageMap<String>([:]))
    
    let dictionary = [0: ["i1", "i2", "i3"], 1: ["i4", "i5"]]
    guard let pageMap = PageMap(dictionary) else {
      XCTFail("PageMap must be correctly constructed")
      return
    }
    
    XCTAssertEqual(pageMap.items, dictionary)
    XCTAssertEqual(pageMap.latestPageIndex, 1)
    XCTAssertEqual(pageMap.loadedPagesCount, 2)
    XCTAssertEqual(pageMap.totalItemsCount, 5)
    
  }
  
  func testIteration() {
    
    let dictionary = [0: ["i1", "i2", "i3"], 1: ["i4", "i5"]]
    
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
    
    let updatedPageMap = pageMap.inserting(p1, withIndex: 1)
    
    XCTAssertEqual(updatedPageMap.items, [0: p0, 1: p1])
    XCTAssertEqual(updatedPageMap.latestPageIndex, 1)
    XCTAssertEqual(updatedPageMap.loadedPagesCount, 2)
    XCTAssertEqual(updatedPageMap.totalItemsCount, 6)
    
  }
  
  func testInsertionKeepingMissingPage() {
    
    let p0 = ["i4", "i5", "i6"]
    let p2 = ["i10", "i11", "i12"]
    
    var pageMap = PageMap(p0)
    
    XCTAssertEqual(pageMap.items, [0: p0])
    XCTAssertEqual(pageMap.latestPageIndex, 0)
    XCTAssertEqual(pageMap.loadedPagesCount, 1)
    XCTAssertEqual(pageMap.totalPagesCount, 1)
    XCTAssertEqual(pageMap.totalItemsCount, 3)
    XCTAssertTrue(pageMap.containsPage(atIndex: 0))
    XCTAssertFalse(pageMap.containsPage(atIndex: 1))

    pageMap.insert(p2, withIndex: 2)
    
    XCTAssertEqual(pageMap.items, [0: p0, 2: p2])
    XCTAssertEqual(pageMap.latestPageIndex, 2)
    XCTAssertEqual(pageMap.loadedPagesCount, 2)
    XCTAssertEqual(pageMap.totalPagesCount, 3)
    XCTAssertEqual(pageMap.totalItemsCount, 9)
    XCTAssertTrue(pageMap.containsPage(atIndex: 0))
    XCTAssertFalse(pageMap.containsPage(atIndex: 1))
    XCTAssertTrue(pageMap.containsPage(atIndex: 2))

    let itemsSequence: [String?] = p0 + Array(repeating: nil, count: 3)  + p2
    
    for (index, element) in pageMap.enumerated() {
      XCTAssertEqual(itemsSequence[index], element)
    }
    
  }
  
  func testContainsItem() {
    
    let p0 = ["i4", "i5", "i6"]
    let pageMap = PageMap(p0)
    
    XCTAssertTrue(pageMap.containsItem(atIndex: 1))
    XCTAssertFalse(pageMap.containsItem(atIndex: 4))
    XCTAssertTrue(pageMap.containsPage(atIndex: 0))
    XCTAssertFalse(pageMap.containsPage(atIndex: 1))
    XCTAssertEqual(pageMap[0], "i4")
    XCTAssertEqual(pageMap[1], "i5")
    XCTAssertEqual(pageMap[2], "i6")
    
  }
  
  func testPageMapConvertibleInit() {
    
    let testPageMapConvertible = TestPageMapConvertible(page: 5, pageSize: 3, pageItems: ["i1", "i11", "i21"])
    let pageMap = PageMap(testPageMapConvertible)
    
    XCTAssertEqual(pageMap.items, [5: ["i1", "i11", "i21"]])
    
  }
  
  func testCleanUp() {
    
    let page0 = (0...10).map { "a\($0)" }
    let page1 = (0...10).map { "b\($0)" }
    let page2 = (0...10).map { "c\($0)" }
    let page3 = (0...10).map { "d\($0)" }
    
    var pageMap = PageMap([0: page0, 1: page1, 2: page2, 3: page3])
    
    pageMap?.cleanUp(basePageIndex: 1, keepingPagesOffset: 1)
    
    XCTAssertEqual(pageMap?.items, [0: page0, 1: page1, 2:page2])
    
  }
  
  func testCleanUp2() {
    
    let page0 = (0...10).map { "a\($0)" }
    let page1 = (0...10).map { "b\($0)" }
    let page2 = (0...10).map { "c\($0)" }
    let page3 = (0...10).map { "d\($0)" }
    
    var pageMap = PageMap([0: page0, 1: page1, 2: page2, 3: page3])
    
    pageMap?.cleanUp(basePageIndex: 2, keepingPagesOffset: 1)
    
    XCTAssertEqual(pageMap?.items, [1: page1, 2: page2, 3: page3])
    
  }
  
  func testCleanUp3() {
    
    let page0 = (0...10).map { "a\($0)" }
    let page1 = (0...10).map { "b\($0)" }
    let page2 = (0...10).map { "c\($0)" }
    let page3 = (0...10).map { "d\($0)" }
    
    var pageMap = PageMap([0: page0, 1: page1, 2: page2, 3: page3])
    pageMap?.cleanUp(basePageIndex: 2, keepingPagesOffset: 0)
    
    XCTAssertEqual(pageMap?.items, [2: page2])

  }
  
  func testCleanUp4() {
    
    let page0 = (0...10).map { "a\($0)" }
    let page1 = (0...10).map { "b\($0)" }
    let page2 = (0...10).map { "c\($0)" }
    let page3 = (0...10).map { "d\($0)" }
    
    var pageMap = PageMap([0: page0, 1: page1, 2: page2, 3: page3])
    pageMap?.cleanUp(basePageIndex: 2, keepingPagesOffset: 3)
    
    XCTAssertEqual(pageMap?.items, [0: page0, 1: page1, 2: page2, 3: page3])
    
  }
  
  func testCleanUpFirstElement() {
    
    let page0 = (0...10).map { "a\($0)" }
    let page1 = (0...10).map { "b\($0)" }
    let page2 = (0...10).map { "c\($0)" }
    let page3 = (0...10).map { "d\($0)" }
    
    var pageMap = PageMap([0: page0, 1: page1, 2: page2, 3: page3])
    pageMap?.cleanUp(basePageIndex: 0, keepingPagesOffset: 1)
    
    XCTAssertEqual(pageMap?.items, [0: page0, 1: page1])
    
  }
  
  func testCleanUpLastElement() {
    
    let page0 = (0...10).map { "a\($0)" }
    let page1 = (0...10).map { "b\($0)" }
    let page2 = (0...10).map { "c\($0)" }
    let page3 = (0...10).map { "d\($0)" }
    
    var pageMap = PageMap([0: page0, 1: page1, 2: page2, 3: page3])
    pageMap?.cleanUp(basePageIndex: 3, keepingPagesOffset: 1)
    
    XCTAssertEqual(pageMap?.items, [2: page2, 3: page3])
    
  }
  
}
