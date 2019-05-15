//
//  SelectableListViewModel.swift
//  InstantSearchCore
//
//  Created by Guy Daher on 18/04/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation


public enum FilterListViewModel {

  typealias Facet = SelectableListViewModel<Filter.Facet, Filter.Facet>
  typealias Numeric = SelectableListViewModel<Filter.Numeric, Filter.Numeric>
  typealias Tag = SelectableListViewModel<Filter.Tag, Filter.Tag>

}

public extension FilterListViewModel.Facet {

  convenience init(items: [Item] = []) {
    self.init(items: items, selectionMode: .multiple)
  }

  func connectFilterState(_ filterState: FilterState, groupID: FilterGroup.ID) {
    connectFilterState(filterState, filterType: Filter.Facet.self, groupID: groupID)
  }

}

public extension FilterListViewModel.Numeric {

  convenience init(items: [Item] = []) {
    self.init(items: items, selectionMode: .single)
  }

  func connectFilterState(_ filterState: FilterState, groupID: FilterGroup.ID) {
    connectFilterState(filterState, filterType: Filter.Numeric.self, groupID: groupID)
  }

}

public extension FilterListViewModel.Tag {

  convenience init(items: [Item] = []) {
    self.init(items: items, selectionMode: .multiple)
  }

  func connectFilterState(_ filterState: FilterState, groupID: FilterGroup.ID) {
    connectFilterState(filterState, filterType: Filter.Tag.self, groupID: groupID)
  }

}

extension SelectableListViewModel where K: FilterType, Item: FilterType {

  func connectFilterState<F: FilterType>(_ filterState: FilterState, filterType: F.Type, groupID: FilterGroup.ID) {
    onSelectionsComputed.subscribe(with: self) { filters in

      let removeCommand: FilterState.Command
      
      switch self.selectionMode {
      case .multiple:
        removeCommand = .removeAll(fromGroupWithID: groupID)

      case .single:
        let filters = self.items.compactMap { $0 as? F }
        removeCommand = .remove(filters: filters, fromGroupWithID: groupID)
      }

      let selections = self.selections.compactMap { $0 as? F }

      let addCommand: FilterState.Command = .add(filters: selections, toGroupWithID: groupID)

      filterState.notify(removeCommand, addCommand)

    }

    let onChange: (FiltersReadable) -> Void = { filters in
      self.selections = Set(filters.getFilters(forGroupWithID: groupID).compactMap { $0 as? K })
    }

    onChange(filterState.filters)

    filterState.onChange.subscribe(with: self, callback: onChange)

  }

}

public class SelectableListViewModel<K: Hashable, Item: Equatable> {

  public var selectionMode: SelectionMode

  public init(items: [Item] = [], selectionMode: SelectionMode) {
    self.items = items
    self.selectionMode = selectionMode
  }

  public var onItemsChanged = Observer<[Item]>()
  public var onSelectionsChanged = Observer<Set<K>>()
  public var onSelectionsComputed = Observer<Set<K>>()

  public var items: [Item] {
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
