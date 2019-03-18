//
//  RefinementListViewModelTests.swift
//  InstantSearchCore
//
//  Created by Guy Daher on 18/03/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

@testable import InstantSearchCore
import XCTest

class RefinementListViewModelTests: XCTestCase {
  func testRefinementListBuilder() {
    let refinementListBuilder = RefinementListBuilder()

    let attribute = Attribute("color")
    let randomAttribute = Attribute("randomAttribute")

    var refinedFacets = Set<FilterFacet>()
    refinedFacets.insert(FilterFacet(attribute: attribute, stringValue: "orange"))
    refinedFacets.insert(FilterFacet(attribute: attribute, stringValue: "red"))
    refinedFacets.insert(FilterFacet(attribute: attribute, stringValue: "green"))
    refinedFacets.insert(FilterFacet(attribute: randomAttribute, stringValue: "randomValue"))

    var facetValues: [FacetValue] = []
    facetValues.append(FacetValue(value: "red", count: 10, highlighted: nil))
    facetValues.append(FacetValue(value: "orange", count: 20, highlighted: nil))
    facetValues.append(FacetValue(value: "yellow", count: 30, highlighted: nil))
    facetValues.append(FacetValue(value: "black", count: 5, highlighted: nil))
    facetValues.append(FacetValue(value: "blue", count: 40, highlighted: nil))
    let sorting: RefinementListViewModel.Sorting = .countDesc

    var expectedList: [FacetValue] = []
    expectedList.append(FacetValue(value: "orange", count: 20, highlighted: nil))
    expectedList.append(FacetValue(value: "red", count: 10, highlighted: nil))
    expectedList.append(FacetValue(value: "green", count: 0, highlighted: nil))
    expectedList.append(FacetValue(value: "blue", count: 40, highlighted: nil))
    expectedList.append(FacetValue(value: "yellow", count: 30, highlighted: nil))
    expectedList.append(FacetValue(value: "black", count: 5, highlighted: nil))

    let actualList: [FacetValue] = refinementListBuilder.getRefinementList(on: attribute, refinedFilterFacets: refinedFacets, facetValues: facetValues, sorting: sorting)

    XCTAssertEqual(expectedList.count, actualList.count)
  }
}
