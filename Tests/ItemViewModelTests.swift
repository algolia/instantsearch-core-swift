//
//  ItemViewModelTests.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 31/05/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation
import XCTest
@testable import InstantSearchCore

class ItemViewModelTests: XCTestCase {
  
  typealias VM = ItemInteractor<String>
  
  func testConstruction() {
    
    let viewModel = VM(item: "i")
    
    XCTAssertEqual(viewModel.item, "i")
    
  }
  
  func testSwitchItem() {
    
    let viewModel = VM(item: "i")
    
    let switchItemExpectation = expectation(description: "item changed")
    
    viewModel.onItemChanged.subscribe(with: self) { newItem in
      XCTAssertEqual(newItem, "o")
      switchItemExpectation.fulfill()
    }
    
    viewModel.item = "o"
    
    waitForExpectations(timeout: 2, handler: nil)
  }
  
}
