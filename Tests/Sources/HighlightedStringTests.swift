//
//  HighlightedStringTests.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 08/02/2020.
//  Copyright © 2020 Algolia. All rights reserved.
//

import Foundation
import XCTest
@testable import InstantSearchCore

class HighlightedStringTests: XCTestCase {
  
    func testWithDecodedString() {

      let expectedHighlightedPart = "rennais"
      
      let inlineString = "VIDÉO. Des CRS déployés devant un lycée <em>rennais</em> pour les épreuves anticipées du bac"

      let decodedString: String = Bundle(for: DisjunctiveFacetingTests.self)
        .path(forResource: "HS", ofType: "json")
        .flatMap { URL(fileURLWithPath: $0) }
        .flatMap { try? String(contentsOf: $0, encoding: .utf8) }!
      
      let inlineHiglighted = HighlightedString(string: inlineString)
      let decodedHighlighted = HighlightedString(string: decodedString)
      
      func extractHighlightedPart(from title: HighlightedString) -> String {
        let highlightedRange = title.taggedString.taggedRanges.first!
        let highlightedPart = title.taggedString.output[highlightedRange]
        return String(highlightedPart)
      }
      
      XCTAssertEqual(expectedHighlightedPart, extractHighlightedPart(from: inlineHiglighted))
      XCTAssertEqual(expectedHighlightedPart, extractHighlightedPart(from: decodedHighlighted))

    }

}

