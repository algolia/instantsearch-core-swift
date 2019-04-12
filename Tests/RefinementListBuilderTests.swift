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

  let selectedValues = ["orange", "red", "green"]
  let refinementListBuilder = RefinementListPresenter()

  func testCountDescSelectedOnTop() {

    var expectedList: [FacetValue] = []
    expectedList.append(FacetValue(value: "orange", count: 20, highlighted: nil))
    expectedList.append(FacetValue(value: "red", count: 10, highlighted: nil))
    expectedList.append(FacetValue(value: "green", count: 0, highlighted: nil)) // Show selected first

    expectedList.append(FacetValue(value: "blue", count: 40, highlighted: nil))
    expectedList.append(FacetValue(value: "yellow", count: 30, highlighted: nil))
    expectedList.append(FacetValue(value: "black", count: 5, highlighted: nil))

    let actualList: [FacetValue] = refinementListBuilder.getRefinementList(selectedValues: selectedValues,
                                                                           resultValues: facetValues,
                                                                           sorting: .count(order: .descending),
                                                                           showSelectedValuesOnTop: true,
                                                                           keepSelectedValuesWithZeroCount: true)

    XCTAssertEqual(expectedList, actualList)
  }

  func testCountDescNotSelectedOnTop() {

    var expectedList: [FacetValue] = []
    expectedList.append(FacetValue(value: "blue", count: 40, highlighted: nil))
    expectedList.append(FacetValue(value: "yellow", count: 30, highlighted: nil))
    expectedList.append(FacetValue(value: "orange", count: 20, highlighted: nil))
    expectedList.append(FacetValue(value: "red", count: 10, highlighted: nil))
    expectedList.append(FacetValue(value: "black", count: 5, highlighted: nil))
    expectedList.append(FacetValue(value: "green", count: 0, highlighted: nil))

    let actualList: [FacetValue] = refinementListBuilder.getRefinementList(selectedValues: selectedValues,
                                                                           resultValues: facetValues,
                                                                           sorting: .count(order: .descending),
                                                                           showSelectedValuesOnTop: false,
                                                                           keepSelectedValuesWithZeroCount: true)

    XCTAssertEqual(expectedList, actualList)
  }

  func testCountAscSelectedOnTop() {

    var expectedList: [FacetValue] = []
    expectedList.append(FacetValue(value: "green", count: 0, highlighted: nil))
    expectedList.append(FacetValue(value: "red", count: 10, highlighted: nil))
    expectedList.append(FacetValue(value: "orange", count: 20, highlighted: nil)) // Show selected first

    expectedList.append(FacetValue(value: "black", count: 5, highlighted: nil))
    expectedList.append(FacetValue(value: "yellow", count: 30, highlighted: nil))
    expectedList.append(FacetValue(value: "blue", count: 40, highlighted: nil))

    let actualList: [FacetValue] = refinementListBuilder.getRefinementList(selectedValues: selectedValues,
                                                                           resultValues: facetValues,
                                                                           sorting: .count(order: .ascending),
                                                                           showSelectedValuesOnTop: true,
                                                                           keepSelectedValuesWithZeroCount: true)

    XCTAssertEqual(expectedList, actualList)
  }

  func testCountAscNotSelectedOnTop() {

    var expectedList: [FacetValue] = []
    expectedList.append(FacetValue(value: "green", count: 0, highlighted: nil))
    expectedList.append(FacetValue(value: "black", count: 5, highlighted: nil))
    expectedList.append(FacetValue(value: "red", count: 10, highlighted: nil))
    expectedList.append(FacetValue(value: "orange", count: 20, highlighted: nil))
    expectedList.append(FacetValue(value: "yellow", count: 30, highlighted: nil))
    expectedList.append(FacetValue(value: "blue", count: 40, highlighted: nil))

    let actualList: [FacetValue] = refinementListBuilder.getRefinementList(selectedValues: selectedValues,
                                                                           resultValues: facetValues,
                                                                           sorting: .count(order: .ascending),
                                                                           showSelectedValuesOnTop: false,
                                                                           keepSelectedValuesWithZeroCount: true)

    XCTAssertEqual(expectedList, actualList)
  }

  func testNameAscSelectedOnTop() {

    var expectedList: [FacetValue] = []

    expectedList.append(FacetValue(value: "green", count: 0, highlighted: nil))
    expectedList.append(FacetValue(value: "orange", count: 20, highlighted: nil))
    expectedList.append(FacetValue(value: "red", count: 10, highlighted: nil)) // Show selected first

    expectedList.append(FacetValue(value: "black", count: 5, highlighted: nil))
    expectedList.append(FacetValue(value: "blue", count: 40, highlighted: nil))
    expectedList.append(FacetValue(value: "yellow", count: 30, highlighted: nil))

    let actualList: [FacetValue] = refinementListBuilder.getRefinementList(selectedValues: selectedValues,
                                                                           resultValues: facetValues,
                                                                           sorting: .name(order: .ascending),
                                                                           showSelectedValuesOnTop: true,
                                                                           keepSelectedValuesWithZeroCount: true)

    XCTAssertEqual(expectedList, actualList)
  }

  func testNameAscNotSelectedOnTop() {

    var expectedList: [FacetValue] = []

    expectedList.append(FacetValue(value: "black", count: 5, highlighted: nil))
    expectedList.append(FacetValue(value: "blue", count: 40, highlighted: nil))
    expectedList.append(FacetValue(value: "green", count: 0, highlighted: nil))
    expectedList.append(FacetValue(value: "orange", count: 20, highlighted: nil))
    expectedList.append(FacetValue(value: "red", count: 10, highlighted: nil))
    expectedList.append(FacetValue(value: "yellow", count: 30, highlighted: nil))

    let actualList: [FacetValue] = refinementListBuilder.getRefinementList(selectedValues: selectedValues,
                                                                           resultValues: facetValues,
                                                                           sorting: .name(order: .ascending),
                                                                           showSelectedValuesOnTop: false,
                                                                           keepSelectedValuesWithZeroCount: true)

    XCTAssertEqual(expectedList, actualList)
  }

  func testNameDescSelectedOnTop() {
    var expectedList: [FacetValue] = []

    expectedList.append(FacetValue(value: "red", count: 10, highlighted: nil))
    expectedList.append(FacetValue(value: "orange", count: 20, highlighted: nil))
    expectedList.append(FacetValue(value: "green", count: 0, highlighted: nil)) // Show selected first


    expectedList.append(FacetValue(value: "yellow", count: 30, highlighted: nil))
    expectedList.append(FacetValue(value: "blue", count: 40, highlighted: nil))
    expectedList.append(FacetValue(value: "black", count: 5, highlighted: nil))

    let actualList: [FacetValue] = refinementListBuilder.getRefinementList(selectedValues: selectedValues,
                                                                           resultValues: facetValues,
                                                                           sorting: .name(order: .descending),
                                                                           showSelectedValuesOnTop: true,
                                                                           keepSelectedValuesWithZeroCount: true)

    XCTAssertEqual(expectedList, actualList)
  }

  func testNameDescNotSelectedOnTop() {
    var expectedList: [FacetValue] = []

    expectedList.append(FacetValue(value: "yellow", count: 30, highlighted: nil))
    expectedList.append(FacetValue(value: "red", count: 10, highlighted: nil))
    expectedList.append(FacetValue(value: "orange", count: 20, highlighted: nil))
    expectedList.append(FacetValue(value: "green", count: 0, highlighted: nil))
    expectedList.append(FacetValue(value: "blue", count: 40, highlighted: nil))
    expectedList.append(FacetValue(value: "black", count: 5, highlighted: nil))

    let actualList: [FacetValue] = refinementListBuilder.getRefinementList(selectedValues: selectedValues,
                                                                           resultValues: facetValues,
                                                                           sorting: .name(order: .descending),
                                                                           showSelectedValuesOnTop: false,
                                                                           keepSelectedValuesWithZeroCount: true)

    XCTAssertEqual(expectedList, actualList)
  }

  func testRemoveSelectedValuesWithZeroCount() {
    var expectedList: [FacetValue] = []

    expectedList.append(FacetValue(value: "yellow", count: 30, highlighted: nil))
    expectedList.append(FacetValue(value: "red", count: 10, highlighted: nil))
    expectedList.append(FacetValue(value: "orange", count: 20, highlighted: nil))
    expectedList.append(FacetValue(value: "blue", count: 40, highlighted: nil))
    expectedList.append(FacetValue(value: "black", count: 5, highlighted: nil))

    let actualList: [FacetValue] = refinementListBuilder.getRefinementList(selectedValues: selectedValues,
                                                                           resultValues: facetValues,
                                                                           sorting: .name(order: .descending),
                                                                           showSelectedValuesOnTop: false,
                                                                           keepSelectedValuesWithZeroCount: false)

    XCTAssertEqual(expectedList, actualList)
  }

  func testMergeWithFacetAndRefinementValues() {
    let actualList = refinementListBuilder.merge(facetValues, withRefinementValues: selectedValues)

    var expectedList: [FacetValue] = []
    expectedList.append(contentsOf: facetValues)
    expectedList.append(FacetValue(value: "green", count: 0, highlighted: nil)) // The missing one, put count 0

    XCTAssertEqual(expectedList, actualList)
  }

  func testMergeWithRefinementValues() {
    let actualList = refinementListBuilder.merge([], withRefinementValues: selectedValues)

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
