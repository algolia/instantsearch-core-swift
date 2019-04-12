//
//  FilterBuilderOperatorTEsts.swift
//  AlgoliaSearch OSX
//
//  Created by Vladislav Fitc on 22/01/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation
@testable import InstantSearchCore
import XCTest

class FilterStateOperatorTests: XCTestCase {

    func testAndGroupOperators() {
        
        let filterState = FilterState()
        
        filterState[.and("g")] +++ "tag1"
        
        XCTAssertEqual(filterState.buildSQL(), """
        "_tags":"tag1"
        """)
        
        XCTAssertTrue(filterState.contains(Filter.Tag(value:"tag1")))
        
        filterState[.and("g")] +++ [Filter.Tag(value:"tag2"), Filter.Tag(value:"tag3")]
        
        XCTAssertEqual(filterState.buildSQL(), """
        ( "_tags":"tag1" AND "_tags":"tag2" AND "_tags":"tag3" )
        """)
        
        XCTAssertTrue(filterState.contains(Filter.Tag(value:"tag2")))
        XCTAssertTrue(filterState.contains(Filter.Tag(value:"tag3")))
        
        filterState[.and("g")] +++ ("price", .greaterThan, 100)
        
        XCTAssertEqual(filterState.buildSQL(), """
        ( "_tags":"tag1" AND "_tags":"tag2" AND "_tags":"tag3" AND "price" > 100.0 )
        """)
        
        XCTAssertTrue(filterState.contains(Filter.Numeric(attribute: "price", operator: .greaterThan, value: 100)))
        
        filterState[.and("g")] +++ ("size", 30...40)
        
        XCTAssertEqual(filterState.buildSQL(), """
        ( "_tags":"tag1" AND "_tags":"tag2" AND "_tags":"tag3" AND "price" > 100.0 AND "size":30.0 TO 40.0 )
        """)
        
        XCTAssertTrue(filterState.contains(Filter.Numeric(attribute: "size", range: 30...40)))
        
        filterState[.and("g")] +++ ("brand", "sony")
        
        XCTAssertEqual(filterState.buildSQL(), """
        ( "_tags":"tag1" AND "_tags":"tag2" AND "_tags":"tag3" AND "brand":"sony" AND "price" > 100.0 AND "size":30.0 TO 40.0 )
        """)
        
        XCTAssertTrue(filterState.contains(Filter.Facet(attribute: "brand", value: "sony")))
        
        filterState[.and("g")] --- "tag1"
        
        XCTAssertEqual(filterState.buildSQL(), """
        ( "_tags":"tag2" AND "_tags":"tag3" AND "brand":"sony" AND "price" > 100.0 AND "size":30.0 TO 40.0 )
        """)
        
        XCTAssertFalse(filterState.contains(Filter.Tag(value:"tag1")))
        
        filterState[.and("g")] --- [Filter.Tag(value:"tag2"), Filter.Tag(value:"tag3")]
        
        XCTAssertEqual(filterState.buildSQL(), """
        ( "brand":"sony" AND "price" > 100.0 AND "size":30.0 TO 40.0 )
        """)
        
        XCTAssertFalse(filterState.contains(Filter.Tag(value:"tag2")))
        XCTAssertFalse(filterState.contains(Filter.Tag(value:"tag3")))
        
        filterState[.and("g")] --- ("price", .greaterThan, 100)
        
        XCTAssertEqual(filterState.buildSQL(), """
        ( "brand":"sony" AND "size":30.0 TO 40.0 )
        """)
        
        XCTAssertFalse(filterState.contains(Filter.Numeric(attribute: "price", operator: .greaterThan, value: 100)))
        
        filterState[.and("g")] --- ("size", 30...40)
        
        XCTAssertEqual(filterState.buildSQL(), """
        "brand":"sony"
        """)
        
        XCTAssertFalse(filterState.contains(Filter.Numeric(attribute: "size", range: 30...40)))
        
        filterState[.and("g")] --- ("brand", "sony")
        
        XCTAssertEqual(filterState.buildSQL(), "")
        
        XCTAssertFalse(filterState.contains(Filter.Facet(attribute: "brand", value: "sony")))
        
    }
    
    func testOrGroupOperators() {
        
        let filterState = FilterState()
        
        let tagGroup = FilterGroup.Or<Filter.Tag>.ID(name: "g1")
        let facetGroup = FilterGroup.Or<Filter.Facet>.ID(name: "g2")
        let numericGroup = FilterGroup.Or<Filter.Numeric>.ID(name: "g3")
        
        filterState[tagGroup] +++ "tag1"
        
        XCTAssertEqual(filterState.buildSQL(), """
        "_tags":"tag1"
        """)
        
        XCTAssertTrue(filterState.contains(Filter.Tag(value: "tag1")))
        
        filterState[tagGroup] +++ [Filter.Tag(value: "tag2"), Filter.Tag(value: "tag3")]
        
        XCTAssertEqual(filterState.buildSQL(), """
        ( "_tags":"tag1" OR "_tags":"tag2" OR "_tags":"tag3" )
        """)
        
        XCTAssertTrue(filterState.contains(Filter.Tag(value: "tag2")))
        XCTAssertTrue(filterState.contains(Filter.Tag(value: "tag3")))
        
        filterState[facetGroup] +++ ("brand", "sony")
        
        XCTAssertEqual(filterState.buildSQL(), """
        ( "_tags":"tag1" OR "_tags":"tag2" OR "_tags":"tag3" ) AND "brand":"sony"
        """)
        
        XCTAssertTrue(filterState.contains(Filter.Facet(attribute: "brand", value: "sony")))
        
        filterState[numericGroup] +++ ("price", .greaterThan, 100)
        
        XCTAssertEqual(filterState.buildSQL(), """
        ( "_tags":"tag1" OR "_tags":"tag2" OR "_tags":"tag3" ) AND "brand":"sony" AND "price" > 100.0
        """)
        
        XCTAssertTrue(filterState.contains(Filter.Numeric(attribute: "price", operator: .greaterThan, value: 100)))
        
        filterState[numericGroup] +++ ("size", 30...40)
        
        XCTAssertEqual(filterState.buildSQL(), """
        ( "_tags":"tag1" OR "_tags":"tag2" OR "_tags":"tag3" ) AND "brand":"sony" AND ( "price" > 100.0 OR "size":30.0 TO 40.0 )
        """)
        
        XCTAssertTrue(filterState.contains(Filter.Numeric(attribute: "size", range: 30...40)))
        
        filterState[tagGroup] --- "tag1"
        
        XCTAssertEqual(filterState.buildSQL(), """
        ( "_tags":"tag2" OR "_tags":"tag3" ) AND "brand":"sony" AND ( "price" > 100.0 OR "size":30.0 TO 40.0 )
        """)
        
        XCTAssertFalse(filterState.contains(Filter.Tag(value: "tag1")))
        
        filterState[tagGroup] --- [Filter.Tag(value: "tag2"), Filter.Tag(value: "tag3")]
        
        XCTAssertEqual(filterState.buildSQL(), """
        "brand":"sony" AND ( "price" > 100.0 OR "size":30.0 TO 40.0 )
        """)
        
        XCTAssertFalse(filterState.contains(Filter.Tag(value: "tag2")))
        XCTAssertFalse(filterState.contains(Filter.Tag(value: "tag3")))
        
        filterState[facetGroup] --- ("brand", "sony")
        
        XCTAssertEqual(filterState.buildSQL(), """
        ( "price" > 100.0 OR "size":30.0 TO 40.0 )
        """)
        
        XCTAssertFalse(filterState.contains(Filter.Facet(attribute: "brand", value: "sony")))
        
        filterState[numericGroup] --- ("price", .greaterThan, 100)
        
        XCTAssertEqual(filterState.buildSQL(), """
        "size":30.0 TO 40.0
        """)
        
        XCTAssertFalse(filterState.contains(Filter.Numeric(attribute: "price", operator: .greaterThan, value: 100)))
        
        filterState[numericGroup] --- ("size", 30...40)
        
        XCTAssertEqual(filterState.buildSQL(), "")
        
        XCTAssertFalse(filterState.contains(Filter.Numeric(attribute: "price", range: 30...40)))
        
        XCTAssertTrue(filterState.isEmpty)
        
    }

}

