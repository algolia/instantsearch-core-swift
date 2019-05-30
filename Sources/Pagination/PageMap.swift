//
//  PageMap.swift
//  InstantSearchCore-iOS
//
//  Created by Vladislav Fitc on 13/03/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

struct PageMap<Item> {
  
  typealias PageIndex = Int
  
  var items: [PageIndex: [Item]]
  
  var pageSize: Int
  
  var latestPageIndex: PageIndex? {
    return loadedPageIndexes.max()
  }
  
  var loadedPageIndexes: Set<PageIndex> = []
  
  var loadedPagesCount: Int {
    return items.count
  }
  
  var totalPagesCount: Int {
    guard let latestPageIndex = latestPageIndex else { return 0 }
    return latestPageIndex + 1
  }
  
  var totalItemsCount: Int {
    guard let latestPageIndex = latestPageIndex else { return 0 }
    // Here we suppose that last items page can be not full
    // So there is a need to calculate a number of elements
    // On last page and add it to previous pages count * page size
    let fullPagesCount = totalPagesCount - 1
    let latestPageItemsCount = items[latestPageIndex]?.count ?? 0
    return fullPagesCount * pageSize + latestPageItemsCount
  }
  
  mutating func insert(_ page: [Item], withIndex pageIndex: PageIndex) {
    items[pageIndex] = page
    loadedPageIndexes = Set(items.keys)
  }
  
  func inserting(_ page: [Item], withIndex pageIndex: PageIndex) -> PageMap {
    var mutableCopy = self
    mutableCopy.insert(page, withIndex: pageIndex)
    return mutableCopy
  }
    
  func pageIndex(for index: Index) -> PageIndex {
    return index / pageSize
  }
  
  func containsPage(atIndex pageIndex: PageIndex) -> Bool {
    return items[pageIndex] != nil
  }
  
  func containsItem(atIndex index: Index) -> Bool {
    return item(atIndex: index) != nil
  }
  
  func item(atIndex index: Index) -> Item? {
    let pageIndex = self.pageIndex(for: index)
    let offset = index % pageSize
    return items[pageIndex]?[offset]
  }
  
}

// MARK: SequenceType
extension PageMap: Sequence {
  
  public func makeIterator() -> IndexingIterator<PageMap> {
    return IndexingIterator(_elements: self)
  }
  
}

// MARK: CollectionType
extension PageMap: BidirectionalCollection {
  
  public typealias Index = Int
  
  public var startIndex: Index { return 0 }
  public var endIndex: Index { return totalItemsCount }
  
  public func index(after i: Index) -> Index {
    return i+1
  }
  
  public func index(before i: Index) -> Index {
    return i-1
  }
  
  /// Accesses and sets elements for a given flat index position.
  /// Currently, setter can only be used to replace non-optional values.
  public subscript (position: Index) -> Item? {
    get {
      let pageIndex = self.pageIndex(for: position)
      
      if let page = items[pageIndex] {
        return page[position%pageSize]
      } else {
        // Return nil for all pages that haven't been set yet
        return nil
      }
    }
    
    set(newValue) {
      guard let newValue = newValue else { return }
      
      let pageIndex = self.pageIndex(for: position)
      var elementPage = items[pageIndex]
      elementPage?[position % pageSize] = newValue
      items[pageIndex] = elementPage
    }
  }
}

protocol PageMapConvertible {
  
  associatedtype PageItem
  
  var page: Int { get }
  var pageSize: Int { get }
  var pageItems: [PageItem] { get }
  
}

extension PageMap {
  
  init(pageSize: Int) {
    items = [:]
    self.pageSize = pageSize
  }
  
  init<T: PageMapConvertible>(_ source: T) where T.PageItem == Item {
    items = [source.page: source.pageItems]
    loadedPageIndexes = [source.page]
    pageSize = source.pageItems.count
  }
  
  init<S: Sequence>(_ items: S) where S.Element == Item {
    let itemsArray = Array(items)
    self.items = [0: itemsArray]
    loadedPageIndexes = [0]
    pageSize = itemsArray.count
  }
  
  init?(_ dictionary: [Int: [Item]]) {
    if dictionary.isEmpty {
      return nil
    }
    
    items = dictionary
    loadedPageIndexes = Set(dictionary.keys)
    pageSize = dictionary.sorted(by: { $0.key < $1.key }).first?.value.count ?? 0
  }
  
}
