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

class TestPageLoader: PageLoadable {
  
  var didLoadPage: ((Int) -> Void)?
  
  func loadPage(atIndex pageIndex: Int) {
    didLoadPage?(pageIndex)
  }
  
}

class MultiIndexHitsViewModelTests: XCTestCase {
  
  func testConstruction() {
    let viewModel = MultiIndexHitsViewModel(hitsViewModels: [])
    XCTAssertEqual(viewModel.numberOfSections(), 0)
  }
  
  func testAppend() {
    let viewModel1 = HitsViewModel<[String: Int]>()
    let viewModel2 = HitsViewModel<[String: [String: Int]]>()
    let multiViewModel = MultiIndexHitsViewModel(hitsViewModels: [viewModel1, viewModel2])
    
    XCTAssertEqual(multiViewModel.numberOfSections(), 2)
    XCTAssertTrue(multiViewModel.contains(viewModel1))
    XCTAssertTrue(multiViewModel.contains(viewModel2))

  }
  
  func testSearchByIndex() {
    let viewModel1 = HitsViewModel<[String: Int]>()
    let viewModel2 = HitsViewModel<[String: [String: Int]]>()
    let multiViewModel = MultiIndexHitsViewModel(hitsViewModels: [viewModel1, viewModel2])
    
    XCTAssertEqual(multiViewModel.numberOfSections(), 2)
    XCTAssertTrue(multiViewModel.contains(viewModel1))
    XCTAssertTrue(multiViewModel.contains(viewModel2))
    XCTAssertEqual(multiViewModel.section(of: viewModel1), 0)
    XCTAssertEqual(multiViewModel.section(of: viewModel2), 1)

  }
  
  func testSearchByIndexThrows() {
    
    let viewModel1 = HitsViewModel<[String: Int]>()
    let viewModel2 = HitsViewModel<[String: [String: Int]]>()
    
    let multiViewModel = MultiIndexHitsViewModel(hitsViewModels: [viewModel1, viewModel2])
    
    XCTAssertNoThrow(try multiViewModel.hitsViewModel(forSection: 0) as HitsViewModel<[String: Int]>)
    XCTAssertNoThrow(try multiViewModel.hitsViewModel(forSection: 1) as HitsViewModel<[String: [String: Int]]>)
    XCTAssertThrowsError(try multiViewModel.hitsViewModel(forSection: 0) as HitsViewModel<[String: [String: String]]>)
    XCTAssertThrowsError(try multiViewModel.hitsViewModel(forSection: 1) as HitsViewModel<String>)

  }
  
  func testUpdatePerViewModel() {

    let viewModel1 = HitsViewModel<[String: Int]>()
    let viewModel2 = HitsViewModel<[String: Bool]>()
    let multiViewModel = MultiIndexHitsViewModel(hitsViewModels: [viewModel1, viewModel2])
    
    let hits1 = try! [["a": 1], ["b": 2], ["c": 3]].map(JSON.init)
    let results1 = SearchResults(hits: hits1, stats: .init())

    let hits2 = try! [["a": true], ["b": false], ["c": true]].map(JSON.init)
    let results2 = SearchResults(hits: hits2, stats: .init())
    
    XCTAssertNoThrow(try multiViewModel.update(results1, forViewModelInSection: 0))
    XCTAssertNoThrow(try multiViewModel.update(results2, forViewModelInSection: 1))
    
    XCTAssertThrowsError(try multiViewModel.update(results2, forViewModelInSection: 0))
    XCTAssertThrowsError(try multiViewModel.update(results1, forViewModelInSection: 1))

  }
  
  func testUpdateSimultaneously() {
    
    let pageLoader = TestPageLoader()

    let viewModel1 = HitsViewModel<[String: Int]>()
    viewModel1.pageLoader = pageLoader
    let viewModel2 = HitsViewModel<[String: Bool]>()
    viewModel2.pageLoader = pageLoader
    
    let multiViewModel = MultiIndexHitsViewModel(hitsViewModels: [viewModel1, viewModel2])
    
    let hits1: [JSON] = [
      .dictionary(["a": .number(1)]),
      .dictionary(["b": .number(2)]),
      .dictionary(["c": .number(3)])
    ]
    
    let results1 = SearchResults(hits: hits1, stats: .init())
    
    let hits2: [JSON] = [
      .dictionary(["a": .bool(true)]),
      .dictionary(["b": .bool(false)]),
    ]
    
    let results2 = SearchResults(hits: hits2, stats: .init())
    
    // Update multihits ViewModel with a correct list of results
    XCTAssertNoThrow(try multiViewModel.update([results1, results2]))
    
    // Checking the state
    XCTAssertEqual(multiViewModel.numberOfSections(), 2)
    XCTAssertEqual(multiViewModel.numberOfHits(inSection: 0), hits1.count)
    XCTAssertEqual(multiViewModel.numberOfHits(inSection: 1), hits2.count)
    
    // Update multihits ViewModel with uncorrect list of results
    XCTAssertThrowsError(try multiViewModel.update([results2, results1]))
    
    // Checking the state
    XCTAssertEqual(multiViewModel.numberOfSections(), 2)
    XCTAssertEqual(multiViewModel.numberOfHits(inSection: 0), hits1.count)
    XCTAssertEqual(multiViewModel.numberOfHits(inSection: 1), hits2.count)
  }
  
  func testHitForRow() {

    let pageLoader = TestPageLoader()
    
    let viewModel1 = HitsViewModel<[String: Int]>()
    viewModel1.pageLoader = pageLoader
    let viewModel2 = HitsViewModel<[String: Bool]>()
    viewModel2.pageLoader = pageLoader
    
    let multiViewModel = MultiIndexHitsViewModel(hitsViewModels: [viewModel1, viewModel2])
    
    let hits1: [JSON] = [
      .dictionary(["a": .number(1)]),
      .dictionary(["b": .number(2)]),
      .dictionary(["c": .number(3)])
    ]
    
    let results1 = SearchResults(hits: hits1, stats: .init())
    
    let hits2: [JSON] = [
      .dictionary(["a": .bool(true)]),
      .dictionary(["b": .bool(false)]),
      ]
    
    let results2 = SearchResults(hits: hits2, stats: .init())
    
    XCTAssertNoThrow(try multiViewModel.update([results1, results2]))
    
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
  
  class TestHitsViewModel: AnyHitsViewModel {
    
    var pageLoader: PageLoadable?
    
    var didCallLoadMoreResults: () -> Void
    
    init(didCallLoadMoreResults: @escaping () -> Void) {
      self.didCallLoadMoreResults = didCallLoadMoreResults
    }
    
    func update(_ searchResults: SearchResults) throws {
      
    }
    
    func notifyQueryChanged() {
      
    }
    
    func notifyPending(atIndex index: Int) {

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
  
}
