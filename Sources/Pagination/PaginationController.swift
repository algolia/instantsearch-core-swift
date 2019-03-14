//
//  PaginationController.swift
//  InstantSearchCore-iOS
//
//  Created by Vladislav Fitc on 13/03/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public class PaginationController<Item, Metadata: PageMetadata> {
  
  private typealias State = (pageMap: PageMap<Item>, metadata: Metadata)
  
  var pageMap: PageMap<Item>? {
    return state?.pageMap
  }
  
  weak var delegate: PaginationControllerDelegate?
  
  private var lastRequestedPage: UInt?
  private var state: State?
  
  func loadNextPageIfNeeded() {
    
    // No need to trigger loading the next page without any page context
    guard let currentState = state else {
      return
    }
    
    // No need to trigger loading the next page, if there is no such page
    guard currentState.pageMap.hasMorePages else {
      return
    }
    
    let pageToRequest = currentState.metadata.page + 1
    
    // No need to trigger loading the next page if last requested page
    if let lastRequestedPage = lastRequestedPage, pageToRequest <= lastRequestedPage {
      return
    }
    
    lastRequestedPage = pageToRequest
    delegate?.didRequestLoadPage(withNumber: pageToRequest)
    
  }
  
  func process<IP: PageMapConvertible>(_ page: IP, with metadata: Metadata) where IP.PageItem == Item {
    
    print("lastMD: \(String(describing: state?.metadata)), receivedMD \(metadata)")
    
    let updatedPageMap: PageMap<Item>
    
    if let state = state, metadata.isAnotherPage(for: state.metadata) {
      // If received page is a new page of current dataset, insert it to pageMap
      updatedPageMap = state.pageMap.inserting(page.pageItems, withNumber: Int(metadata.page))
    } else {
      // If received page is a page of different dataset, replace pageMap by the new one
      updatedPageMap = PageMap(page)
      lastRequestedPage = 0
    }
    
    state = (updatedPageMap, metadata)
    
  }
  
}

protocol PaginationControllerDelegate: class {
  func didRequestLoadPage(withNumber number: UInt)
}

public protocol PageMetadata {
  var page: UInt { get }
  func isAnotherPage(for data: Self) -> Bool
}
