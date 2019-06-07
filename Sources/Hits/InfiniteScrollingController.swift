//
//  InfiniteScrollingController.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 05/06/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public class InfiniteScrollingController: InfiniteScrollable {
  
  public var lastPageIndex: Int?
  public weak var pageLoader: PageLoadable?
  private let pendingPageIndexes: SynchronizedSet<Int>
  
  public init() {
    pendingPageIndexes = SynchronizedSet()
  }
  
  public func notifyPending(pageIndex: Int) {
    pendingPageIndexes.remove(pageIndex)
  }
  
  public func notifyPendingAll() {
    pendingPageIndexes.removeAll()
  }
  
  func isLoadedOrPending<T>(pageIndex: PageMap<T>.PageIndex, pageMap: PageMap<T>) -> Bool {
    return pageMap.containsPage(atIndex: pageIndex) || pendingPageIndexes.contains(pageIndex)
  }
  
  func calculatePagesAndLoad<T>(currentRow: Int, offset: Int, pageMap: PageMap<T>) {
    
    guard let pageLoader = pageLoader else {
      assertionFailure("Missing Page Loader")
      return
    }
    
    let previousPagesToLoad = computePreviousPagesToLoad(currentRow: currentRow, offset: offset, pageMap: pageMap)
    
    let nextPagesToLoad = computeNextPagesToLoad(currentRow: currentRow, offset: offset, pageMap: pageMap)
    
    // Zipping sorted pages to load sequences
    // makes possible to load the nearest pages firstly
    
    let pagesToLoad =
      zip(previousPagesToLoad.sorted(), nextPagesToLoad.sorted())
      .map { [$0.0, $0.1] }
      .reduce([], +)
    
    for pageIndex in pagesToLoad {
      debugPrint("[InfiniteScrollingController] Requested loading page: \(pageIndex)")
      pendingPageIndexes.insert(pageIndex)
      pageLoader.loadPage(atIndex: pageIndex)
    }
    
  }
  
  func computePreviousPagesToLoad<T>(currentRow: Int, offset: Int, pageMap: PageMap<T>) -> Set<PageMap<T>.PageIndex> {
    
    let computedLowerBoundRow = currentRow - offset
    let lowerBoundRow: Int
    
    if computedLowerBoundRow < pageMap.startIndex {
      lowerBoundRow = pageMap.startIndex
    } else {
      lowerBoundRow = computedLowerBoundRow
    }
    
    let pagesToLoad = (lowerBoundRow..<currentRow)
      .map(pageMap.pageIndex(for:))
      .filter { !isLoadedOrPending(pageIndex: $0, pageMap: pageMap) }
    
    return Set(pagesToLoad)

  }
  
  func computeNextPagesToLoad<T>(currentRow: Int, offset: Int, pageMap: PageMap<T>) -> Set<PageMap<T>.PageIndex> {
    
    let computedUpperBoundRow = currentRow + offset
    
    let upperBoundRow: Int
    
    if let lastPageIndex = lastPageIndex {
      let lastPageSize = pageMap.page(atIndex: lastPageIndex)?.items.count ?? pageMap.pageSize
      let totalPagesButLastCount = lastPageIndex
      let lastRowIndex = (totalPagesButLastCount * pageMap.pageSize + lastPageSize) - 1
      upperBoundRow = computedUpperBoundRow > lastRowIndex ? lastRowIndex : computedUpperBoundRow
    } else {
      upperBoundRow = computedUpperBoundRow
    }
    
    guard currentRow + 1 <= upperBoundRow else {
      return []
    }
    
    let pagesToLoad = ((currentRow + 1)...upperBoundRow)
      .map(pageMap.pageIndex(for:))
      .filter { !isLoadedOrPending(pageIndex: $0, pageMap: pageMap) }
    
    return Set(pagesToLoad)
    
  }
  
}
