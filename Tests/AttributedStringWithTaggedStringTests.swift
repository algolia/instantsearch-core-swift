//
//  AttributedStringWithTaggedStringTests.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 14/06/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation
import XCTest
@testable import InstantSearchCore

class AttributedStringWithTaggedStringTests: XCTestCase {
  
  private func checkRanges(string: NSAttributedString, ranges: [NSRange: [NSAttributedString.Key: Any]]) {
    string.enumerateAttributes(in: NSMakeRange(0, string.length), options: []) { attributes, range, _ in
      guard let expectedAttributes = ranges[range] else {
        XCTFail("Range [\(range.location), \(range.location + range.length)[ not expected")
        return
      }
      // We cannot easily compare the dictionaries because values don't necessarily conform to `Equatable`.
      // So we just verify that we have the same key set. For our purposes it's enough, because non highlighted
      // ranges will have empty attributes.
      XCTAssertEqual(Array(expectedAttributes.keys), Array(attributes.keys))
    }
  }
  
  func testAttributedString() {
    let input = "Woodstock is <em>Snoopy</em>'s friend"
    let highlightedString = HighlightedString(string: input)
    let attributes: [NSAttributedString.Key: Any] = [
      .foregroundColor: UIColor.red
    ]
    let attributedString = NSAttributedString(taggedString: highlightedString.taggedString, attributes: attributes)
    checkRanges(string: attributedString, ranges: [
      NSMakeRange(0, 13): [:],
      NSMakeRange(13, 6): attributes,
      NSMakeRange(19, 9): [:],
      ])
    
  }
  
}
