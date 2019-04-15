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
    
    let groupFacets = FilterGroup.ID.or(name: "filterFacets")
    let groupFacetsOtherInstance = FilterGroup.ID.or(name: "filterFacets")
    let groupNumerics = FilterGroup.ID.and(name: "filterNumerics")
    let groupTagsOr = FilterGroup.ID.or(name: "filterTags")
    let groupTagsAnd = FilterGroup.ID.and(name: "filterTags")
    
    filterState.add(filterFacet1, to: groupFacets)
    // Make sure that if we re-create a group instance, filters will stay in same group bracket
    filterState.add(filterFacet2, to: groupFacetsOtherInstance)
    
    filterState.add(filterNumeric1, to: groupNumerics)
    filterState.add(filterNumeric2, to: groupNumerics)
    // Repeat once to see if the Set rejects same filter
    filterState.add(filterNumeric2, to: groupNumerics)
    
    filterState.addAll(filters: [filterTag1, filterTag2], to: groupTagsOr)
    filterState.add(filterTag1, to: groupTagsAnd)
    let expectedState = """
( "category":"chair" OR "category":"table" ) AND ( "price" < 20.0 AND "price" > 10.0 ) AND ( "_tags":"Hank" OR "_tags":"Tom" ) AND "_tags":"Tom"
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
                                    "category":"chair" AND ( "price" < 20.0 AND "price" > 10.0 ) AND ( "_tags":"Hank" OR "_tags":"Tom" )
                                    """
    XCTAssertEqual(filterState.buildSQL(), expectedFilterState2)
    
    filterState.removeAll([filterNumeric1, filterNumeric2])
    
    let expectedFilterState3 = """
                                    "category":"chair" AND ( "_tags":"Hank" OR "_tags":"Tom" )
                                    """
    XCTAssertEqual(filterState.buildSQL(), expectedFilterState3)
    
  }
  
  func testInversion() {
    
    let filterState = FilterState()
    
    filterState.addAll(filters: [
      Filter.Tag(value: "tagA", isNegated: true),
      Filter.Tag(value: "tagB", isNegated: true)]
      , to: .or(name: "a"))
    
    filterState.addAll(filters: [
      Filter.Facet(attribute: "size", value: 40, isNegated: true),
      Filter.Facet(attribute: "featured", value: true, isNegated: true)
      ], to: .or(name: "b"))
    
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
    
    let groupFacets = FilterGroup.ID.or(name: "filterFacets")
    let groupFacetsOtherInstance = FilterGroup.ID.or(name: "filterFacets")
    let groupNumerics = FilterGroup.ID.and(name: "filterNumerics")
    let groupTagsOr = FilterGroup.ID.or(name: "filterTags")
    let groupTagsAnd = FilterGroup.ID.and(name: "filterTags")
    
    filterState.add(filterFacet1, to: groupFacets)
    // Make sure that if we re-create a group instance, filters will stay in same group bracket
    filterState.add(filterFacet2, to: groupFacetsOtherInstance)
    
    filterState.add(filterNumeric1, to: groupNumerics)
    filterState.add(filterNumeric2, to: groupNumerics)
    // Repeat once to see if the Set rejects same filter
    filterState.add(filterNumeric2, to: groupNumerics)
    
    filterState.addAll(filters: [filterTag1, filterTag2], to: groupTagsOr)
    filterState.add(filterTag1, to: groupTagsAnd)
    
    let expectedState = """
                                    ( "category":"chair" OR "category":"table" ) AND ( "price" < 20.0 AND "price" > 10.0 ) AND ( "_tags":"Hank" OR "_tags":"Tom" ) AND "_tags":"Tom"
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
    
    filterState.addAll(filters: [tagA, tagB], to: .or(name: "tags"))
    
    filterState.addAll(filters: [Filter.Tag(value: "hm"), Filter.Tag(value: "other")], to: .or(name: "tags"))
    
    filterState.addAll(filters: [
      Filter.Numeric(attribute: "size", range: 15...20),
      Filter.Numeric(attribute: "price", operator: .greaterThan, value: 100)], to: .or(name: "numeric"))
    
    filterState.add(numeric, to: .and(name: "others"))
    filterState.add(facet, to: .and(name: "others"))
    filterState.add(Filter.Tag(value: "someTag"), to: .and(name: "some"))
    filterState.addAll(filters: [
      Filter.Numeric(attribute: "price", operator: .greaterThan, value: 20),
      Filter.Numeric(attribute: "size", range: 15...20)
    ], to: .and(name: "some"))
    filterState.addAll(filters: [
      Filter.Facet(attribute: "brand", stringValue: "apple"),
      Filter.Facet(attribute: "featured", boolValue: true),
      Filter.Facet(attribute: "rating", floatValue: 4)
    ], to: .and(name: "some"))
      
    XCTAssertTrue(filterState.contains(tagA))
    XCTAssertTrue(filterState.contains(tagB))
    XCTAssertTrue(filterState.contains(numeric))
    XCTAssertTrue(filterState.contains(facet))
    XCTAssertTrue(filterState.contains(tagA, in: .or(name: "tags")))
    XCTAssertTrue(filterState.contains(tagB, in: .or(name: "tags")))
    XCTAssertTrue(filterState.contains(numeric, in: .and(name: "others")))
    XCTAssertTrue(filterState.contains(facet, in: .and(name: "others")))
    
    XCTAssertFalse(filterState.contains(tagC))
    XCTAssertFalse(filterState.contains(Filter.Facet(attribute: "new", value: false)))
    XCTAssertFalse(filterState.contains(tagC, in: .or(name: "tags")))
    XCTAssertFalse(filterState.contains(tagA, in: .and(name: "others")))
    XCTAssertFalse(filterState.contains(tagB, in: .and(name: "others")))
    
    let expectedResult = """
        ( "price" > 100.0 OR "size":15.0 TO 20.0 ) AND ( "new":"true" AND "price" < 100.0 ) AND ( "_tags":"someTag" AND "brand":"apple" AND "featured":"true" AND "price" > 20.0 AND "rating":"4.0" AND "size":15.0 TO 20.0 ) AND ( "_tags":"A" OR "_tags":"B" OR "_tags":"hm" OR "_tags":"other" )
        """
    
    XCTAssertEqual(filterState.buildSQL(), expectedResult)
    
  }
  
  func testRemove() {
    
    let filterState = FilterState()
    
    filterState.addAll(filters: [Filter.Tag(value: "a"), Filter.Tag(value: "b")], to: .or(name: "orTags"))
    filterState.addAll(filters: [Filter.Tag(value: "a"), Filter.Tag(value: "b")], to: .and(name: "any"))
    filterState.add(Filter.Numeric(attribute: "price", range: 1...10), to: .and(name: "any"))
    
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
    
    XCTAssertTrue(filterState.remove(Filter.Tag(value: "b"), from: .and(name: "any")))
    
    XCTAssertTrue(filterState.contains(Filter.Tag(value: "b")))
    XCTAssertFalse(filterState.contains(Filter.Tag(value: "b"), in: .and(name: "any")))
    XCTAssertTrue(filterState.contains(Filter.Tag(value: "b"), in: .or(name: "orTags")))
    
    XCTAssertEqual(filterState.buildSQL(), """
        "price":1.0 TO 10.0 AND "_tags":"b"
        """)
    
    // Remove all from group
    filterState.removeAll(from: .and(name: "any"))
    XCTAssertTrue(filterState.getFilters(for: .and(name: "any")).isEmpty)
    
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
    
    filterState.add(filterFacet1, to: .or(name: "a"))
    filterState.remove(filterFacet2, from: .or(name: "a"))
    
    XCTAssertEqual(filterState.buildSQL(), """
        "category":"table"
        """)
    
    filterState.add(filterNumeric1, to: .and(name: "b"))
    filterState.add(filterTag1, to: .and(name: "b"))
    
    XCTAssertEqual(filterState.buildSQL(), """
        "category":"table" AND ( "_tags":"Tom" AND "price" > 10.0 )
        """)
    
    filterState.addAll(filters: [filterFacet1, filterFacet2], to: .or(name:"a"))
    
    XCTAssertEqual(filterState.buildSQL(), """
        ( "category":"chair" OR "category":"table" ) AND ( "_tags":"Tom" AND "price" > 10.0 )
        """)
    
    filterState.addAll(filters: [filterNumeric1, filterNumeric2], to: .and(name: "b"))
    
    XCTAssertEqual(filterState.buildSQL(), """
        ( "category":"chair" OR "category":"table" ) AND ( "_tags":"Tom" AND "price" < 20.0 AND "price" > 10.0 )
        """)
    
  }
  
  func testClearAttribute() {
    
    let filterNumeric1 = Filter.Numeric(attribute: "price", operator: .greaterThan, value: 10)
    let filterNumeric2 = Filter.Numeric(attribute: "price", operator: .lessThan, value: 20)
    let filterTag1 = Filter.Tag(value: "Tom")
    let filterTag2 = Filter.Tag(value: "Hank")
    
    let groupNumericsOr = FilterGroup.ID.or(name: "filterNumeric")
    let groupTagsOr = FilterGroup.ID.or(name: "filterTags")
    
    let filterState = FilterState()
    
    filterState.addAll(filters: [filterNumeric1, filterNumeric2], to: groupNumericsOr)
    XCTAssertEqual(filterState.buildSQL(), """
        ( "price" < 20.0 OR "price" > 10.0 )
        """)
    
    filterState.addAll(filters: [filterTag1, filterTag2], to: groupTagsOr)
    
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
    let group = FilterGroup.ID.or(name: "group")
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
    let group = FilterGroup.ID.and(name: "group")
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
    
    XCTAssertFalse(filterState.getFilters(for: .or(name: "a")).contains(.facet(filter)))
    XCTAssertTrue(filterState.getFilters(for: .or(name: "a")).isEmpty)
    
    filterState.toggle(filter, in: .or(name: "a"))
    XCTAssertTrue(filterState.getFilters(for: .or(name: "a")).contains(.facet(filter)))
    XCTAssertFalse(filterState.getFilters(for: .or(name: "a")).isEmpty)
    
    filterState.toggle(filter, in: .or(name: "a"))
    XCTAssertFalse(filterState.contains(filter, in: .or(name: "a")))
    XCTAssertTrue(filterState.getFilters(for: .or(name: "a")).isEmpty)
    
    // Disjunctive Group
    
    XCTAssertFalse(filterState.contains(filter, in: .and(name: "a")))
    XCTAssertTrue(filterState.getFilters(for: .and(name: "a")).isEmpty)
    
    filterState.toggle(filter, in: .and(name: "a"))
    XCTAssertTrue(filterState.getFilters(for: .and(name: "a")).contains(.facet(filter)))
    XCTAssertFalse(filterState.getFilters(for: .and(name: "a")).isEmpty)
    
    
    filterState.toggle(filter, in: .and(name: "a"))
    XCTAssertFalse(filterState.contains(filter, in: .and(name: "a")))
    XCTAssertTrue(filterState.getFilters(for: .and(name: "a")).isEmpty)
    
    filterState.toggle(Filter.Numeric(attribute: "size", operator: .equals, value: 40), in: .and(name: "a"))
    filterState.toggle(Filter.Facet(attribute: "country", stringValue: "france"), in: .and(name: "a"))
    
    XCTAssertFalse(filterState.getFilters(for: .and(name: "a")).isEmpty)
    XCTAssertTrue(filterState.getFilters(for: .and(name: "a")).contains(.numeric(Filter.Numeric(attribute: "size", operator: .equals, value: 40))))
    XCTAssertTrue(filterState.getFilters(for: .and(name: "a")).contains(.facet(Filter.Facet(attribute: "country", stringValue: "france"))))
    
    filterState.toggle(Filter.Numeric(attribute: "size", operator: .equals, value: 40), in: .and(name: "a"))
      filterState.toggle(Filter.Facet(attribute: "country", stringValue: "france"), in: .and(name: "a"))
    
    XCTAssertTrue(filterState.getFilters(for: .and(name: "a")).isEmpty)
    XCTAssertFalse(filterState.getFilters(for: .and(name: "a")).contains(.numeric(Filter.Numeric(attribute: "size", operator: .equals, value: 40))))
    XCTAssertFalse(filterState.getFilters(for: .and(name: "a")).contains(.facet(Filter.Facet(attribute: "country", stringValue: "france"))))
    
    
    filterState.toggle(Filter.Facet(attribute: "size", floatValue: 40), in: .or(name: "a"))
    filterState.toggle(Filter.Facet(attribute: "count", floatValue: 25), in: .or(name: "a"))
        
    XCTAssertFalse(filterState.getFilters(for: .or(name: "a")).isEmpty)
    XCTAssertTrue(filterState.getFilters(for: .or(name: "a")).contains(.facet(Filter.Facet(attribute: "size", floatValue: 40))))
    XCTAssertTrue(filterState.getFilters(for: .or(name: "a")).contains(.facet(Filter.Facet(attribute: "count", floatValue: 25))))
    
  }
  
  
  func testDisjunctiveFacetAttributes() {
    
    let filterState = FilterState()
    
    filterState.addAll(filters: [
      Filter.Facet(attribute: "color", stringValue: "red"),
      Filter.Facet(attribute: "color", stringValue: "green"),
      Filter.Facet(attribute: "color", stringValue: "blue")
    ], to: .or(name: "g1"))
    
    XCTAssertEqual(filterState.getDisjunctiveFacetsAttributes(), ["color"])
    
    filterState.add(Filter.Facet(attribute: "country", stringValue: "france"), to: .or(name: "g2"))
    
    XCTAssertEqual(filterState.getDisjunctiveFacetsAttributes(), ["color", "country"])
    
    filterState.add(Filter.Facet(attribute: "country", stringValue: "uk"), to: .or(name: "g2"))
    
    filterState.add(Filter.Facet(attribute: "size", floatValue: 40), to: .or(name: "g2"))
    
    XCTAssertEqual(filterState.getDisjunctiveFacetsAttributes(), ["color", "country", "size"])
    
    filterState.add(Filter.Numeric(attribute: "price", operator: .greaterThan, value: 50), to: .and(name: "g3"))
    filterState.add(Filter.Facet(attribute: "featured", boolValue: true), to: .and(name: "g3"))
    
    XCTAssertEqual(filterState.getDisjunctiveFacetsAttributes(), ["color", "country", "size"])
    
    filterState.add(Filter.Numeric(attribute: "price", operator: .lessThan, value: 100), to: .and(name: "g3"))
    
    XCTAssertEqual(filterState.getDisjunctiveFacetsAttributes(), ["color", "country", "size"])
    
    filterState.add(Filter.Facet(attribute: "size", floatValue: 42), to: .or(name: "g2"))
    
    XCTAssertEqual(filterState.getDisjunctiveFacetsAttributes(), ["color", "country", "size"])
    
    filterState.removeAll([
      Filter.Facet(attribute: "color", stringValue: "red"),
      Filter.Facet(attribute: "color", stringValue: "green"),
      Filter.Facet(attribute: "color", stringValue: "blue")
    ], from: .or(name: "g1"))
    
    XCTAssertEqual(filterState.getDisjunctiveFacetsAttributes(), ["country", "size"])
    
  }
  
  func testRefinements() {
    
    let filterState = FilterState()
    
    filterState.addAll(filters: [
      Filter.Facet(attribute: "color", stringValue: "red"),
      Filter.Facet(attribute: "color", stringValue: "green"),
      Filter.Facet(attribute: "color", stringValue: "blue"),
    ], to: .or(name: "g1"))
    
    XCTAssertEqual(filterState.getRawFacetFilters()["color"].flatMap(Set.init), Set(["red", "green", "blue"]))
    
    filterState.add(Filter.Facet(attribute: "country", stringValue: "france"), to: .or(name: "g2"))
    
    XCTAssertEqual(filterState.getRawFacetFilters()["color"].flatMap(Set.init), Set(["red", "green", "blue"]))
    XCTAssertEqual(filterState.getRawFacetFilters()["country"], ["france"])
    
    filterState.add(Filter.Facet(attribute: "country", stringValue: "uk"), to: .and(name: "g3"))
    
    XCTAssertEqual(filterState.getRawFacetFilters()["color"].flatMap(Set.init), Set(["red", "green", "blue"]))
    XCTAssertEqual(filterState.getRawFacetFilters()["country"].flatMap(Set.init), Set(["france", "uk"]))
    
    filterState.remove(Filter.Facet(attribute: "color", stringValue: "green"), from: .or(name: "g1"))
    
    XCTAssertEqual(filterState.getRawFacetFilters()["color"].flatMap(Set.init), Set(["red", "blue"]))
    XCTAssertEqual(filterState.getRawFacetFilters()["country"].flatMap(Set.init), Set(["france", "uk"]))
    
  }
  
  func testFilterScoring() {
    
    let filterState = FilterState()
    
    let filterFacet1 = Filter.Facet(attribute: Attribute("category"), value: "table", score: 5)
    let filterFacet2 = Filter.Facet(attribute: Attribute("category"), value: "chair", score: 10)
    
    let groupFacets = FilterGroup.ID.or(name: "filterFacets")
    
    filterState.add(filterFacet1, to: groupFacets)
    filterState.add(filterFacet2, to: groupFacets)
    
    let expectedResult = """
                                    ( "category":"chair<score=10>" OR "category":"table<score=5>" )
                                    """
    
    XCTAssertEqual(filterState.buildSQL(), expectedResult)
    
  }
  
}
