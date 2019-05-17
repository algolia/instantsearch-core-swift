//
//  SelectableListViewModel.swift
//  InstantSearchCore
//
//  Created by Guy Daher on 18/04/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public enum SelectionMode {
  case single
  case multiple
}

public class SelectableListViewModel<Key: Hashable, Item: Equatable> {

  public var selectionMode: SelectionMode

  public init(items: [Item] = [], selectionMode: SelectionMode) {
    self.items = items
    self.selectionMode = selectionMode
  }

  public var onItemsChanged = Observer<[Item]>()
  public var onSelectionsChanged = Observer<Set<Key>>()
  public var onSelectionsComputed = Observer<Set<Key>>()

  public var items: [Item] {
    didSet {
      if oldValue != items {
        onItemsChanged.fire(items)
      }
    }
  }

  public var selections = Set<Key>() {
    didSet {
      if oldValue != selections {
        onSelectionsChanged.fire(selections)
      }
    }
  }

  public func computeSelections(selectingItemForKey key: Key) {
    
    let selections: Set<Key>
    
    switch selectionMode {
    case .single:
      selections = self.selections.contains(key) ? [] : [key]
      
    case .multiple:
      selections = self.selections.contains(key) ? self.selections.subtracting([key]) : self.selections.union([key])
    }
    
    onSelectionsComputed.fire(selections)

  }

}
