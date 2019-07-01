//
//  DisjunctiveFacetingsTests.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 26/06/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation
import XCTest
@testable import InstantSearchCore

class DisjunctiveFacetingTests: XCTestCase {
  
  class TestDelegate: DisjunctiveFacetingDelegate {
    
    let disjunctiveFacetsAttributes: Set<Attribute>
    let filterList: [FilterType]
    
    init(disjunctiveFacetsAttributes: Set<Attribute>, filterList: [FilterType]) {
      self.disjunctiveFacetsAttributes = disjunctiveFacetsAttributes
      self.filterList = filterList
    }
    
  }
  
  
  func testBuildAndQuery() {
    let query = Query()
    let filtersAnd: [FilterType] = [
      Filter.Facet(attribute: "f1", boolValue: true),
      Filter.Tag(value: "t1"),
      Filter.Numeric(attribute: "n1", range: 1...10)
    ]
    let filtersOr: [FilterType] = [
      Filter.Facet(attribute: "of1", boolValue: true),
      Filter.Facet(attribute: "of2", stringValue: "of2v"),
      Filter.Numeric(attribute: "on1", range: 1...10),
      Filter.Numeric(attribute: "on2", operator: .greaterThan, value: 10),
      Filter.Tag(value: "ot1"),
      Filter.Tag(value: "ot2")
    ]
    let andQuery = DisjunctiveFacetingHelper.buildAndQuery(query: query, filtersAnd: filtersAnd, filtersOr: filtersOr)
    let expectedFilters = """
    ( "f1":"true" AND "_tags":"t1" AND "n1":1.0 TO 10.0 ) AND ( "of1":"true" OR "of2":\"of2v\" ) AND ( "on1":1.0 TO 10.0 OR "on2" > 10.0 ) AND ( "_tags":"ot1" OR "_tags":"ot2" )
    """
    XCTAssertEqual(andQuery.filters, expectedFilters)
  }
  
  func testBuildOrQueries() {
    let query = Query()
    let filtersAnd: [FilterType] = [
      Filter.Facet(attribute: "f1", boolValue: true),
      Filter.Tag(value: "t1"),
      Filter.Numeric(attribute: "n1", range: 1...10)
    ]
    let filtersOr: [FilterType] = [
      Filter.Facet(attribute: "of1", boolValue: true),
      Filter.Facet(attribute: "of2", stringValue: "of2v"),
      Filter.Facet(attribute: "of3", floatValue: 50),
      Filter.Numeric(attribute: "on1", range: 1...10),
      Filter.Numeric(attribute: "on2", operator: .greaterThan, value: 10),
      Filter.Tag(value: "ot1"),
      Filter.Tag(value: "ot2")
    ]
    let orQueries = DisjunctiveFacetingHelper.buildOrQueries(query: query, filtersAnd: filtersAnd, filtersOr: filtersOr, disjunctiveFacets: ["of1", "of2"])
    
    XCTAssertEqual(orQueries.count, 2)
    
    if let query1 = orQueries.first(where: { $0.facets == ["of1"] }) {
      let expectedFilters = """
      ( "f1":"true" AND "_tags":"t1" AND "n1":1.0 TO 10.0 ) AND ( "of2":"of2v" OR "of3":"50.0" ) AND ( "on1":1.0 TO 10.0 OR "on2" > 10.0 ) AND ( "_tags":"ot1" OR "_tags":"ot2" )
      """
      XCTAssertEqual(query1.filters, expectedFilters)
    } else {
      XCTFail("Missing query with facet \"of1\"")
    }
    
    if let query2 = orQueries.first(where: { $0.facets == ["of2"] }) {
      let expectedFilters = """
      ( "f1":"true" AND "_tags":"t1" AND "n1":1.0 TO 10.0 ) AND ( "of1":"true" OR "of3":"50.0" ) AND ( "on1":1.0 TO 10.0 OR "on2" > 10.0 ) AND ( "_tags":"ot1" OR "_tags":"ot2" )
      """
      XCTAssertEqual(query2.filters, expectedFilters)
    } else {
      XCTFail("Missing query with facet \"of2\"")
    }

  }
  
  func testBuildQueriesRaw() {
    let disjunctiveFacets: Set<Attribute> = ["color", "size"]
    let filters: [FilterType] = [
      Filter.Facet(attribute: "color", stringValue: "red"),
      Filter.Facet(attribute: "color", stringValue: "blue"),
      Filter.Facet(attribute: "size", floatValue: 42),
      Filter.Facet(attribute: "size", floatValue: 44),
      Filter.Tag(value: "promo"),
    ]
    buildQueries(disjunctiveFacets: disjunctiveFacets, filters: filters)
  }
  
  func testBuildQueriesWithDelegate() {
    let disjunctiveFacets: Set<Attribute> = ["color", "size"]
    let filters: [FilterType] = [
      Filter.Facet(attribute: "color", stringValue: "red"),
      Filter.Facet(attribute: "color", stringValue: "blue"),
      Filter.Facet(attribute: "size", floatValue: 42),
      Filter.Facet(attribute: "size", floatValue: 44),
      Filter.Tag(value: "promo"),
    ]
    let delegate = TestDelegate(disjunctiveFacetsAttributes: disjunctiveFacets, filterList: filters)
    buildQueries(disjunctiveFacets: delegate.disjunctiveFacetsAttributes, filters: delegate.filterList)
  }
  
  func buildQueries(disjunctiveFacets: Set<Attribute>, filters: [FilterType]) {
    
    let query = Query()
    query.query = "t-shirt"
    
    let queries = DisjunctiveFacetingHelper.buildQueries(with: query, disjunctiveFacets: disjunctiveFacets, filters: filters)
    
    XCTAssertEqual(queries.count, 3)
    
    let andQuery = queries.first!
    XCTAssertNil(andQuery.facets)
    XCTAssertEqual(andQuery.filters, """
    ( "_tags":"promo" ) AND ( "color":"red" OR "color":"blue" OR "size":"42.0" OR "size":"44.0" )
    """)
    
    for query in queries[1...] {
      switch query.facets {
      case ["size"]:
        XCTAssertEqual(query.filters, """
        ( "_tags":"promo" ) AND ( "color":"red" OR "color":"blue" )
        """)

      case ["color"]:
        XCTAssertEqual(query.filters, """
        ( "_tags":"promo" ) AND ( "size":"42.0" OR "size":"44.0" )
        """)

      default:
        XCTFail("Unexpected case")
      }
    }
    
  }
  
  func testMergeResults() {
    
    let res1 = try! SearchResults(jsonFile: "DisjFacetingResult1", bundle: Bundle(for: DisjunctiveFacetingTests.self))
    let res2 = try! SearchResults(jsonFile: "DisjFacetingResult2", bundle: Bundle(for: DisjunctiveFacetingTests.self))
    let res3 = try! SearchResults(jsonFile: "DisjFacetingResult3", bundle: Bundle(for: DisjunctiveFacetingTests.self))
    
    let output = DisjunctiveFacetingHelper.mergeResults([res1, res2, res3])
    
    XCTAssertEqual(output.facetStats?.count, 2)
    XCTAssertEqual(output.disjunctiveFacets?.count, 2)
    XCTAssertEqual(output.disjunctiveFacets?.map { $0.key }.contains("price"), true)
    XCTAssertEqual(output.disjunctiveFacets?.map { $0.key }.contains("pubYear"), true)

  }
  
}
