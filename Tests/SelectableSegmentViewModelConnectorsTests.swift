//
//  SelectableSegmentInteractorConnectorsTests.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 21/05/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation
@testable import InstantSearchCore
import XCTest

class SelectableSegmentInteractorConnectorsTests: XCTestCase {
  
  class TestController: SelectableSegmentController {
    
    typealias SegmentKey = Int
    
    var selected: Int?
    var onClick: ((Int) -> Void)?
    var items: [Int: String] = [:]
    
    func setSelected(_ selected: Int?) {
      self.selected = selected
    }
    
    func setItems(items: [Int : String]) {
      self.items = items
    }
    
    func clickItem(withKey key: Int) {
      onClick?(key)
    }
    
  }
  
  func testConnectSearcher() {
    
    let query = Query()
    let filterState = FilterState()
    let searcher = SingleIndexSearcher(index: .test, query: query)
    
    let interactor = SelectableSegmentInteractor<Int, Filter.Tag>(items: [0: "t1", 1: "t2", 2: "t3"])
    interactor.connectSearcher(searcher, attribute: "tags")
    interactor.connectFilterState(filterState, attribute: "tags", operator: .or)
    
    XCTAssertTrue((query.facets ?? []).contains("tags"))
    
  }
  
  func testConnectFilterState() {
    
    let filterState = FilterState()
    let interactor = SelectableSegmentInteractor<Int, Filter.Tag>(items: [0: "t1", 1: "t2", 2: "t3"])
    
    interactor.connectFilterState(filterState, attribute: "tags", operator: .or)
    // Interactor -> FilterState
    
    interactor.computeSelected(selecting: 1)
    
    XCTAssertTrue(filterState.contains(Filter.Tag(value: "t2"), inGroupWithID: .or(name: "tags", filterType: .tag)))

    // FilterState -> Interactor
    
    filterState.notify(.remove(filter: Filter.Tag(value: "t2"), fromGroupWithID: .or(name: "tags", filterType: .tag)))
    
    XCTAssertNil(interactor.selected)
    
    filterState.notify(.add(filter: Filter.Tag(value: "t3"), toGroupWithID: .or(name: "tags", filterType: .tag)))
    
    XCTAssertEqual(interactor.selected, 2)
    
  }
  
  func testConnectController() {
    
    let interactor = SelectableSegmentInteractor<Int, Filter.Tag>(items: [0: "t1", 1: "t2", 2: "t3"])
    let controller = TestController()

    interactor.selected = 1
    
    interactor.connectController(controller)

    // Preselection
    
    XCTAssertEqual(controller.items, [0: "t1", 1: "t2", 2: "t3"])
    XCTAssertEqual(controller.selected, 1)
    
    // Interactor -> Controller
    
    interactor.selected = 2
    XCTAssertEqual(controller.selected, 2)

    interactor.items = [0: "t4", 1: "t5", 2: "t6"]
    XCTAssertEqual(controller.items, [0: "t4", 1: "t5", 2: "t6"])
    
    // Controller -> Interactor
    
    let selectedComputedExpectation = expectation(description: "selected computed")
    
    interactor.onSelectedComputed.subscribe(with: self) { _, selected in
      XCTAssertEqual(selected, 0)
      selectedComputedExpectation.fulfill()
    }
    
    controller.clickItem(withKey: 0)
    
    waitForExpectations(timeout: 5, handler: nil)
    
  }
    
}
