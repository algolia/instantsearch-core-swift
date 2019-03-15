//
//  PageMap.swift
//  InstantSearchCore-iOS
//
//  Created by Vladislav Fitc on 13/03/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

struct PageMap<Item: Decodable> {
  
  var pageToItems: [Int: [Item]]
  
  let latestPage: UInt
  let totalPageCount: Int
  let totalItemsCount: Int
  
  fileprivate var itemsSequence: [Item]
  
  mutating func insert(_ page: [Item], withNumber pageNumber: Int) {
    pageToItems[pageNumber] = page
    itemsSequence = pageToItems.sorted { $0.key < $1.key } .flatMap { $0.value }
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

struct PageMapIterator<Item: Decodable>: IteratorProtocol {
  
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
  
  associatedtype PageItem: Decodable
  
  var page: Int { get }
  var pagesCount: Int { get }
  var totalItemsCount: Int { get }
  var pageItems: [PageItem] { get }
  
}

extension PageMap {
  
  init<T: PageMapConvertible>(_ source: T) where T.PageItem == Item {
    pageToItems = [source.page: source.pageItems]
    latestPage = UInt(source.page)
    totalPageCount = source.pagesCount
    totalItemsCount = source.totalItemsCount
    itemsSequence = source.pageItems
  }
  
}
