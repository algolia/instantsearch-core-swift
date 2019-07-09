//
//  DisjunctiveFacetingIntegrationTests.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 04/07/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation
import XCTest
@testable import InstantSearchCore

class DisjunctiveFacetingIntegrationTests: OnlineTestCase {

  struct Item: Codable {
    let objectID: String = UUID().uuidString
    let category: String
    let color: String?
    let promotions: EitherSingleOrList<String>?
  }
  
  let disjunctiveAttributes: [Attribute] = [
    "category",
    "color",
    "promotions"
  ]
  
  override func setUp() {
    super.setUp()
    let exp = expectation(description: "wait for filling the index")
    let settings: [String: Any] = ["attributesForFaceting": disjunctiveAttributes.map { $0.name }]
    let items = try! [Item](jsonFile: "disjunctive", bundle: Bundle(for: HierarchicalTests.self))
    fillIndex(withItems: items, settings: settings, completionHandler: exp.fulfill)
    waitForExpectations(timeout: 50, handler: .none)
  }
  
  func testDisjunctive() {
    
    let expectedFacets: [(Attribute, [Facet])] = [
      ("category", [
        .init(value: "shirt", count: 2, highlighted: nil),
        .init(value: "hat", count: 1, highlighted: nil),
        ]),
      ("promotions", [
        .init(value: "free return", count: 2, highlighted: nil),
        .init(value: "coupon", count: 1, highlighted: nil),
        .init(value: "on sale", count: 1, highlighted: nil),
      ])
    ]
    
    let expectedDisjucntiveFacets: [(Attribute, [Facet])] = [
      ("color", [
        .init(value: "blue", count: 3, highlighted: nil),
        .init(value: "green", count: 2, highlighted: nil),
        .init(value: "orange", count: 2, highlighted: nil),
        .init(value: "yellow", count: 2, highlighted: nil),
        .init(value: "red", count: 1, highlighted: nil),
      ])
    ]
    
    let query = Query()
    query.facets = disjunctiveAttributes.map { $0.name }
    let colorFilter = Filter.Facet(attribute: "color", stringValue: "blue")
    let disjunctiveGroup = FilterGroup.Or(filters: [colorFilter], name: "colors")
    let queryBuilder = QueryBuilder(query: query, filterGroups: [disjunctiveGroup])
    
    let queries = queryBuilder.build()
    
    XCTAssertEqual(queries.count, 2)
    XCTAssertEqual(queryBuilder.disjunctiveFacetingQueriesCount, 1)
    
    let exp = expectation(description: "results")
    
    index.multipleQueries(queries) { (result, error) in
      self.extract(result, error) { (results: MultiSearchResults) in
        let finalResult = try! queryBuilder.aggregate(results.searchResults)
        expectedFacets.forEach { (attribute, facets) in
          XCTAssertTrue(finalResult.facets?[attribute]?.equalContents(to: facets) == true)
        }
        expectedDisjucntiveFacets.forEach { (attribute, facets) in
          XCTAssertTrue(finalResult.disjunctiveFacets?[attribute]?.equalContents(to: facets) == true)
        }
        exp.fulfill()
      }
    }
    
    waitForExpectations(timeout: 15, handler: .none)

  }
  
  func testMultiDisjunctive() {
    
    let expectedFacets: [(Attribute, [Facet])] = [
      ("category", [
        .init(value: "shirt", count: 1, highlighted: nil),
        ]),
      ("promotions", [
        .init(value: "coupon", count: 1, highlighted: nil),
        ])
    ]
    
    let expectedDisjucntiveFacets: [(Attribute, [Facet])] = [
      ("color", [
        .init(value: "blue", count: 1, highlighted: nil),
        ])
    ]
    
    let query = Query()
    query.facets = disjunctiveAttributes.map { $0.name }
    let colorFilter = Filter.Facet(attribute: "color", stringValue: "blue")
    let disjunctiveGroup = FilterGroup.Or(filters: [colorFilter], name: "colors")
    let promotionsFilter = Filter.Facet(attribute: "promotions", stringValue: "coupon")
    let conjunctiveGroup = FilterGroup.And(filters: [promotionsFilter], name: "promotions")
    let queryBuilder = QueryBuilder(query: query, filterGroups: [disjunctiveGroup, conjunctiveGroup])
    
    let queries = queryBuilder.build()
    
    XCTAssertEqual(queries.count, 2)
    XCTAssertEqual(queryBuilder.disjunctiveFacetingQueriesCount, 1)
    
    let exp = expectation(description: "results")
    
    index.multipleQueries(queries) { (result, error) in
      self.extract(result, error) { (results: MultiSearchResults) in
        let finalResult = try! queryBuilder.aggregate(results.searchResults)
        expectedFacets.forEach { (attribute, facets) in
          XCTAssertTrue(finalResult.facets?[attribute]?.equalContents(to: facets) == true)
        }
        expectedDisjucntiveFacets.forEach { (attribute, facets) in
          XCTAssertTrue(finalResult.disjunctiveFacets?[attribute]?.equalContents(to: facets) == true)
        }
        exp.fulfill()
      }
    }
    
    waitForExpectations(timeout: 15, handler: .none)
    
  }

  
}
