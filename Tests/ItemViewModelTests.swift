//
//  ItemInteractorTests.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 31/05/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation
import XCTest
@testable import InstantSearchCore

class ItemInteractorTests: XCTestCase {
  
  typealias VM = ItemInteractor<String>
  
  func testConstruction() {
    
    let interactor = VM(item: "i")
    
    XCTAssertEqual(interactor.item, "i")
    
  }
  
  func testSwitchItem() {
    
    let interactor = VM(item: "i")
    
    let switchItemExpectation = expectation(description: "item changed")
    
<<<<<<< HEAD
    interactor.onItemChanged.subscribe(with: self) { newItem in
=======
    viewModel.onItemChanged.subscribe(with: self) { _, newItem in
>>>>>>> Add weak reference to observer in observation callback. Replac all [weak self] by reference to observer
      XCTAssertEqual(newItem, "o")
      switchItemExpectation.fulfill()
    }
    
    interactor.item = "o"
    
    waitForExpectations(timeout: 2, handler: nil)
  }
  
}
