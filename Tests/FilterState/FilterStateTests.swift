//
//  FilterStateTests.swift
//  AlgoliaSearch
//
//  Created by Guy Daher on 10/12/2018.
//  Copyright © 2018 Algolia. All rights reserved.
//

import Foundation

@testable import InstantSearchCore
import XCTest

extension FilterState {
  
  func buildSQL() -> String {
    return getFilterGroups().compactMap { $0 as? FilterGroupType & SQLSyntaxConvertible }.sqlForm
  }
  
}

class FilterStateTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testPlayground() {
        
        let filterState = FilterState()
        let filterFacet1 = Filter.Facet(attribute: "category", value: "table")
        let filterFacet2 = Filter.Facet(attribute: "category", value: "chair")
        let filterNumeric1 = Filter.Numeric(attribute: "price", operator: .greaterThan, value: 10)
        let filterNumeric2 = Filter.Numeric(attribute: "price", operator: .lessThan, value: 20)
        let filterTag1 = Filter.Tag(value: "Tom")
        let filterTag2 = Filter.Tag(value: "Hank")

        let groupFacets = FilterGroup.Or<Filter.Facet>.ID(name: "filterFacets")
        let groupFacetsOtherInstance = FilterGroup.Or<Filter.Facet>.ID(name: "filterFacets")
        let groupNumerics = FilterGroup.And.ID(name: "filterNumerics")
        let groupTagsOr = FilterGroup.Or<Filter.Tag>.ID(name: "filterTags")
        let groupTagsAnd = FilterGroup.And.ID(name: "filterTags")

        filterState.add(filterFacet1, to: groupFacets)
        // Make sure that if we re-create a group instance, filters will stay in same group bracket
        filterState.add(filterFacet2, to: groupFacetsOtherInstance)

        filterState.add(filterNumeric1, to: groupNumerics)
        filterState.add(filterNumeric2, to: groupNumerics)
         // Repeat once to see if the Set rejects same filter
        filterState.add(filterNumeric2, to: groupNumerics)

        filterState.addAll( [filterTag1, filterTag2], to: groupTagsOr)
        filterState.add(filterTag1, to: groupTagsAnd)
      let expectedState = """
( "category":"chair" OR "category":"table" ) AND ( "price" < 20.0 AND "price" > 10.0 ) AND ( "_tags":"Hank" OR "_tags":"Tom" )
"""
        XCTAssertEqual(filterState.buildSQL(), expectedState)
        
        XCTAssertTrue(filterState.contains(filterFacet1))
        
        let missingFilter = Filter.Facet(attribute: "bla", value: false)
        XCTAssertFalse(filterState.contains(missingFilter))
        
        filterState.remove(filterTag1, from: groupTagsAnd) // existing one
        filterState.remove(filterTag1, from: groupTagsAnd) // remove one more time
        filterState.remove(Filter.Tag(value: "unexisting"), from: groupTagsOr) // remove one that does not exist
        filterState.remove(filterFacet1) // Remove in all groups

        let expectedFilterState2 = """
                                    "category":"chair" AND ( "price" < 20.0 AND "price" > 10.0 ) AND "_tags":"Hank"
                                    """
        XCTAssertEqual(filterState.buildSQL(), expectedFilterState2)

        filterState.removeAll([filterNumeric1, filterNumeric2])

        let expectedFilterState3 = """
                                    "category":"chair" AND "_tags":"Hank"
                                    """
        XCTAssertEqual(filterState.buildSQL(), expectedFilterState3)
                
    }
    
    func testInversion() {
        
        let filterState = FilterState()
      
        filterState[.or("a")] +++ Filter.Tag(value: "tagA", isNegated: true) +++ Filter.Tag(value: "tagB", isNegated: true)
        filterState[.or("b")] +++ Filter.Facet(attribute: "size", value: 40, isNegated: true) +++ Filter.Facet(attribute: "featured", value: true, isNegated: true)
        
        let expectedState = "( NOT \"_tags\":\"tagA\" OR NOT \"_tags\":\"tagB\" ) AND ( NOT \"featured\":\"true\" OR NOT \"size\":\"40.0\" )"
        
        XCTAssertEqual(filterState.buildSQL(), expectedState)

    }
    
    func testAdd() {
        
        let filterState = FilterState()
        
        let filterFacet1 = Filter.Facet(attribute: Attribute("category"), value: "table")
        let filterFacet2 = Filter.Facet(attribute: Attribute("category"), value: "chair")
        let filterNumeric1 = Filter.Numeric(attribute: "price", operator: .greaterThan, value: 10)
        let filterNumeric2 = Filter.Numeric(attribute: "price", operator: .lessThan, value: 20)
        let filterTag1 = Filter.Tag(value: "Tom")
        let filterTag2 = Filter.Tag(value: "Hank")
        
        let groupFacets = FilterGroup.Or<Filter.Facet>.ID(name: "filterFacets")
        let groupFacetsOtherInstance = FilterGroup.Or<Filter.Facet>.ID(name: "filterFacets")
        let groupNumerics = FilterGroup.And.ID(name: "filterNumerics")
        let groupTagsOr = FilterGroup.Or<Filter.Tag>.ID(name: "filterTags")
        let groupTagsAnd = FilterGroup.And.ID(name: "filterTags")
        
        filterState.add(filterFacet1, to: groupFacets)
        // Make sure that if we re-create a group instance, filters will stay in same group bracket
        filterState.add(filterFacet2, to: groupFacetsOtherInstance)
        
        filterState.add(filterNumeric1, to: groupNumerics)
        filterState.add(filterNumeric2, to: groupNumerics)
        // Repeat once to see if the Set rejects same filter
        filterState.add(filterNumeric2, to: groupNumerics)
        
        filterState.addAll([filterTag1, filterTag2], to: groupTagsOr)
        filterState.add(filterTag1, to: groupTagsAnd)
        
        let expectedState = """
                                    ( "category":"chair" OR "category":"table" ) AND ( "price" < 20.0 AND "price" > 10.0 ) AND ( "_tags":"Hank" OR "_tags":"Tom" )
                                    """
        
        XCTAssertEqual(filterState.buildSQL(), expectedState)
        
    }
    
    func testContains() {
        
        let filterState = FilterState()
        
        let tagA = Filter.Tag(value: "A")
        let tagB = Filter.Tag(value: "B")
        let tagC = Filter.Tag(value: "C")
        let numeric = Filter.Numeric(attribute: "price", operator: .lessThan, value: 100)
        let facet = Filter.Facet(attribute: "new", value: true)
        
        filterState[.or("tags")] +++ [tagA, tagB]
        
        filterState[.or("tags")] +++ "hm" +++ "other"
        
        filterState[.or("numeric")] +++ ("size", 15...20) +++ ("price", .greaterThan, 100)
        
        filterState[.and("others")]
            +++ numeric
            +++ facet
        
        filterState[.and("some")]
            +++ ("price", .greaterThan, 20)
            +++ ("size", 15...20)
            +++ "someTag"
            +++ [("brand", "apple"), ("featured", true), ("rating", 4)]
        
        XCTAssertTrue(filterState.contains(tagA))
        XCTAssertTrue(filterState.contains(tagB))
        XCTAssertTrue(filterState.contains(numeric))
        XCTAssertTrue(filterState.contains(facet))
        XCTAssertTrue(filterState.contains(tagA, in: .or("tags")))
        XCTAssertTrue(filterState.contains(tagB, in: .or("tags")))
        XCTAssertTrue(filterState.contains(numeric, in: .and("others")))
        XCTAssertTrue(filterState.contains(facet, in: .and("others")))
        
        XCTAssertFalse(filterState.contains(tagC))
        XCTAssertFalse(filterState.contains(Filter.Facet(attribute: "new", value: false)))
        XCTAssertFalse(filterState.contains(tagC, in: .or("tags")))
        XCTAssertFalse(filterState.contains(tagA, in: .and("others")))
        XCTAssertFalse(filterState.contains(tagB, in: .and("others")))
        
        let expectedResult = """
        ( "price" > 100.0 OR "size":15.0 TO 20.0 ) AND ( "new":"true" AND "price" < 100.0 ) AND ( "_tags":"someTag" AND "brand":"apple" AND "featured":"true" AND "price" > 20.0 AND "rating":"4.0" AND "size":15.0 TO 20.0 ) AND ( "_tags":"A" OR "_tags":"B" OR "_tags":"hm" OR "_tags":"other" )
        """
        
        XCTAssertEqual(filterState.buildSQL(), expectedResult)
        
    }

    func testMove() {
        
        let filterState = FilterState()

        let orGroup: FilterGroup.Or<Filter.Tag>.ID = .or("tags")
        let andGroup: FilterGroup.And.ID = .and("some")
        let anotherOrGroup: FilterGroup.Or<Filter.Tag>.ID = .or("otherTags")
        let anotherAndGroup: FilterGroup.And.ID = .and("other")
        
        let tagA = Filter.Tag(value: "a")
        let tagB = Filter.Tag(value: "b")
        let tagC = Filter.Tag(value: "c")
        let numeric = Filter.Numeric(attribute: "price", operator: .greaterThan, value: 10)
        
        filterState[orGroup] +++ tagA +++ tagB
        filterState[andGroup] +++ tagC +++ numeric
        
        XCTAssertEqual(filterState.buildSQL(), """
        ( "_tags":"c" AND "price" > 10.0 ) AND ( "_tags":"a" OR "_tags":"b" )
        """)
        
        // Move or -> and
        XCTAssertTrue(filterState[orGroup].move(tagA, to: andGroup))
        // Test consistency
        XCTAssertFalse(filterState[orGroup].contains(tagA))
        XCTAssertTrue(filterState[andGroup].contains(tagA))
        // Test impossibility to move it again
        XCTAssertFalse(filterState[orGroup].move(tagA, to: andGroup))
        
        XCTAssertEqual(filterState.buildSQL(), """
        ( "_tags":"a" AND "_tags":"c" AND "price" > 10.0 ) AND "_tags":"b"
        """)
        
        // Move and -> or
        XCTAssertTrue(filterState[andGroup].move(tagC, to: orGroup))
        // Test consistency
        XCTAssertFalse(filterState[andGroup].contains(tagC))
        XCTAssertTrue(filterState[orGroup].contains(tagC))
        // Test impossibility to move it again
        XCTAssertFalse(filterState[andGroup].move(tagC, to: orGroup))
        
        XCTAssertEqual(filterState.buildSQL(), """
        ( "_tags":"a" AND "price" > 10.0 ) AND ( "_tags":"b" OR "_tags":"c" )
        """)
        
        // Move or -> or
        XCTAssertTrue(filterState[orGroup].move(tagC, to: anotherOrGroup))
        // Test consistency
        XCTAssertTrue(filterState[anotherOrGroup].contains(tagC))
        XCTAssertFalse(filterState[orGroup].contains(tagC))
        // Test impossibility to move it again
        XCTAssertFalse(filterState[orGroup].move(tagC, to: anotherOrGroup))
        
        XCTAssertEqual(filterState.buildSQL(), """
        "_tags":"c" AND ( "_tags":"a" AND "price" > 10.0 ) AND "_tags":"b"
        """)
        
        // Move and -> and
        XCTAssertTrue(filterState[andGroup].move(numeric, to: anotherAndGroup))
        // Test consistency
        XCTAssertTrue(filterState[anotherAndGroup].contains(numeric))
        XCTAssertFalse(filterState[andGroup].contains(numeric))
        // Test impossibility to move it again
        XCTAssertFalse(filterState[andGroup].move(numeric, to: anotherAndGroup))
        
        XCTAssertEqual(filterState.buildSQL(), """
        "price" > 10.0 AND "_tags":"c" AND "_tags":"a" AND "_tags":"b"
        """)

    }
    
    func testRemove() {
        
        let filterState = FilterState()
        
        filterState[.or("orTags")] +++ "a" +++ "b"
        filterState[.and("any")] +++ Filter.Tag(value: "a") +++ Filter.Tag(value: "b") +++ Filter.Numeric(attribute: "price", range: 1...10)
        
        XCTAssertEqual(filterState.buildSQL(), """
        ( "_tags":"a" AND "_tags":"b" AND "price":1.0 TO 10.0 ) AND ( "_tags":"a" OR "_tags":"b" )
        """)
        
        XCTAssertTrue(filterState.remove(Filter.Tag(value: "a")))
        XCTAssertFalse(filterState.contains(Filter.Tag(value: "a")))
        
        XCTAssertEqual(filterState.buildSQL(), """
        ( "_tags":"b" AND "price":1.0 TO 10.0 ) AND "_tags":"b"
        """)
        
        // Try to delete one more time
        XCTAssertFalse(filterState.remove(Filter.Tag(value: "a")))
        
        XCTAssertEqual(filterState.buildSQL(), """
        ( "_tags":"b" AND "price":1.0 TO 10.0 ) AND "_tags":"b"
        """)
        
        // Remove filter occuring in multiple groups from one group
        
        XCTAssertTrue(filterState.remove(Filter.Tag(value: "b"), from: .and("any")))
        
        XCTAssertTrue(filterState.contains(Filter.Tag(value: "b")))
        XCTAssertFalse(filterState.contains(Filter.Tag(value: "b"), in: .and("any")))
        XCTAssertTrue(filterState.contains(Filter.Tag(value: "b"), in: .or("orTags")))
        
        XCTAssertEqual(filterState.buildSQL(), """
        "price":1.0 TO 10.0 AND "_tags":"b"
        """)

        // Remove all from group
        filterState.removeAll(from: .and("any"))
        XCTAssertTrue(filterState[.and("any")].isEmpty)
        
        XCTAssertEqual(filterState.buildSQL(), """
        "_tags":"b"
        """)
        
        // Remove all anywhere
        filterState.removeAll()
        XCTAssertTrue(filterState.isEmpty)
        
        XCTAssertEqual(filterState.buildSQL(), "")
        
    }
    
    func testSubscriptAndOperatorPlayground() {
        
        let filterState = FilterState()
        
        let filterFacet1 = Filter.Facet(attribute: "category", value: "table")
        let filterFacet2 = Filter.Facet(attribute: "category", value: "chair")
        let filterNumeric1 = Filter.Numeric(attribute: "price", operator: .greaterThan, value: 10)
        let filterNumeric2 = Filter.Numeric(attribute: "price", operator: .lessThan, value: 20)
        let filterTag1 = Filter.Tag(value: "Tom")
        
        filterState[.or("a")] +++ filterFacet1 --- filterFacet2
        
        XCTAssertEqual(filterState.buildSQL(), """
        "category":"table"
        """)
        
        filterState[.and("b")] +++ [filterNumeric1] +++ filterTag1
        
        XCTAssertEqual(filterState.buildSQL(), """
        "category":"table" AND ( "_tags":"Tom" AND "price" > 10.0 )
        """)
        
        filterState[.or("a")] +++ [filterFacet1, filterFacet2]
        
        XCTAssertEqual(filterState.buildSQL(), """
        ( "category":"chair" OR "category":"table" ) AND ( "_tags":"Tom" AND "price" > 10.0 )
        """)

        filterState[.and("b")] +++ [filterNumeric1, filterNumeric2]
        
        XCTAssertEqual(filterState.buildSQL(), """
        ( "category":"chair" OR "category":"table" ) AND ( "_tags":"Tom" AND "price" < 20.0 AND "price" > 10.0 )
        """)
        
    }
    
    func testClearAttribute() {
        
        let filterNumeric1 = Filter.Numeric(attribute: "price", operator: .greaterThan, value: 10)
        let filterNumeric2 = Filter.Numeric(attribute: "price", operator: .lessThan, value: 20)
        let filterTag1 = Filter.Tag(value: "Tom")
        let filterTag2 = Filter.Tag(value: "Hank")
        
        let groupNumericsOr = FilterGroup.Or<Filter.Numeric>.ID(name: "filterNumeric")
        let groupTagsOr = FilterGroup.Or<Filter.Tag>.ID(name: "filterTags")

        let filterState = FilterState()
        
        filterState.addAll([filterNumeric1, filterNumeric2], to: groupNumericsOr)
        XCTAssertEqual(filterState.buildSQL(), """
        ( "price" < 20.0 OR "price" > 10.0 )
        """)
        
        filterState.addAll([filterTag1, filterTag2], to: groupTagsOr)
        
        XCTAssertEqual(filterState.buildSQL(), """
        ( "price" < 20.0 OR "price" > 10.0 ) AND ( "_tags":"Hank" OR "_tags":"Tom" )
        """)

        filterState.removeAll(for: "price")
        
        XCTAssertFalse(filterState.contains(filterNumeric1))
        XCTAssertFalse(filterState.contains(filterNumeric2))
        XCTAssertTrue(filterState.contains(filterTag1))
        XCTAssertTrue(filterState.contains(filterTag2))
        
        XCTAssertEqual(filterState.buildSQL(), """
        ( "_tags":"Hank" OR "_tags":"Tom" )
        """)
        
    }
    
    func testIsEmpty() {
        let filterState = FilterState()
        let filter = Filter.Numeric(attribute: "price", operator: .greaterThan, value: 10)
        let group = FilterGroup.Or<Filter.Numeric>.ID(name: "group")
        XCTAssertTrue(filterState.isEmpty)
        filterState.add(filter, to: group)
        XCTAssertEqual(filterState.buildSQL(), """
        "price" > 10.0
        """)
        XCTAssertFalse(filterState.isEmpty)
        filterState.remove(filter)
        XCTAssertTrue(filterState.isEmpty, filterState.buildSQL())
        XCTAssertEqual(filterState.buildSQL(), "")
    }
    
    func testClear() {
        let filterState = FilterState()
        let filterNumeric = Filter.Numeric(attribute: "price", operator: .greaterThan, value: 10)
        let filterTag = Filter.Tag(value: "Tom")
        let group = FilterGroup.And.ID(name: "group")
        filterState.add(filterNumeric, to: group)
        XCTAssertEqual(filterState.buildSQL(), """
        "price" > 10.0
        """)
        filterState.add(filterTag, to: group)
        XCTAssertEqual(filterState.buildSQL(), """
        ( "_tags":"Tom" AND "price" > 10.0 )
        """)
        filterState.removeAll()
        XCTAssertTrue(filterState.isEmpty)
        XCTAssertEqual(filterState.buildSQL(), "")
    }
    
    func testToggle() {
        
        let filterState = FilterState()
        
        let filter = Filter.Facet(attribute: "brand", stringValue: "sony")
        
        // Conjunctive Group
        
        XCTAssertFalse(filterState[.or("a")].contains(filter))
        XCTAssertTrue(filterState[.or("a", ofType: Filter.Facet.self)].isEmpty)
        
        filterState[.or("a")].toggle(filter)
        XCTAssertTrue(filterState[.or("a")].contains(filter))
        XCTAssertFalse(filterState[.or("a", ofType: Filter.Facet.self)].isEmpty)
        
        filterState[.or("a")].toggle(filter)
        XCTAssertFalse(filterState[.or("a")].contains(filter))
        XCTAssertTrue(filterState[.or("a", ofType: Filter.Facet.self)].isEmpty)
        
        // Disjunctive Group
        
        XCTAssertFalse(filterState[.and("a")].contains(filter))
        XCTAssertTrue(filterState[.and("a")].isEmpty)
        
        filterState[.and("a")].toggle(filter)
        XCTAssertTrue(filterState[.and("a")].contains(filter))
        XCTAssertFalse(filterState[.and("a")].isEmpty)
        
        filterState[.and("a")].toggle(filter)
        XCTAssertFalse(filterState[.and("a")].contains(filter))
        XCTAssertTrue(filterState[.and("a")].isEmpty)
        
        filterState[.and("a")] <> ("size", .equals, 40) <> ("country", "france")
        
        XCTAssertFalse(filterState[.and("a")].isEmpty)
        XCTAssertTrue(filterState[.and("a")].contains(Filter.Numeric(attribute: "size", operator: .equals, value: 40)))
        XCTAssertTrue(filterState[.and("a")].contains(Filter.Facet(attribute: "country", stringValue: "france")))
        
        filterState[.and("a")] <> ("size", .equals, 40) <> ("country", "france")
        
        XCTAssertTrue(filterState[.and("a")].isEmpty)
        XCTAssertFalse(filterState[.and("a")].contains(Filter.Numeric(attribute: "size", operator: .equals, value: 40)))
        XCTAssertFalse(filterState[.and("a")].contains(Filter.Facet(attribute: "country", stringValue: "france")))
        
        
        filterState[.or("a")] <> ("size", 40) <> ("count", 25)
        
        XCTAssertFalse(filterState[.or("a", ofType: Filter.Facet.self)].isEmpty)
        XCTAssertTrue(filterState[.or("a", ofType: Filter.Facet.self)].contains(Filter.Facet(attribute: "size", floatValue: 40)))
        XCTAssertTrue(filterState[.or("a", ofType: Filter.Facet.self)].contains(Filter.Facet(attribute: "count", floatValue: 25)))
        
    }

    
    func testDisjunctiveFacetAttributes() {
        
        let filterState = FilterState()
        
        filterState[.or("g1")]
            +++ ("color", "red")
            +++ ("color", "green")
            +++ ("color", "blue")
        
        XCTAssertEqual(filterState.getDisjunctiveFacetsAttributes(), ["color"])
        
        filterState[.or("g2")]
            +++ ("country", "france")
        
        XCTAssertEqual(filterState.getDisjunctiveFacetsAttributes(), ["color", "country"])

        filterState[.or("g2")]
            +++ ("country", "uk")
        
        filterState[.or("g2")]
            +++ ("size", 40)
        
        XCTAssertEqual(filterState.getDisjunctiveFacetsAttributes(), ["color", "country", "size"])
        
        filterState[.and("g3")]
            +++ ("price", .greaterThan, 50)
            +++ ("featured", true)
        
        XCTAssertEqual(filterState.getDisjunctiveFacetsAttributes(), ["color", "country", "size"])

        filterState[.and("g3")]
            +++ ("price", .lessThan, 100)
        
        XCTAssertEqual(filterState.getDisjunctiveFacetsAttributes(), ["color", "country", "size"])
        
        filterState[.or("g2")]
            +++ ("size", 42)
        
        XCTAssertEqual(filterState.getDisjunctiveFacetsAttributes(), ["color", "country", "size"])
        
        filterState[.or("g1")]
            --- ("color", "red")
            --- ("color", "green")
            --- ("color", "blue")
        
        XCTAssertEqual(filterState.getDisjunctiveFacetsAttributes(), ["country", "size"])

    }
    
    func testRefinements() {
        
        let filterState = FilterState()
    
        filterState[.or("g1")]
            +++ ("color", "red")
            +++ ("color", "green")
            +++ ("color", "blue")
        
        XCTAssertEqual(filterState.getRawFacetFilters()["color"].flatMap(Set.init), Set(["red", "green", "blue"]))

        filterState[.or("g2")]
            +++ ("country", "france")

        XCTAssertEqual(filterState.getRawFacetFilters()["color"].flatMap(Set.init), Set(["red", "green", "blue"]))
        XCTAssertEqual(filterState.getRawFacetFilters()["country"], ["france"])
        
        filterState[.and("g3")]
            +++ ("country", "uk")
        
        XCTAssertEqual(filterState.getRawFacetFilters()["color"].flatMap(Set.init), Set(["red", "green", "blue"]))
        XCTAssertEqual(filterState.getRawFacetFilters()["country"].flatMap(Set.init), Set(["france", "uk"]))

        filterState[.or("g1")]
            --- ("color", "green")

        XCTAssertEqual(filterState.getRawFacetFilters()["color"].flatMap(Set.init), Set(["red", "blue"]))
        XCTAssertEqual(filterState.getRawFacetFilters()["country"].flatMap(Set.init), Set(["france", "uk"]))

    }

  func testFilterScoring() {

    let filterState = FilterState()

    let filterFacet1 = Filter.Facet(attribute: Attribute("category"), value: "table", score: 5)
    let filterFacet2 = Filter.Facet(attribute: Attribute("category"), value: "chair", score: 10)

    let groupFacets = FilterGroup.Or<Filter.Facet>.ID(name: "filterFacets")

    filterState.add(filterFacet1, to: groupFacets)
    filterState.add(filterFacet2, to: groupFacets)

    let expectedResult = """
                                    ( "category":"chair<score=10>" OR "category":"table<score=5>" )
                                    """

    XCTAssertEqual(filterState.buildSQL(), expectedResult)


  }
    
}
