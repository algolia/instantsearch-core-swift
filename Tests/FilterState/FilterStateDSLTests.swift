//
//  FilterStateDSLTests.swift
//  AlgoliaSearch OSX
//
//  Created by Vladislav Fitc on 22/01/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation
@testable import InstantSearchCore
import XCTest

class FilterStateDSLTests: XCTestCase {
  
  func testAndGroupOperators() {
    
    let filterStateDSL = FilterStateDSL()
    
    filterStateDSL.filterState.add(Filter.Tag(value: "tag1"), toGroupWithID: .and(name: "g"))
    
    XCTAssertEqual(filterStateDSL.filterState.buildSQL(), """
        "_tags":"tag1"
        """)
    
    XCTAssertTrue(filterStateDSL.filterState.contains(Filter.Tag(value:"tag1")))
    
    
    filterStateDSL.and("g") +++ ["tag2", Filter.Tag(value:"tag3")]
    
    XCTAssertEqual(filterStateDSL.filterState.buildSQL(), """
        ( "_tags":"tag1" AND "_tags":"tag2" AND "_tags":"tag3" )
        """)
    
    XCTAssertTrue(filterStateDSL.filterState.contains(Filter.Tag(value:"tag2")))
    XCTAssertTrue(filterStateDSL.filterState.contains(Filter.Tag(value:"tag3")))
    
    filterStateDSL.and("g") +++ ("price", .greaterThan, 100)
    
    XCTAssertEqual(filterStateDSL.filterState.buildSQL(), """
        ( "_tags":"tag1" AND "_tags":"tag2" AND "_tags":"tag3" AND "price" > 100.0 )
        """)
    
    XCTAssertTrue(filterStateDSL.filterState.contains(Filter.Numeric(attribute: "price", operator: .greaterThan, value: 100)))
    
    filterStateDSL.and("g") +++ ("size", 30...40)
    
    XCTAssertEqual(filterStateDSL.filterState.buildSQL(), """
        ( "_tags":"tag1" AND "_tags":"tag2" AND "_tags":"tag3" AND "price" > 100.0 AND "size":30.0 TO 40.0 )
        """)
    
    XCTAssertTrue(filterStateDSL.filterState.contains(Filter.Numeric(attribute: "size", range: 30...40)))
    
    filterStateDSL.and("g") +++ ("brand", "sony")
    
    XCTAssertEqual(filterStateDSL.filterState.buildSQL(), """
        ( "_tags":"tag1" AND "_tags":"tag2" AND "_tags":"tag3" AND "brand":"sony" AND "price" > 100.0 AND "size":30.0 TO 40.0 )
        """)
    
    XCTAssertTrue(filterStateDSL.filterState.contains(Filter.Facet(attribute: "brand", value: "sony")))
    
    filterStateDSL.and("g") --- "tag1"
    
    XCTAssertEqual(filterStateDSL.filterState.buildSQL(), """
        ( "_tags":"tag2" AND "_tags":"tag3" AND "brand":"sony" AND "price" > 100.0 AND "size":30.0 TO 40.0 )
        """)
    
    XCTAssertFalse(filterStateDSL.filterState.contains(Filter.Tag(value:"tag1")))
    
    filterStateDSL.and("g") --- [Filter.Tag(value:"tag2"), Filter.Tag(value:"tag3")]
    
    XCTAssertEqual(filterStateDSL.filterState.buildSQL(), """
        ( "brand":"sony" AND "price" > 100.0 AND "size":30.0 TO 40.0 )
        """)
    
    XCTAssertFalse(filterStateDSL.filterState.contains(Filter.Tag(value:"tag2")))
    XCTAssertFalse(filterStateDSL.filterState.contains(Filter.Tag(value:"tag3")))
    
    filterStateDSL.and("g") --- ("price", .greaterThan, 100)
    
    XCTAssertEqual(filterStateDSL.filterState.buildSQL(), """
        ( "brand":"sony" AND "size":30.0 TO 40.0 )
        """)
    
    XCTAssertFalse(filterStateDSL.filterState.contains(Filter.Numeric(attribute: "price", operator: .greaterThan, value: 100)))
    
    filterStateDSL.and("g") --- ("size", 30...40)
  
    
    XCTAssertEqual(filterStateDSL.filterState.buildSQL(), """
        "brand":"sony"
        """)
    
    XCTAssertFalse(filterStateDSL.filterState.contains(Filter.Numeric(attribute: "size", range: 30...40)))
    
    filterStateDSL.and("g") --- ("brand", "sony")
    
    XCTAssertEqual(filterStateDSL.filterState.buildSQL(), "")
    
    XCTAssertFalse(filterStateDSL.filterState.contains(Filter.Facet(attribute: "brand", value: "sony")))
    
  }
  
  func testOrGroupOperators() {
    
    let filterStateDSL = FilterStateDSL()
    
    filterStateDSL.or("g1") +++ "tag1"
    
    XCTAssertEqual(filterStateDSL.filterState.buildSQL(), """
        "_tags":"tag1"
        """)
    
    XCTAssertTrue(filterStateDSL.filterState.contains(Filter.Tag(value: "tag1")))
    
    filterStateDSL.or("g1") +++ [Filter.Tag(value: "tag2"), Filter.Tag(value: "tag3")]
    
    XCTAssertEqual(filterStateDSL.filterState.buildSQL(), """
        ( "_tags":"tag1" OR "_tags":"tag2" OR "_tags":"tag3" )
        """)
    
    XCTAssertTrue(filterStateDSL.filterState.contains(Filter.Tag(value: "tag2")))
    XCTAssertTrue(filterStateDSL.filterState.contains(Filter.Tag(value: "tag3")))
    
    filterStateDSL.or("g2") +++ ("brand", "sony")
    
    XCTAssertEqual(filterStateDSL.filterState.buildSQL(), """
        ( "_tags":"tag1" OR "_tags":"tag2" OR "_tags":"tag3" ) AND "brand":"sony"
        """)
    
    XCTAssertTrue(filterStateDSL.filterState.contains(Filter.Facet(attribute: "brand", value: "sony")))
    
    filterStateDSL.or("g3") +++ ("price", .greaterThan, 100)
    
    XCTAssertEqual(filterStateDSL.filterState.buildSQL(), """
        ( "_tags":"tag1" OR "_tags":"tag2" OR "_tags":"tag3" ) AND "brand":"sony" AND "price" > 100.0
        """)
    
    XCTAssertTrue(filterStateDSL.filterState.contains(Filter.Numeric(attribute: "price", operator: .greaterThan, value: 100)))
    
    filterStateDSL.or("g3") +++ ("size", 30...40)
    
    XCTAssertEqual(filterStateDSL.filterState.buildSQL(), """
        ( "_tags":"tag1" OR "_tags":"tag2" OR "_tags":"tag3" ) AND "brand":"sony" AND ( "price" > 100.0 OR "size":30.0 TO 40.0 )
        """)
    
    XCTAssertTrue(filterStateDSL.filterState.contains(Filter.Numeric(attribute: "size", range: 30...40)))
    
    filterStateDSL.or("g1") --- "tag1"
    
    XCTAssertEqual(filterStateDSL.filterState.buildSQL(), """
        ( "_tags":"tag2" OR "_tags":"tag3" ) AND "brand":"sony" AND ( "price" > 100.0 OR "size":30.0 TO 40.0 )
        """)
    
    XCTAssertFalse(filterStateDSL.filterState.contains(Filter.Tag(value: "tag1")))
    
    filterStateDSL.or("g1") --- [Filter.Tag(value: "tag2"), Filter.Tag(value: "tag3")]
    
    XCTAssertEqual(filterStateDSL.filterState.buildSQL(), """
        "brand":"sony" AND ( "price" > 100.0 OR "size":30.0 TO 40.0 )
        """)
    
    XCTAssertFalse(filterStateDSL.filterState.contains(Filter.Tag(value: "tag2")))
    XCTAssertFalse(filterStateDSL.filterState.contains(Filter.Tag(value: "tag3")))
    
    filterStateDSL.or("g2") --- ("brand", "sony")
    
    XCTAssertEqual(filterStateDSL.filterState.buildSQL(), """
        ( "price" > 100.0 OR "size":30.0 TO 40.0 )
        """)
    
    XCTAssertFalse(filterStateDSL.filterState.contains(Filter.Facet(attribute: "brand", value: "sony")))
    
    filterStateDSL.or("g3") --- ("price", .greaterThan, 100)
    
    XCTAssertEqual(filterStateDSL.filterState.buildSQL(), """
        "size":30.0 TO 40.0
        """)
    
    XCTAssertFalse(filterStateDSL.filterState.contains(Filter.Numeric(attribute: "price", operator: .greaterThan, value: 100)))
    
    filterStateDSL.or("g3") --- ("size", 30...40)
    
    XCTAssertEqual(filterStateDSL.filterState.buildSQL(), "")
    
    XCTAssertFalse(filterStateDSL.filterState.contains(Filter.Numeric(attribute: "price", range: 30...40)))
    
    XCTAssertTrue(filterStateDSL.filterState.isEmpty)
    
  }
  
}

