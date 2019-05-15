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
  
  private var lastRequestedPage: UInt?
  
  func loadNextPageIfNeeded() {
    
    // No need to trigger loading the next page without any page context
    guard let pageMap = pageMap else {
      lastRequestedPage = 0
      delegate?.didRequestLoadPage(withNumber: 0)
      return
    }
    
    // No need to trigger loading the next page, if there is no such page
    guard pageMap.hasMorePages else {
      return
    }
    
    let pageToRequest = pageMap.latestPage + 1
    
    // No need to trigger loading the next page if last requested page
    if let lastRequestedPage = lastRequestedPage, pageToRequest <= lastRequestedPage {
      return
    }
    
    lastRequestedPage = pageToRequest
    delegate?.didRequestLoadPage(withNumber: pageToRequest)
    
  }
  
  func process<IP: PageMapConvertible>(_ page: IP) where IP.PageItem == Item {
  
    let updatedPageMap: PageMap<Item>
    
    if let pageMap = pageMap {
      updatedPageMap = pageMap.inserting(page.pageItems, withNumber: page.page)
    } else {
      updatedPageMap = PageMap(page)
      lastRequestedPage = 0
    }
    
    pageMap = updatedPageMap
    
  }
  
  public func invalidate() {
    pageMap = .none
  }
  
}

protocol PaginatorDelegate: class {
  func didRequestLoadPage(withNumber number: UInt)
}
