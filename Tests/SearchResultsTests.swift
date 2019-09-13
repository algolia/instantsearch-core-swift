//
//  SearchResultsV2Tests.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 01/03/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

@testable import InstantSearchCore
import XCTest

enum JSONReadingError: Error {
  case wrongPath
  case invalidData
}

extension Decodable {
  
  init(jsonFile: String, bundle: Bundle = .main) throws {
    
    guard let url = bundle.path(forResource: jsonFile, ofType: "json").flatMap(URL.init(fileURLWithPath:)) else {
      throw JSONReadingError.wrongPath
    }
    
    guard let data = try? Data(contentsOf: url, options: .mappedIfSafe) else {
      throw JSONReadingError.invalidData
    }
    
    let decoder = JSONDecoder()
    let item = try decoder.decode(Self.self, from: data)

    self = item
  }
  
}

class SearchResultsTests: XCTestCase {

  struct Item: Codable {
    let title: String
  }

  func testDecoding() {

    do {
      let searchResults = try SearchResults(jsonFile: "SearchResult", bundle: Bundle(for: SearchResultsTests.self))
      XCTAssertEqual(searchResults.stats.totalHitsCount, 596)
      XCTAssertEqual(searchResults.stats.page, 0)
      XCTAssertEqual(searchResults.stats.pagesCount, 60)
      XCTAssertEqual(searchResults.stats.hitsPerPage, 10)
      XCTAssertEqual(searchResults.stats.processingTimeMS, 4)
      XCTAssertEqual(searchResults.stats.query, "Amazon")
      XCTAssertEqual(searchResults.stats.queryID, "queryID")

      XCTAssertEqual(searchResults.queryID, "queryID")

      XCTAssertEqual(searchResults.hits.count, 10)
      XCTAssertEqual(searchResults.areFacetsCountExhaustive, true)
      XCTAssertNil(searchResults.message)
      XCTAssertNil(searchResults.queryAfterRemoval)
      XCTAssertEqual(searchResults.aroundGeoLocation!.latitude, 48.856614, accuracy: 0.01)
      XCTAssertEqual(searchResults.aroundGeoLocation!.longitude, 2.3522219, accuracy: 0.01)
      XCTAssertEqual(searchResults.rankingInfo!.parsedQuery, "amazon")
      XCTAssertEqual(searchResults.rankingInfo!.serverUsed, "d52-usw-3.algolia.net")
      XCTAssertFalse(searchResults.rankingInfo!.timeoutCounts)
      XCTAssertFalse(searchResults.rankingInfo!.timeoutHits)
      if let facetStats = searchResults.facetStats {
        XCTAssertTrue(facetStats.keys.contains("price"))
        XCTAssertTrue(facetStats.keys.contains("pubYear"))
      } else {
        XCTFail("Missing facet stats")
      }

    } catch let error {
      XCTFail("\(error)")
    }

  }
  
  

}
