//
//  DeletableListViewModel.swift
//  InstantSearchCore
//
//  Created by Guy Daher on 12/06/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public class ItemsListViewModel<Item: Hashable> {

  public var items: Set<Item> {
    didSet {
      if oldValue != items {
        onItemsChanged.fire(items)
      }
    }
  }

  public let onItemsChanged: Observer<Set<Item>>
  public let onItemsComputed: Observer<Set<Item>>

  public init(items: Set<Item> = []) {
    self.items = items
    self.onItemsChanged = Observer()
    self.onItemsComputed = Observer()
  }

  public func remove(item: Item) {
    self.onItemsComputed.fire(items.subtracting([item]))
  }

  public func add(item: Item) {
    self.onItemsComputed.fire(items.union([item]))
  }
}
