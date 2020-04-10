//
//  MultiHitsInteractorTests.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 18/03/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation
@testable import InstantSearchCore
import AlgoliaSearchClientSwiftimport XCTest

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
  
  func testAccessByIndex() {
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
    
    let noErrorExpectation = expectation(description: "correct update")
    noErrorExpectation.isInverted = true
    
    let resultsExpectation = expectation(description: "results")
    resultsExpectation.expectedFulfillmentCount = 2
    
    multiInteractor.onError.subscribe(with: self) { (_, error) in
      noErrorExpectation.fulfill()
    }
    
    multiInteractor.onResultsUpdated.subscribe(with: self) { (_, results) in
      resultsExpectation.fulfill()
    }
    
    multiInteractor.update(results1, forInteractorInSection: 0)
    multiInteractor.update(results2, forInteractorInSection: 1)

    waitForExpectations(timeout: 3, handler: .none)
  
  }
  
  func testIncorrectUpdatePerInteractor() {
    
    let interactor1 = HitsInteractor<[String: Int]>()
    let interactor2 = HitsInteractor<[String: Bool]>()
    let multiInteractor = MultiIndexHitsInteractor(hitsInteractors: [interactor1, interactor2])
    
    let hits1 = try! [["a": 1], ["b": 2], ["c": 3]].map(JSON.init)
    let results1 = SearchResults(hits: hits1, stats: .init())

    let hits2 = try! [["a": true], ["b": false], ["c": true]].map(JSON.init)
    let results2 = SearchResults(hits: hits2, stats: .init())
    
    let errorExpectation = expectation(description: "incorrect update")
    errorExpectation.expectedFulfillmentCount = 2
    
    let resultsExpectation = expectation(description: "results")
    resultsExpectation.expectedFulfillmentCount = 2

    multiInteractor.onError.subscribe(with: self) { (_, error) in
      errorExpectation.fulfill()
    }
    
    multiInteractor.onResultsUpdated.subscribe(with: self) { (_, _) in
      resultsExpectation.fulfill()
    }
    
    multiInteractor.update(results1, forInteractorInSection: 1)
    multiInteractor.update(results2, forInteractorInSection: 0)

    waitForExpectations(timeout: 3, handler: .none)
    
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
    
    let interactor1Exp = expectation(description: "Interactor 1")
    let interactor2Exp = expectation(description: "Interactor 2")
    let multiInteractorExp = expectation(description: "MultiInteractor expectation")
    
    interactor1.onResultsUpdated.subscribe(with: self) { (_, _) in
      XCTAssertEqual(multiInteractor.numberOfSections(), 2)
      XCTAssertEqual(multiInteractor.numberOfHits(inSection: 0), hits1.count)
      interactor1Exp.fulfill()
    }
    
    interactor2.onResultsUpdated.subscribe(with: self) { (_, _) in
      XCTAssertEqual(multiInteractor.numberOfSections(), 2)
      XCTAssertEqual(multiInteractor.numberOfHits(inSection: 1), hits2.count)
      interactor2Exp.fulfill()
    }
    
    multiInteractor.onResultsUpdated.subscribe(with: self) { (_, _) in
      multiInteractorExp.fulfill()
    }
    
    // Update multihits Interactor with a correct list of results
    multiInteractor.update([results1, results2])
              
    waitForExpectations(timeout: 3, handler: .none)
    
  }
  
  func testIncorrectUpdateSimultaneously() {
    
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
    
    let interactor1Exp = expectation(description: "Interactor 1")
    let interactor2Exp = expectation(description: "Interactor 2")
    let multiInteractorExp = expectation(description: "MultiInteractor expectation")
    multiInteractorExp.expectedFulfillmentCount = 2
    
    interactor1.onError.subscribe(with: self) { (_, _) in
      XCTAssertEqual(multiInteractor.numberOfSections(), 2)
      XCTAssertEqual(multiInteractor.numberOfHits(inSection: 0), 0)
      interactor1Exp.fulfill()
    }
         
    interactor2.onError.subscribe(with: self) { (_, _) in
       XCTAssertEqual(multiInteractor.numberOfSections(), 2)
       XCTAssertEqual(multiInteractor.numberOfHits(inSection: 1), 0)
       interactor2Exp.fulfill()
    }
     
    multiInteractor.onError.subscribe(with: self) { (_, _) in
       multiInteractorExp.fulfill()
    }
     
    // Update multihits Interactor with a correct list of results
    multiInteractor.update([results2, results1])
               
    waitForExpectations(timeout: 3, handler: .none)
    
  }
  
  func testPartiallyCorrectUpdateSimultaneously() {
    
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
      .dictionary(["a": .string("a")]),
      .dictionary(["b": .string("b")]),
    ]
    
    let results2 = SearchResults(hits: hits2, stats: .init())
    
    let interactor1Exp = expectation(description: "Interactor 1")
    let interactor2Exp = expectation(description: "Interactor 2")
    let multiInteractorResultsExp = expectation(description: "MultiInteractor results expectation")
    let multiInteractorErrorExp = expectation(description: "MultiInteractor error expectation")
        
    interactor1.onResultsUpdated.subscribe(with: self) { (_, _) in
      XCTAssertEqual(multiInteractor.numberOfSections(), 2)
      XCTAssertEqual(multiInteractor.numberOfHits(inSection: 0), 3)
      interactor1Exp.fulfill()
    }
         
    interactor2.onError.subscribe(with: self) { (_, _) in
       XCTAssertEqual(multiInteractor.numberOfSections(), 2)
       XCTAssertEqual(multiInteractor.numberOfHits(inSection: 1), 0)
       interactor2Exp.fulfill()
    }
    
    multiInteractor.onResultsUpdated.subscribe(with: self) { (_, _) in
       multiInteractorResultsExp.fulfill()
    }
     
    multiInteractor.onError.subscribe(with: self) { (_, _) in
       multiInteractorErrorExp.fulfill()
    }
     
    // Update multihits Interactor with a correct list of results
    multiInteractor.update([results1, results2])
               
    waitForExpectations(timeout: 3, handler: .none)
    
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
    
    let resultsUpdatedExp = expectation(description: "Results updated")
  
    multiInteractor.onResultsUpdated.subscribe(with: self) { (_, _) in

      do {
        XCTAssertNoThrow(try multiInteractor.hit(atIndex: 0, inSection: 0) as [String: Int]?)
        XCTAssertNoThrow(try multiInteractor.hit(atIndex: 1, inSection: 1) as [String: Bool]?)
        XCTAssertThrowsError(try multiInteractor.hit(atIndex: 0, inSection: 0) as [String: Bool]?)
        XCTAssertThrowsError(try multiInteractor.hit(atIndex: 1, inSection: 1) as [String: Int]?)
      } catch _ {}

      do {
        
        let hit1 = try multiInteractor.hit(atIndex: 0, inSection: 0) as [String: Int]?
        XCTAssertEqual(hit1?["a"], 1)
        
        let hit2 = try multiInteractor.hit(atIndex: 1, inSection: 1) as [String: Bool]?
        XCTAssertEqual(hit2?["b"], false)
        
      } catch let error {
        XCTFail("Unexpected error \(error)")
      }
      
      resultsUpdatedExp.fulfill()
    }
        
    multiInteractor.update([results1, results2])
    
    waitForExpectations(timeout: 3, handler: .none)
        
  }
  
  class TestHitsInteractor: AnyHitsInteractor {
    
    func getCurrentGenericHits<R>() throws -> [R] where R : Decodable {
      return []
    }
    
    func getCurrentRawHits() -> [[String : Any]] {
      return []
    }
    
    var onError: Observer<Error> = .init()
        
    var pageLoader: PageLoadable?
    
    var didCallLoadMoreResults: () -> Void
    
    init(didCallLoadMoreResults: @escaping () -> Void) {
      self.didCallLoadMoreResults = didCallLoadMoreResults
    }
    
    func update(_ searchResults: SearchResults) -> Operation {
      return Operation()
    }
    
    func process(_ error: Error, for query: Query) {

    }
    
    func notifyQueryChanged() {
      
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
