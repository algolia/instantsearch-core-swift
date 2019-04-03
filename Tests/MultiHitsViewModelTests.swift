//
//  MultiHitsViewModelTests.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 18/03/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation
@testable import InstantSearchCore
import XCTest

class MultiHitsViewModelTests: XCTestCase {
  
  func testConstruction() {
    let viewModel = MultiHitsViewModel()
    XCTAssertEqual(viewModel.numberOfSections(), 0)
  }
  
  func testAppend() {
    let multiViewModel = MultiHitsViewModel()
    let viewModel1 = HitsViewModel<[String: Int]>()
    let viewModel2 = HitsViewModel<[String: [String: Int]]>()
    
    multiViewModel.append(viewModel1)
    multiViewModel.append(viewModel2)
    
    XCTAssertEqual(multiViewModel.numberOfSections(), 2)
    XCTAssertTrue(multiViewModel.contains(viewModel1))
    XCTAssertTrue(multiViewModel.contains(viewModel2))

  }
  
  func testInsertAndSearchByIndex() {
    let multiViewModel = MultiHitsViewModel()
    let viewModel1 = HitsViewModel<[String: Int]>()
    let viewModel2 = HitsViewModel<[String: [String: Int]]>()
    
    multiViewModel.insert(hitsViewModel: viewModel1, inSection: 0)
    multiViewModel.insert(hitsViewModel: viewModel2, inSection: 0)
    
    XCTAssertEqual(multiViewModel.numberOfSections(), 2)
    XCTAssertTrue(multiViewModel.contains(viewModel1))
    XCTAssertTrue(multiViewModel.contains(viewModel2))
    XCTAssertEqual(multiViewModel.section(of: viewModel1), 1)
    XCTAssertEqual(multiViewModel.section(of: viewModel2), 0)

  }
  
  func testReplacement() {
    let multiViewModel = MultiHitsViewModel()
    let viewModel1 = HitsViewModel<[String: Int]>()
    let viewModel2 = HitsViewModel<[String: [String: Int]]>()
    
    multiViewModel.insert(hitsViewModel: viewModel1, inSection: 0)
    multiViewModel.replace(by: viewModel2, inSection: 0)
    
    XCTAssertEqual(multiViewModel.numberOfSections(), 1)
    XCTAssertTrue(multiViewModel.contains(viewModel2))
    XCTAssertFalse(multiViewModel.contains(viewModel1))

  }
  
  func testRemoval() {
    
    let multiViewModel = MultiHitsViewModel()
    
    let viewModel1 = HitsViewModel<[String: Int]>()
    let viewModel2 = HitsViewModel<[String: [String: Int]]>()
    
    multiViewModel.append(viewModel1)
    multiViewModel.append(viewModel2)

    multiViewModel.remove(inSection: 0)
    
    XCTAssertEqual(multiViewModel.numberOfSections(), 1)
    XCTAssertFalse(multiViewModel.contains(viewModel1))
    XCTAssertTrue(multiViewModel.contains(viewModel2))

  }
  
  func testRemoveAll() {
    
    let multiViewModel = MultiHitsViewModel()
    
    let viewModel1 = HitsViewModel<[String: Int]>()
    let viewModel2 = HitsViewModel<[String: [String: Int]]>()
    
    multiViewModel.append(viewModel1)
    multiViewModel.append(viewModel2)
    
    multiViewModel.removeAll()
    
    XCTAssertEqual(multiViewModel.numberOfSections(), 0)

  }
  
  func testSearchByIndexThrows() {
    
    let multiViewModel = MultiHitsViewModel()
    
    let viewModel1 = HitsViewModel<[String: Int]>()
    let viewModel2 = HitsViewModel<[String: [String: Int]]>()
    
    multiViewModel.append(viewModel1)
    multiViewModel.append(viewModel2)
    
    XCTAssertNoThrow(try multiViewModel.hitsViewModel(forSection: 0) as HitsViewModel<[String: Int]>)
    XCTAssertNoThrow(try multiViewModel.hitsViewModel(forSection: 1) as HitsViewModel<[String: [String: Int]]>)
    XCTAssertThrowsError(try multiViewModel.hitsViewModel(forSection: 0) as HitsViewModel<[String: [String: String]]>)
    XCTAssertThrowsError(try multiViewModel.hitsViewModel(forSection: 1) as HitsViewModel<String>)

  }
  
  func testUpdatePerViewModel() {
    
    let multiViewModel = MultiHitsViewModel()

    let viewModel1 = HitsViewModel<[String: Int]>()
    let viewModel2 = HitsViewModel<[String: Bool]>()
    
    multiViewModel.append(viewModel1)
    multiViewModel.append(viewModel2)
    
    let hits1: [[String: Int]] = [["a": 1], ["b": 2], ["c": 3]]
    let results1 = SearchResults<[String: Int]>(hits: hits1, query: "q1", params: "", queryID: "", page: 0, pagesCount: 10, hitsPerPage: 3)
    let md = QueryMetadata(queryText: "q1", page: 0)

    let hits2: [[String: Bool]] = [["a": true], ["b": false], ["c": true]]
    let results2 = SearchResults<[String: Bool]>(hits: hits2, query: "q1", params: "", queryID: "", page: 0, pagesCount: 10, hitsPerPage: 3)
    
    XCTAssertNoThrow(try multiViewModel.update(results1, with: md, forViewModelInSection: 0))
    XCTAssertNoThrow(try multiViewModel.update(results2, with: md, forViewModelInSection: 1))
    
    XCTAssertThrowsError(try multiViewModel.update(results2, with: md, forViewModelInSection: 0))
    XCTAssertThrowsError(try multiViewModel.update(results1, with: md, forViewModelInSection: 1))

  }
  
  func testUpdateSimultaneously() {
    
    let multiViewModel = MultiHitsViewModel()
    
    let viewModel1 = HitsViewModel<[String: Int]>()
    let viewModel2 = HitsViewModel<[String: Bool]>()
    
    multiViewModel.append(viewModel1)
    multiViewModel.append(viewModel2)
    
    let hits1: [JSON] = [
      .dictionary(["a": .number(1)]),
      .dictionary(["b": .number(2)]),
      .dictionary(["c": .number(3)])
    ]
    
    let results1: SearchResults<JSON> = SearchResults(hits: hits1, query: "q1", params: "", queryID: "", page: 0, pagesCount: 10, hitsPerPage: 3)
    
    let hits2: [JSON] = [
      .dictionary(["a": .bool(true)]),
      .dictionary(["b": .bool(false)]),
    ]
    
    let results2: SearchResults<JSON> = SearchResults(hits: hits2, query: "q1", params: "", queryID: "", page: 0, pagesCount: 10, hitsPerPage: 3)
    
    let md = QueryMetadata(queryText: "q1", page: 0)

    // Update multihits ViewModel with a correct list of results
    XCTAssertNoThrow(try multiViewModel.update([(md, results1), (md, results2)]))
    
    // Checking the state
    XCTAssertEqual(multiViewModel.numberOfSections(), 2)
    XCTAssertEqual(multiViewModel.numberOfHits(inSection: 0), hits1.count)
    XCTAssertEqual(multiViewModel.numberOfHits(inSection: 1), hits2.count)
    
    // Update multihits ViewModel with uncorrect list of results
    XCTAssertThrowsError(try multiViewModel.update([(md, results2), (md, results1)]))
    
    // Checking the state
    XCTAssertEqual(multiViewModel.numberOfSections(), 2)
    XCTAssertEqual(multiViewModel.numberOfHits(inSection: 0), hits1.count)
    XCTAssertEqual(multiViewModel.numberOfHits(inSection: 1), hits2.count)
  }
  
  func testHitForRow() {
    
    let multiViewModel = MultiHitsViewModel()

    let viewModel1 = HitsViewModel<[String: Int]>()
    let viewModel2 = HitsViewModel<[String: Bool]>()
    
    multiViewModel.append(viewModel1)
    multiViewModel.append(viewModel2)
    
    let hits1: [JSON] = [
      .dictionary(["a": .number(1)]),
      .dictionary(["b": .number(2)]),
      .dictionary(["c": .number(3)])
    ]
    
    let results1: SearchResults<JSON> = SearchResults(hits: hits1, query: "q1", params: "", queryID: "", page: 0, pagesCount: 10, hitsPerPage: 3)
    
    let hits2: [JSON] = [
      .dictionary(["a": .bool(true)]),
      .dictionary(["b": .bool(false)]),
      ]
    
    let results2: SearchResults<JSON> = SearchResults(hits: hits2, query: "q1", params: "", queryID: "", page: 0, pagesCount: 10, hitsPerPage: 3)
        
    let md = QueryMetadata(queryText: "q1", page: 0)
    
    XCTAssertNoThrow(try multiViewModel.update([(md, results1), (md, results2)]))
    
    XCTAssertNoThrow(try multiViewModel.hit(atIndex: 0, inSection: 0) as [String: Int]?)
    XCTAssertNoThrow(try multiViewModel.hit(atIndex: 1, inSection: 1) as [String: Bool]?)
    XCTAssertThrowsError(try multiViewModel.hit(atIndex: 0, inSection: 0) as [String: Bool]?)
    XCTAssertThrowsError(try multiViewModel.hit(atIndex: 1, inSection: 1) as [String: Int]?)
    
    do {
      
      let hit1 = try multiViewModel.hit(atIndex: 0, inSection: 0) as [String: Int]?
      XCTAssertEqual(hit1?["a"], 1)
      
      let hit2 = try multiViewModel.hit(atIndex: 1, inSection: 1) as [String: Bool]?
      XCTAssertEqual(hit2?["b"], false)
      
    } catch let error {
      XCTFail("Unexpected error \(error)")
    }
    
  }
  
  struct TestHitsViewModel: AnyHitsViewModel {
    
    var didCallLoadMoreResults: () -> Void
    
    init(didCallLoadMoreResults: @escaping () -> Void) {
      self.didCallLoadMoreResults = didCallLoadMoreResults
    }
    
    func update(withGeneric searchResults: SearchResults<JSON>, with queryMetadata: QueryMetadata) throws {
    }
    
    func rawHitAtIndex(_ index: Int) -> [String : Any]? {
      return .none
    }
    
    func numberOfHits() -> Int {
      return 0
    }
    
    func genericHitAtIndex<R>(_ index: Int) throws -> R? where R : Decodable {
      return (0 as! R)
    }
    
    func loadMoreResults() {
      didCallLoadMoreResults()
    }
  }
  
  func testLoadMoreResults() {
    
    let multiViewModel = MultiHitsViewModel()
    
    let exp = expectation(description: "Call load more")
    exp.expectedFulfillmentCount = 2
    
    let testViewModel1 = TestHitsViewModel(didCallLoadMoreResults: exp.fulfill)
    let testViewModel2 = TestHitsViewModel(didCallLoadMoreResults: exp.fulfill)
    
    multiViewModel.appendGeneric(testViewModel1)
    multiViewModel.appendGeneric(testViewModel2)
    
    multiViewModel.loadMoreResults(forSection: 0)
    multiViewModel.loadMoreResults(forSection: 1)
    
    waitForExpectations(timeout: 2, handler: .none)
  }
  
}
