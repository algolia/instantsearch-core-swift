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

class RefinementListBuilderTests: XCTestCase {

  lazy var facetValues: [FacetValue] = {
    var values: [FacetValue] = []
    values.append(FacetValue(value: "red", count: 10, highlighted: nil))
    values.append(FacetValue(value: "orange", count: 20, highlighted: nil))
    values.append(FacetValue(value: "yellow", count: 30, highlighted: nil))
    values.append(FacetValue(value: "black", count: 5, highlighted: nil))
    values.append(FacetValue(value: "blue", count: 40, highlighted: nil))
    return values
  }()

  let refinedValues = ["orange", "red", "green"]
  let refinementListBuilder = RefinementListBuilder()

  func testCountDescRefined() {

    var expectedList: [FacetValue] = []
    expectedList.append(FacetValue(value: "orange", count: 20, highlighted: nil))
    expectedList.append(FacetValue(value: "red", count: 10, highlighted: nil))
    expectedList.append(FacetValue(value: "green", count: 0, highlighted: nil)) // Show refined first

    expectedList.append(FacetValue(value: "blue", count: 40, highlighted: nil))
    expectedList.append(FacetValue(value: "yellow", count: 30, highlighted: nil))
    expectedList.append(FacetValue(value: "black", count: 5, highlighted: nil))

    let actualList: [FacetValue] = refinementListBuilder.getRefinementList(refinementValues: refinedValues, facetValues: facetValues, sorting: .countDesc, areRefinedValuesFirst: true)

    XCTAssertEqual(expectedList, actualList)
  }

  func testCountDescNotRefined() {

    var expectedList: [FacetValue] = []
    expectedList.append(FacetValue(value: "blue", count: 40, highlighted: nil))
    expectedList.append(FacetValue(value: "yellow", count: 30, highlighted: nil))
    expectedList.append(FacetValue(value: "orange", count: 20, highlighted: nil))
    expectedList.append(FacetValue(value: "red", count: 10, highlighted: nil))
    expectedList.append(FacetValue(value: "black", count: 5, highlighted: nil))
    expectedList.append(FacetValue(value: "green", count: 0, highlighted: nil))

    let actualList: [FacetValue] = refinementListBuilder.getRefinementList(refinementValues: refinedValues, facetValues: facetValues, sorting: .countDesc, areRefinedValuesFirst: false)

    XCTAssertEqual(expectedList, actualList)
  }

  func testCountAscRefined() {

    var expectedList: [FacetValue] = []
    expectedList.append(FacetValue(value: "green", count: 0, highlighted: nil))
    expectedList.append(FacetValue(value: "red", count: 10, highlighted: nil))
    expectedList.append(FacetValue(value: "orange", count: 20, highlighted: nil)) // Show refined first

    expectedList.append(FacetValue(value: "black", count: 5, highlighted: nil))
    expectedList.append(FacetValue(value: "yellow", count: 30, highlighted: nil))
    expectedList.append(FacetValue(value: "blue", count: 40, highlighted: nil))

    let actualList: [FacetValue] = refinementListBuilder.getRefinementList(refinementValues: refinedValues, facetValues: facetValues, sorting: .countAsc, areRefinedValuesFirst: true)

    XCTAssertEqual(expectedList, actualList)
  }

  func testCountAscNotRefined() {

    var expectedList: [FacetValue] = []
    expectedList.append(FacetValue(value: "green", count: 0, highlighted: nil))
    expectedList.append(FacetValue(value: "black", count: 5, highlighted: nil))
    expectedList.append(FacetValue(value: "red", count: 10, highlighted: nil))
    expectedList.append(FacetValue(value: "orange", count: 20, highlighted: nil))
    expectedList.append(FacetValue(value: "yellow", count: 30, highlighted: nil))
    expectedList.append(FacetValue(value: "blue", count: 40, highlighted: nil))

    let actualList: [FacetValue] = refinementListBuilder.getRefinementList(refinementValues: refinedValues, facetValues: facetValues, sorting: .countAsc, areRefinedValuesFirst: false)

    XCTAssertEqual(expectedList, actualList)
  }

  func testNameAscRefined() {

    var expectedList: [FacetValue] = []

    expectedList.append(FacetValue(value: "green", count: 0, highlighted: nil))
    expectedList.append(FacetValue(value: "orange", count: 20, highlighted: nil))
    expectedList.append(FacetValue(value: "red", count: 10, highlighted: nil)) // Show refined first

    expectedList.append(FacetValue(value: "black", count: 5, highlighted: nil))
    expectedList.append(FacetValue(value: "blue", count: 40, highlighted: nil))
    expectedList.append(FacetValue(value: "yellow", count: 30, highlighted: nil))

    let actualList: [FacetValue] = refinementListBuilder.getRefinementList(refinementValues: refinedValues, facetValues: facetValues, sorting: .nameAsc, areRefinedValuesFirst: true)

    XCTAssertEqual(expectedList, actualList)
  }

  func testNameAscNotRefined() {

    var expectedList: [FacetValue] = []

    expectedList.append(FacetValue(value: "black", count: 5, highlighted: nil))
    expectedList.append(FacetValue(value: "blue", count: 40, highlighted: nil))
    expectedList.append(FacetValue(value: "green", count: 0, highlighted: nil))
    expectedList.append(FacetValue(value: "orange", count: 20, highlighted: nil))
    expectedList.append(FacetValue(value: "red", count: 10, highlighted: nil))
    expectedList.append(FacetValue(value: "yellow", count: 30, highlighted: nil))

    let actualList: [FacetValue] = refinementListBuilder.getRefinementList(refinementValues: refinedValues, facetValues: facetValues, sorting: .nameAsc, areRefinedValuesFirst: false)

    XCTAssertEqual(expectedList, actualList)
  }

  func testNameDescRefined() {
    var expectedList: [FacetValue] = []

    expectedList.append(FacetValue(value: "red", count: 10, highlighted: nil))
    expectedList.append(FacetValue(value: "orange", count: 20, highlighted: nil))
    expectedList.append(FacetValue(value: "green", count: 0, highlighted: nil)) // Show refined first


    expectedList.append(FacetValue(value: "yellow", count: 30, highlighted: nil))
    expectedList.append(FacetValue(value: "blue", count: 40, highlighted: nil))
    expectedList.append(FacetValue(value: "black", count: 5, highlighted: nil))

    let actualList: [FacetValue] = refinementListBuilder.getRefinementList(refinementValues: refinedValues, facetValues: facetValues, sorting: .nameDesc, areRefinedValuesFirst: true)

    XCTAssertEqual(expectedList, actualList)
  }

  func testNameDescNotRefined() {
    var expectedList: [FacetValue] = []

    expectedList.append(FacetValue(value: "yellow", count: 30, highlighted: nil))
    expectedList.append(FacetValue(value: "red", count: 10, highlighted: nil))
    expectedList.append(FacetValue(value: "orange", count: 20, highlighted: nil))
    expectedList.append(FacetValue(value: "green", count: 0, highlighted: nil))
    expectedList.append(FacetValue(value: "blue", count: 40, highlighted: nil))
    expectedList.append(FacetValue(value: "black", count: 5, highlighted: nil))

    let actualList: [FacetValue] = refinementListBuilder.getRefinementList(refinementValues: refinedValues, facetValues: facetValues, sorting: .nameDesc, areRefinedValuesFirst: false)

    XCTAssertEqual(expectedList, actualList)
  }

  func testMergeWithFacetAndRefinementValues() {
    let actualList = refinementListBuilder.merge(facetValues, withRefinementValues: refinedValues)

    var expectedList: [FacetValue] = []
    expectedList.append(contentsOf: facetValues)
    expectedList.append(FacetValue(value: "green", count: 0, highlighted: nil)) // The missing one, put count 0

    XCTAssertEqual(expectedList, actualList)
  }

  func testMergeWithRefinementValues() {
    let actualList = refinementListBuilder.merge([], withRefinementValues: refinedValues)

    var expectedList: [FacetValue] = []
    expectedList.append(FacetValue(value: "orange", count: 0, highlighted: nil))
    expectedList.append(FacetValue(value: "red", count: 0, highlighted: nil))
    expectedList.append(FacetValue(value: "green", count: 0, highlighted: nil)) // The missing one, put count 0

    XCTAssertEqual(expectedList, actualList)
  }

  func testMergeWithFacetValues() {
    let actualList = refinementListBuilder.merge(facetValues, withRefinementValues: [])

    var expectedList: [FacetValue] = []
    expectedList.append(contentsOf: facetValues)

    XCTAssertEqual(expectedList, actualList)
  }

  func testMergeWithEmptyValues() {
    let actualList = refinementListBuilder.merge([], withRefinementValues: [])

    let expectedList: [FacetValue] = []

    XCTAssertEqual(expectedList, actualList)
  }
}
