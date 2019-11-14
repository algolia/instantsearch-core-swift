//
//  HierarchicalIntegrationTests.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 02/07/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation
import XCTest
@testable import InstantSearchCore

class HierarchicalTests: OnlineTestCase {
  
  struct Item: Codable {
    let objectID: String = UUID().uuidString
    let name: String
    let hierarchicalCategories: [String: String]
  }
  
  static func attribute(for level: Int) -> Attribute {
    return .init("hierarchicalCategories.lvl\(level)")
  }
  
  let lvl0 = { attribute(for: 0) }()
  let lvl1 = { attribute(for: 1) }()
  let lvl2 = { attribute(for: 2) }()
  var hierarchicalAttributes: [Attribute] {
    return [lvl0, lvl1, lvl2]
  }
  
  let clothing = "Clothing"
  let book = "Book"
  let furniture = "Furniture"
  
  let clothing_men = "Clothing > Men"
  let clothing_women = "Clothing > Women"
  
  let clothing_men_hats = "Clothing > Men > Hats"
  let clothing_men_shirt = "Clothing > Men > Shirt"
  
  override func setUp() {
    super.setUp()
    let exp = expectation(description: "wait for filling the index")
    let settings: [String: Any] = ["attributesForFaceting": hierarchicalAttributes.map { $0.name }]
    let items = try! [Item](jsonFile: "hierarchical", bundle: Bundle(for: HierarchicalTests.self))
    fillIndex(withItems: items, settings: settings, completionHandler: exp.fulfill)
    waitForExpectations(timeout: 50, handler: .none)
  }
  
  func testHierachical() {
    
    let filter = Filter.Facet(attribute: lvl1, stringValue: clothing_men)
    
    let filterGroups = [FilterGroup.And(filters: [filter], name: "_hierarchical")]
    
    let hierarchicalFilters = [
      Filter.Facet(attribute: lvl0, stringValue: clothing),
      Filter.Facet(attribute: lvl1, stringValue: clothing_men)
    ]
    
    let expectedHierarchicalFacets: [(Attribute, [Facet])] = [
      (lvl0, [
        .init(value: clothing, count: 4, highlighted: nil),
        .init(value: book, count: 2, highlighted: nil),
        .init(value: furniture, count: 1, highlighted: nil)
        ]),
      (lvl1, [
        .init(value: clothing_men, count: 2, highlighted: nil),
        .init(value: clothing_women, count: 2, highlighted: nil),
        ]),
      (lvl2, [
        .init(value: clothing_men_hats, count: 1, highlighted: nil),
        .init(value: clothing_men_shirt, count: 1, highlighted: nil),
        ])
    ]
    
    
    let query = Query(query: "")
    query.facets = hierarchicalAttributes.map { $0.name }
    let queryBuilder = QueryBuilder(query: query,
                                           filterGroups: filterGroups,
                                           hierarchicalAttributes: hierarchicalAttributes,
                                           hierachicalFilters: hierarchicalFilters)
    let queries = queryBuilder.build().map { IndexQuery(index: self.index, query: $0) }
    
    XCTAssertEqual(queryBuilder.hierarchicalFacetingQueriesCount, 3)
    
    let exp = expectation(description: "results")
    
    client!.multipleQueries(queries) { (result, error) in
      self.extract(result, error) { (results: MultiSearchResults) in
        let finalResult = try! queryBuilder.aggregate(results.searchResults)
        expectedHierarchicalFacets.forEach { (attribute, facets) in
          XCTAssertTrue(finalResult.hierarchicalFacets?[attribute]?.equalContents(to: facets) == true)
        }
        exp.fulfill()
      }
    }
    
    
    waitForExpectations(timeout: 15, handler: .none)
    
  }
  
  func testHierachicalEmpty() {
    
    let filterGroups: [FilterGroupType] = []
    
    let hierarchicalFilters: [Filter.Facet] = []
    
    let query = Query(query: "")
    query.facets = hierarchicalAttributes.map { $0.name }
    let queryBuilder = QueryBuilder(query: query,
                                           filterGroups: filterGroups,
                                           hierarchicalAttributes: hierarchicalAttributes,
                                           hierachicalFilters: hierarchicalFilters)
    let queries = queryBuilder.build().map { IndexQuery(index: self.index, query: $0) }
    
    XCTAssertEqual(queryBuilder.hierarchicalFacetingQueriesCount, 0)
    
    let exp = expectation(description: "results")
    
    client!.multipleQueries(queries) { (result, error) in
      self.extract(result, error) { (results: MultiSearchResults) in
        let finalResult = try! queryBuilder.aggregate(results.searchResults)
        XCTAssertNil(finalResult.hierarchicalFacets)
        exp.fulfill()
      }
    }
    
    waitForExpectations(timeout: 15, handler: .none)
    
  }
  
  func testHierarchicalLastLevel() {
    
    let filter = Filter.Facet(attribute: lvl2, stringValue: clothing_men_hats)
    
    let filterGroups = [FilterGroup.And(filters: [filter], name: "_hierarchical")]
    
    let hierarchicalFilters = [
      Filter.Facet(attribute: lvl0, stringValue: clothing),
      Filter.Facet(attribute: lvl1, stringValue: clothing_men),
      Filter.Facet(attribute: lvl2, stringValue: clothing_men_hats)
    ]
    
    let expectedHierarchicalFacets: [(Attribute, [Facet])] = [
      (lvl0, [
        .init(value: clothing, count: 4, highlighted: nil),
        .init(value: book, count: 2, highlighted: nil),
        .init(value: furniture, count: 1, highlighted: nil)
        ]),
      (lvl1, [
        .init(value: clothing_men, count: 2, highlighted: nil),
        .init(value: clothing_women, count: 2, highlighted: nil),
        ]),
      (lvl2, [
        .init(value: clothing_men_hats, count: 1, highlighted: nil),
        .init(value: clothing_men_shirt, count: 1, highlighted: nil),
        ])
    ]
    
    
    let query = Query(query: "")
    query.facets = hierarchicalAttributes.map { $0.name }
    let queryBuilder = QueryBuilder(query: query,
                                           filterGroups: filterGroups,
                                           hierarchicalAttributes: hierarchicalAttributes,
                                           hierachicalFilters: hierarchicalFilters)
    let queries = queryBuilder.build().map { IndexQuery(index: self.index, query: $0) }
    
    XCTAssertEqual(queryBuilder.hierarchicalFacetingQueriesCount, 3)
    
    let exp = expectation(description: "results")
    
    client!.multipleQueries(queries) { (result, error) in
      self.extract(result, error) { (results: MultiSearchResults) in
        let finalResult = try! queryBuilder.aggregate(results.searchResults)
        expectedHierarchicalFacets.forEach { (attribute, facets) in
          XCTAssertTrue(finalResult.hierarchicalFacets?[attribute]?.equalContents(to: facets) == true)
        }
        exp.fulfill()
      }
    }
      
    waitForExpectations(timeout: 15, handler: .none)
    
  }
  
}

extension Array where Element: Equatable {
  func equalContents(to other: [Element]) -> Bool {
    guard self.count == other.count else { return false }
    for e in self {
      let currentECount = filter { $0 == e }.count
      let otherECount = other.filter { $0 == e }.count
      guard currentECount == otherECount else {
        return false
      }
    }
    return true
  }
}
