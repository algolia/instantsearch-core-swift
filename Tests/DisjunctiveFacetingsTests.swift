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
    let filterGroups: [FilterGroupType]
    
    init(disjunctiveFacetsAttributes: Set<Attribute>, filterGroups: [FilterGroupType]) {
      self.disjunctiveFacetsAttributes = disjunctiveFacetsAttributes
      self.filterGroups = filterGroups
    }
    
    func toFilterGroups() -> [FilterGroupType] {
      return filterGroups
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
  
  func testMultipleDisjunctiveGroupsOfSameType() {
    
    let query = Query()
    
    let colorGroup = FilterGroup.Or<Filter.Facet>(filters: [.init(attribute: "color", stringValue: "red"), .init(attribute: "color", stringValue: "green")], name: "color")
    let sizeGroup = FilterGroup.Or<Filter.Facet>(filters: [.init(attribute: "size", stringValue: "m"), .init(attribute: "size", stringValue: "s")], name: "size")

    let filterGroups: [FilterGroupType] = [colorGroup, sizeGroup]
    
    let disjunctiveFacets = Set([colorGroup.name, sizeGroup.name].compactMap { $0 }.map(Attribute.init(rawValue:)))
    let queries = DisjunctiveFacetingHelper.buildQueries(with: query, disjunctiveFacets: disjunctiveFacets, filterGroups: filterGroups)
    
    let andQuery = queries.first!
    XCTAssertNil(andQuery.facets)
    XCTAssertEqual(andQuery.filters, """
    ( "color":"red" OR "color":"green" ) AND ( "size":"m" OR "size":"s" )
    """)

    for query in queries[1...] {
      switch query.facets {
      case ["size"]:
        XCTAssertEqual(query.filters, """
        ( "color":"red" OR "color":"green" )
        """)
        
      case ["color"]:
        XCTAssertEqual(query.filters, """
        ( "size":"m" OR "size":"s" )
        """)
        
      default:
        XCTFail("Unexpected case")
      }
    }
    
  }
  
}
