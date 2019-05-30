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
  
  private var requestedPages: Set<Int> = []
  
  func loadPage(withIndex pageIndex: Int) {
    
    // No need to trigger if there is no delegate
    guard let delegate = delegate else { return }
    
    // No need to trigger loading the next page if already requested
    guard !requestedPages.contains(pageIndex) else { return }
    
    requestedPages.insert(pageIndex)
    delegate.didRequestLoadPage(withIndex: pageIndex)
    
  }
  
  func loadNextPageIfNeeded() {
    let pageToLoad = pageMap?.latestPageIndex.flatMap { $0 + 1 } ?? 0
    loadPage(withIndex: pageToLoad)
  }
  
  func process<IP: PageMapConvertible>(_ page: IP) where IP.PageItem == Item {
  
    requestedPages.remove(page.page)
    
    let updatedPageMap: PageMap<Item>
    
    if let pageMap = pageMap {
      updatedPageMap = pageMap.inserting(page.pageItems, withIndex: page.page)
    } else {
      updatedPageMap = PageMap(page)
    }
    
    pageMap = updatedPageMap
    
    if let pageCleanUpOffset = pageCleanUpOffset {
      pageMap?.cleanUp(basePageIndex: page.page, keepingPagesOffset: pageCleanUpOffset)
    }
    
  }
  
  public func invalidate() {
    requestedPages = []
    pageMap = .none
  }
  
}

extension PageMap {
  
  mutating func cleanUp(basePageIndex pageIndex: Int, keepingPagesOffset: Int) {
    
    let leastPageIndex = pageIndex - keepingPagesOffset
    let lastPageIndex = pageIndex + keepingPagesOffset
    
    let pagesToRemove = loadedPageIndexes.filter { $0 < leastPageIndex || $0 > lastPageIndex }

    for pageIndex in pagesToRemove {
      items.removeValue(forKey: pageIndex)
    }
    
  }
  
}

protocol PaginatorDelegate: class {
  func didRequestLoadPage(withIndex pageIndex: Int)
}
