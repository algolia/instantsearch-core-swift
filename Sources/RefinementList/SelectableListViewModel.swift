//
//  SelectableListViewModel.swift
//  InstantSearchCore
//
//  Created by Guy Daher on 18/04/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

class SelectableListViewModel<K: Hashable, V: Equatable> {

  public var selectionMode: SelectionMode

  public init(selectionMode: SelectionMode) {
    self.selectionMode = selectionMode
  }

  public var onValuesChanged = Observer<[V]>()
  public var onSelectionsChanged = Observer<Set<K>>()
  public var onSelectedChanged = Observer<Set<K>>()

  public var values: [V] = [] {
    didSet {
      if oldValue != values {
        onValuesChanged.fire(values)
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

  public func select(key: K) {
    let selections: Set<K>
    switch selectionMode {
    case .single:
      selections = self.selections.contains(key) ? [] : [key]
    case .multiple:
      selections = self.selections.contains(key) ? self.selections.subtracting([key]) : self.selections.union([key])
    }

    onSelectionsChanged.fire(selections)
  }

}

public enum SelectionMode {
  case single
  case multiple
}
