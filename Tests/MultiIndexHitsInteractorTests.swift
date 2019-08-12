//
//  MultiHitsInteractorTests.swift
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

class MultiIndexHitsInteractorTests: XCTestCase {
  
  func testConstruction() {
    let interactor = MultiIndexHitsInteractor(hitsInteractors: [])
    XCTAssertEqual(interactor.numberOfSections(), 0)
  }
  
  func testAppend() {
    let interactor1 = HitsInteractor<[String: Int]>()
    let interactor2 = HitsInteractor<[String: [String: Int]]>()
    let multiInteractor = MultiIndexHitsInteractor(hitsInteractors: [interactor1, interactor2])
    
    XCTAssertEqual(multiInteractor.numberOfSections(), 2)
    XCTAssertTrue(multiInteractor.contains(interactor1))
    XCTAssertTrue(multiInteractor.contains(interactor2))

  }
  
  func testSearchByIndex() {
    let interactor1 = HitsInteractor<[String: Int]>()
    let interactor2 = HitsInteractor<[String: [String: Int]]>()
    let multiInteractor = MultiIndexHitsInteractor(hitsInteractors: [interactor1, interactor2])
    
    XCTAssertEqual(multiInteractor.numberOfSections(), 2)
    XCTAssertTrue(multiInteractor.contains(interactor1))
    XCTAssertTrue(multiInteractor.contains(interactor2))
    XCTAssertEqual(multiInteractor.section(of: interactor1), 0)
    XCTAssertEqual(multiInteractor.section(of: interactor2), 1)

  }
  
  func testSearchByIndexThrows() {
    
    let interactor1 = HitsInteractor<[String: Int]>()
    let interactor2 = HitsInteractor<[String: [String: Int]]>()
    
    let multiInteractor = MultiIndexHitsInteractor(hitsInteractors: [interactor1, interactor2])
    
    XCTAssertNoThrow(try multiInteractor.hitsInteractor(forSection: 0) as HitsInteractor<[String: Int]>)
    XCTAssertNoThrow(try multiInteractor.hitsInteractor(forSection: 1) as HitsInteractor<[String: [String: Int]]>)
    XCTAssertThrowsError(try multiInteractor.hitsInteractor(forSection: 0) as HitsInteractor<[String: [String: String]]>)
    XCTAssertThrowsError(try multiInteractor.hitsInteractor(forSection: 1) as HitsInteractor<String>)

  }
  
  func testUpdatePerInteractor() {

    let interactor1 = HitsInteractor<[String: Int]>()
    let interactor2 = HitsInteractor<[String: Bool]>()
    let multiInteractor = MultiIndexHitsInteractor(hitsInteractors: [interactor1, interactor2])
    
    let hits1 = try! [["a": 1], ["b": 2], ["c": 3]].map(JSON.init)
    let results1 = SearchResults(hits: hits1, stats: .init())

    let hits2 = try! [["a": true], ["b": false], ["c": true]].map(JSON.init)
    let results2 = SearchResults(hits: hits2, stats: .init())
    
    XCTAssertNoThrow(try multiInteractor.update(results1, forInteractorInSection: 0))
    XCTAssertNoThrow(try multiInteractor.update(results2, forInteractorInSection: 1))
    
    XCTAssertThrowsError(try multiInteractor.update(results2, forInteractorInSection: 0))
    XCTAssertThrowsError(try multiInteractor.update(results1, forInteractorInSection: 1))

  }
  
  func testUpdateSimultaneously() {
    
    let pageLoader = TestPageLoader()

    let interactor1 = HitsInteractor<[String: Int]>()
    interactor1.pageLoader = pageLoader
    let interactor2 = HitsInteractor<[String: Bool]>()
    interactor2.pageLoader = pageLoader
    
    let multiInteractor = MultiIndexHitsInteractor(hitsInteractors: [interactor1, interactor2])
    
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
    
    // Update multihits Interactor with a correct list of results
    XCTAssertNoThrow(try multiInteractor.update([results1, results2]))
    
    // Checking the state
    XCTAssertEqual(multiInteractor.numberOfSections(), 2)
    XCTAssertEqual(multiInteractor.numberOfHits(inSection: 0), hits1.count)
    XCTAssertEqual(multiInteractor.numberOfHits(inSection: 1), hits2.count)
    
    // Update multihits Interactor with uncorrect list of results
    XCTAssertThrowsError(try multiInteractor.update([results2, results1]))
    
    // Checking the state
    XCTAssertEqual(multiInteractor.numberOfSections(), 2)
    XCTAssertEqual(multiInteractor.numberOfHits(inSection: 0), hits1.count)
    XCTAssertEqual(multiInteractor.numberOfHits(inSection: 1), hits2.count)
  }
  
  func testHitForRow() {

    let pageLoader = TestPageLoader()
    
    let interactor1 = HitsInteractor<[String: Int]>()
    interactor1.pageLoader = pageLoader
    let interactor2 = HitsInteractor<[String: Bool]>()
    interactor2.pageLoader = pageLoader
    
    let multiInteractor = MultiIndexHitsInteractor(hitsInteractors: [interactor1, interactor2])
    
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
    
    XCTAssertNoThrow(try multiInteractor.update([results1, results2]))
    
    XCTAssertNoThrow(try multiInteractor.hit(atIndex: 0, inSection: 0) as [String: Int]?)
    XCTAssertNoThrow(try multiInteractor.hit(atIndex: 1, inSection: 1) as [String: Bool]?)
    XCTAssertThrowsError(try multiInteractor.hit(atIndex: 0, inSection: 0) as [String: Bool]?)
    XCTAssertThrowsError(try multiInteractor.hit(atIndex: 1, inSection: 1) as [String: Int]?)
    
    do {
      
      let hit1 = try multiInteractor.hit(atIndex: 0, inSection: 0) as [String: Int]?
      XCTAssertEqual(hit1?["a"], 1)
      
      let hit2 = try multiInteractor.hit(atIndex: 1, inSection: 1) as [String: Bool]?
      XCTAssertEqual(hit2?["b"], false)
      
    } catch let error {
      XCTFail("Unexpected error \(error)")
    }
    
  }
  
  class TestHitsInteractor: AnyHitsInteractor {
    
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
