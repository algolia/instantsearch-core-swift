//
//  SelectableListViewModel.swift
//  InstantSearchCore
//
//  Created by Guy Daher on 18/04/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

typealias RefinementFacetsViewModel = SelectableListViewModel<String, FacetValue>

class SelectableListViewModel<K: Hashable, V: Equatable> {

  public var selectionMode: SelectionMode

  public init(selectionMode: SelectionMode) {
    self.selectionMode = selectionMode
  }

  public var refinementsListeners = Observer<[V]>()
  public var selectionsListeners = Observer<Set<K>>()
  public var selectedListeners = Observer<Set<K>>()

  public var values: [V] = [] {
    didSet {
      if oldValue != values {
        refinementsListeners.fire(values)
      }
    }
  }

  public var selections = Set<K>() {
    didSet {
      if oldValue != selections {
        selectionsListeners.fire(selections)
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

    selectionsListeners.fire(selections)
  }

}

public enum SelectionMode {
  case single
  case multiple
}

