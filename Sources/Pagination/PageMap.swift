//
//  PageMap.swift
//  InstantSearchCore-iOS
//
//  Created by Vladislav Fitc on 13/03/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

struct PageMap<Item> {
  
  var pageToItems: [Int: [Item]]
  
  var latestPage: UInt
  var totalPageCount: Int
  var totalItemsCount: Int
  
  fileprivate var itemsSequence: [Item]
  
  mutating func insert(_ page: [Item], withNumber pageNumber: Int) {
    pageToItems[pageNumber] = page
    itemsSequence = pageToItems.sorted { $0.key < $1.key } .flatMap { $0.value }
    
    if pageNumber > latestPage {
      latestPage = UInt(pageNumber)
    }
    
    if pageNumber > totalPageCount - 1 {
      totalPageCount = pageNumber + 1
    }
    
    if itemsSequence.count > totalItemsCount {
      totalItemsCount = itemsSequence.count
    }
    
  }
  
  func inserting(_ page: [Item], withNumber pageNumber: Int) -> PageMap {
    var mutableCopy = self
    mutableCopy.insert(page, withNumber: pageNumber)
    return mutableCopy
  }
  
  var hasMorePages: Bool {
    return totalPageCount > latestPage + 1
  }
  
  func containsItem(atIndex index: Int) -> Bool {
    return count > index
  }
  
}

extension PageMap: Sequence {
  func makeIterator() -> PageMapIterator<Item> {
    return PageMapIterator(itemsPages: self)
  }
}

extension PageMap: Collection {
  // Required nested types, that tell Swift what our collection contains
  typealias Index = Array<Item>.Index
  typealias Element = Array<Item>.Element
  
  // The upper and lower bounds of the collection, used in iterations
  var startIndex: Index { return itemsSequence.startIndex }
  var endIndex: Index { return itemsSequence.endIndex }
  
  // Required subscript, based on a dictionary index
  subscript(index: Index) -> Item {
    get { return itemsSequence[index] }
  }
  
  // Method that returns the next index when iterating
  func index(after i: Index) -> Index {
    return itemsSequence.index(after: i)
  }
}

struct PageMapIterator<Item>: IteratorProtocol {
  
  private let pageMap: PageMap<Item>
  private var iterator: Array<Item>.Iterator
  
  init(itemsPages: PageMap<Item>) {
    self.pageMap = itemsPages
    self.iterator = itemsPages.itemsSequence.makeIterator()
  }
  
  mutating func next() -> Item? {
    return iterator.next()
  }
  
}

protocol PageMapConvertible {
  
  associatedtype PageItem
  
  var page: Int { get }
  var pagesCount: Int { get }
  var totalItemsCount: Int { get }
  var pageItems: [PageItem] { get }
  
}

extension PageMap {
  
  init() {
    pageToItems = [0: []]
    latestPage = 0
    totalPageCount = 0
    totalItemsCount = 0
    itemsSequence = []
  }
  
  init<T: PageMapConvertible>(_ source: T) where T.PageItem == Item {
    pageToItems = [source.page: source.pageItems]
    latestPage = UInt(source.page)
    totalPageCount = source.pagesCount
    totalItemsCount = source.totalItemsCount
    itemsSequence = source.pageItems
  }
  
  init<S: Sequence>(_ items: S) where S.Element == Item {
    let itemsArray = Array(items)
    pageToItems = [0: itemsArray]
    latestPage = 0
    totalPageCount = 1
    totalItemsCount = itemsArray.count
    itemsSequence = itemsArray
  }
  
  init?(_ dictionary: [Int: [Item]]) {
    if dictionary.isEmpty {
      return nil
    }
    
    pageToItems = dictionary
    latestPage = UInt(dictionary.keys.sorted().last!)
    totalPageCount = dictionary.count
    totalItemsCount = dictionary.values.map { $0.count }.reduce(0, +)
    itemsSequence = dictionary.sorted { $0.key < $1.key } .flatMap { $0.value }
  }
  
}
