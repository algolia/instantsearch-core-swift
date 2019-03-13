//
//  PaginationController.swift
//  InstantSearchCore-iOS
//
//  Created by Vladislav Fitc on 13/03/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public class PaginationController<Item: Decodable, Metadata: PageMetadata> {
  
  var pageMap: PageMap<Item>?
  weak var delegate: PaginationControllerDelegate?
  
  private var lastRequestedPage: UInt = 0
  private var lastProcessedMetadata: Metadata?
  
  func loadNextPageIfNeeded() {
    
    guard let lastReceivedQueryMetadata = lastProcessedMetadata else { return }
    
    let newPageToRequest = lastReceivedQueryMetadata.page + 1
    
    guard newPageToRequest > lastRequestedPage else {
      return
    }
    
    lastRequestedPage += 1
    print("Requesting New page newPageToRequest \(newPageToRequest) and new lastRequestedPage \(lastRequestedPage)")
    delegate?.didRequestLoadPage(withNumber: lastRequestedPage)
    
  }
  
  func process<IP: PageMapConvertible>(_ page: IP, with metadata: Metadata) where IP.PageItem == Item {
    
    print("lastMD: \(lastProcessedMetadata.debugDescription), receivedMD \(metadata)")
    
    if
      let lastProcessedMetadata = lastProcessedMetadata,
      let currentPageMap = pageMap,
      metadata.isAnotherPage(for: lastProcessedMetadata)
    {
      pageMap = currentPageMap.inserting(page.pageItems, withNumber: Int(metadata.page))
      print("INSERT NEW HIT lastSentPage \(lastRequestedPage), latestPage \(pageMap!.latestPage), hitsCount \(pageMap!.count)")
    } else {
      pageMap = PageMap(page)
      lastRequestedPage = 0
      print("RESET NEW HIT lastSentPage \(lastRequestedPage), latestPage \(pageMap!.latestPage), hitsCount \(pageMap!.count)")
    }
    
    lastProcessedMetadata = metadata
    
  }
  
}

protocol PaginationControllerDelegate: class {
  func didRequestLoadPage(withNumber number: UInt)
}

public protocol PageMetadata {
  var page: UInt { get }
  func isAnotherPage(for data: Self) -> Bool
}
