//
//  TaggedStringTests.swift
//  InstantSearchCore-iOS
//
//  Created by Vladislav Fitc on 14/06/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation
import XCTest
@testable import InstantSearchCore

class TaggedStringTests: XCTestCase {
  
  let preTag = "<em>"
  let postTag = "</em>"
  
  func test() {
    let input = "Woodstock is <em>Snoopy</em>'s friend"
    let taggedString = TaggedString(string: input, preTag: preTag, postTag: postTag)
    
    XCTAssertEqual(taggedString.output, "Woodstock is Snoopy's friend")
    let taggedSubstrings = taggedString.taggedRanges.map { taggedString.output[$0] }
    XCTAssertEqual(taggedSubstrings, ["Snoopy"])
    let untaggedSubstrings = taggedString.untaggedRanges.map { taggedString.output[$0] }
    XCTAssertEqual(untaggedSubstrings, ["Woodstock is ", "'s friend"])
  }
  
  func testMultipleHighlighted() {
    
    let input = "<em>Live</em> as <em>if you were</em> to die <em>tomorrow</em>. Learn as if you were to live <em>forever</em>"
    
    let taggedString = TaggedString(string: input, preTag: preTag, postTag: postTag)
    
    XCTAssertEqual(taggedString.output, "Live as if you were to die tomorrow. Learn as if you were to live forever")
    
    let expectedTaggedSubstrings = [
      "Live",
      "if you were",
      "tomorrow",
      "forever",
    ]
    let taggedSubstrings = taggedString.taggedRanges.map { String(taggedString.output[$0]) }
    
    XCTAssertEqual(expectedTaggedSubstrings, taggedSubstrings)
    
    let expectedUntaggedSubstrings = [
      " as ",
      " to die ",
      ". Learn as if you were to live ",
    ]
    let untaggedSubstrings = taggedString.untaggedRanges.map {
      String(taggedString.output[$0])
    }
    XCTAssertEqual(expectedUntaggedSubstrings, untaggedSubstrings)
    
  }
  
  func testWholeStringHighlighted() {
    let input = "<em>Highlighted string</em>"
    let taggedString = TaggedString(string: input, preTag: preTag, postTag: postTag, options: [.caseInsensitive])
    XCTAssertEqual(taggedString.input, input)
    XCTAssertEqual(taggedString.output, "Highlighted string")
    XCTAssertEqual(taggedString.taggedRanges.map { String(taggedString.output[$0]) }, ["Highlighted string"])
    XCTAssertTrue(taggedString.untaggedRanges.map { String(taggedString.output[$0]) }.isEmpty)
  }
  
  func testNoHighlighted() {
    let input = "Just a string"
    let taggedString = TaggedString(string: input, preTag: preTag, postTag: postTag, options: [.caseInsensitive])
    XCTAssertEqual(taggedString.input, input)
    XCTAssertEqual(taggedString.output, input)
    XCTAssertTrue(taggedString.taggedRanges.isEmpty)
    XCTAssertEqual(taggedString.untaggedRanges.map { String(taggedString.output[$0]) }, [input])
  }
  
  func testEmpty() {
    let input = ""
    let taggedString = TaggedString(string: input, preTag: preTag, postTag: postTag, options: [.caseInsensitive])
    XCTAssertEqual(taggedString.input, input)
    XCTAssertEqual(taggedString.output, input)
    XCTAssertTrue(taggedString.taggedRanges.isEmpty)
    XCTAssertTrue(taggedString.untaggedRanges.isEmpty)
  }
  
}
