//
//  Pagination.swift
//  InstantSearchCore-iOS
//
//  Created by Vladislav Fitc on 13/03/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

class Paginator<Item> {
  
  var pageMap: PageMap<Item>?
  weak var delegate: PaginatorDelegate?
  var pageCleanUpOffset: Int?
  
  private var lastRequestedPage: Int?
  
  func loadNextPageIfNeeded() {
    
    // No need to trigger if there is no delegate
    guard let delegate = delegate else { return }
    
    // No need to trigger loading the next page, if there is no such page
    guard delegate.hasMorePages else {
      return
    }
    
    let pageToRequest: Int
    
    if let latestPageIndex = pageMap?.latestPageIndex {
      pageToRequest = latestPageIndex + 1
    } else {
      pageToRequest = 0
    }
    
    // No need to trigger loading the next page if already requested
    if let lastRequestedPage = lastRequestedPage, pageToRequest <= lastRequestedPage {
      return
    }
    
    lastRequestedPage = pageToRequest
    delegate.didRequestLoadPage(withIndex: pageToRequest)
    
  }
  
  func process<IP: PageMapConvertible>(_ page: IP) where IP.PageItem == Item {
  
    let updatedPageMap: PageMap<Item>
    
    if let pageMap = pageMap {
      updatedPageMap = pageMap.inserting(page.pageItems, withIndex: page.page)
    } else {
      updatedPageMap = PageMap(page)
      lastRequestedPage = 0
    }
    
    pageMap = updatedPageMap
    
    if let pageCleanUpOffset = pageCleanUpOffset {
      pageMap?.cleanUp(basePageIndex: page.page, keepingPagesOffset: pageCleanUpOffset)
    }
    
  }
  
  public func invalidate() {
    pageMap = .none
  }
  
}

extension PageMap {
  
  mutating func cleanUp(basePageIndex pageIndex: Int, keepingPagesOffset: Int) {
    
    let leastPageIndex = pageIndex - keepingPagesOffset
    let lastPageIndex = pageIndex + keepingPagesOffset
    
    if leastPageIndex > 0 {
      let rangeToRemove = startIndex...leastPageIndex-1
      for pageIndex in rangeToRemove {
        items.removeValue(forKey: pageIndex)
      }
    }
    
    if lastPageIndex < pagesCount {
      let rangeToRemove = lastPageIndex+1...endIndex
      for pageIndex in rangeToRemove {
        items.removeValue(forKey: pageIndex)
      }
    }
    
  }
  
}

protocol PaginatorDelegate: class {
  var hasMorePages: Bool { get }
  func didRequestLoadPage(withIndex pageIndex: Int)
}
