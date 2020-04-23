//
//  HitsInteractorRelatedItemsTests.swift
//  InstantSearchCore
//
//  Created by test test on 23/04/2020.
//  Copyright © 2020 Algolia. All rights reserved.
//

import Foundation

import Foundation
import XCTest
@testable import InstantSearchCore

class HitsInteractorRelatedItemsTests: XCTestCase {
    
  struct Product: Codable {
    let name: String
    let brand: String
    let type: String
    let categories: [String]
    let image: URL
  }
  
  func testConnect() {
    let matchingPatterns: [MatchingPattern<Product>] =
      [
        MatchingPattern(attribute: "brand", score: 3, filterPath: \.brand),
        MatchingPattern(attribute: "type", score: 10, filterPath: \.type),
        MatchingPattern(attribute: "categories", score: 2, filterPath: \.categories),
      ]

    let searcher = SingleIndexSearcher(index: .test)
    let product = Product.init(name: "productName", brand: "Amazon", type: "Streaming media plyr", categories: ["Streaming Media Players", "TV & Home Theater"], image: URL.init(string: "http://url.com")!)
    
    let hitsInteractor = HitsInteractor<JSON>.init()
    
    let hit: Hit<Product> = .init(objectID: "objectID123", object: product)
    hitsInteractor.connectSearcher(searcher, withRelatedItemsTo: hit, with: matchingPatterns)
    
    let expectedOptionalFilter = ["brand:Amazon<score=3>", "%5Bcategories%3AStreaming%20Media%20Players%3Cscore%3D2%3E%2Ccategories%3ATV%20%26%20Home%20Theater%3Cscore%3D2%3E%5D", "type:Streaming media plyr<score=10>"]
    
    XCTAssertEqual(searcher.indexQueryState.query.sumOrFiltersScores, true)
    XCTAssertEqual(searcher.indexQueryState.query.optionalFilters, expectedOptionalFilter)
    XCTAssertEqual(searcher.indexQueryState.query.facetFilters as! [String], ["objectID:-objectID123"])
    
  }
}
