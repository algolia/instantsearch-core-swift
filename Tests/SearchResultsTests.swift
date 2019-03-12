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

class SearchResultsTests: XCTestCase {

  struct Item: Codable {
    let title: String
  }

  func testDecoding() {

    guard let searchResultURL = Bundle.init(for: SearchResultsTests.self).path(forResource: "SearchResult", ofType: "json").flatMap(URL.init(fileURLWithPath:)) else {
      XCTFail("Cannot read file")
      return
    }
    guard let data = try? Data(contentsOf: searchResultURL, options: .mappedIfSafe) else {
      XCTFail("Cannot parse data")
      return
    }

    XCTAssertFalse(data.isEmpty, "Data is empty")

    let decoder = JSONDecoder()

    do {
      let searchResults = try decoder.decode(SearchResults<Hit<Item>>.self, from: data)
      XCTAssertEqual(searchResults.totalHitsCount, 596)
      XCTAssertEqual(searchResults.page, 0)
      XCTAssertEqual(searchResults.pagesCount, 60)
      XCTAssertEqual(searchResults.hitsPerPage, 10)
      XCTAssertEqual(searchResults.processingTimeMS, 4)
      XCTAssertEqual(searchResults.query, "Amazon")
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
      print(searchResults.hits)

    } catch let error {
      XCTFail("\(error)")
    }

  }

}
