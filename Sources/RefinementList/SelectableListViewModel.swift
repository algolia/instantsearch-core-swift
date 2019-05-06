//
//  SelectableListViewModel.swift
//  InstantSearchCore
//
//  Created by Guy Daher on 18/04/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public class SelectableListViewModel<K: Hashable, Item: Equatable> {

  public var selectionMode: SelectionMode

  public init(selectionMode: SelectionMode) {
    self.selectionMode = selectionMode
  }

  public var onItemsChanged = Observer<[Item]>()
  public var onSelectionsChanged = Observer<Set<K>>()
  public var onSelectionsComputed = Observer<Set<K>>()

  public var items: [Item] = [] {
    didSet {
      if oldValue != items {
        onItemsChanged.fire(items)
      }
    }
  }

  public var selections = Set<K>() {
    didSet {
      if oldValue != selections {
        onSelectionsChanged.fire(selections)
      }
    }
  }

  public func computeSelections(selectingItemForKey key: K) {
    
    let selections: Set<K>
    
    switch selectionMode {
    case .single:
      selections = self.selections.contains(key) ? [] : [key]
      
    case .multiple:
      selections = self.selections.contains(key) ? self.selections.subtracting([key]) : self.selections.union([key])
    }
    
    onSelectionsComputed.fire(selections)

  }

}

public enum SelectionMode {
  case single
  case multiple
}
