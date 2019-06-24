//
//  SelectableListViewModel+Filter.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 17/05/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public typealias FilterListViewModel<F: FilterType & Hashable> = SelectableListViewModel<F, F>

public extension SelectableListViewModel where Key == Item, Item: FilterType {
  
  func connectFilterState(_ filterState: FilterState,
                          groupName: String = "",
                          operator: RefinementOperator) {
    
    let groupID: FilterGroup.ID
    
    switch `operator` {
    case .or:
      groupID = .or(name: groupName)
      
    case .and:
      groupID = .and(name: groupName)
    }
    
    whenSelectionsComputedThenUpdateFilterState(filterState, groupID)
    whenFilterStateChangedThenUpdateSelections(filterState, groupID: groupID)
  }
  
}

private extension SelectableListViewModel where Key == Item, Item: FilterType {
  
  func whenSelectionsComputedThenUpdateFilterState(_ filterState: FilterState, _ groupID: FilterGroup.ID) {
    
    onSelectionsComputed.subscribePast(with: self) { filters in
      
      let removeCommand: FilterState.Command
      
      switch self.selectionMode {
      case .multiple:
        removeCommand = .removeAll(fromGroupWithID: groupID)
        
      case .single:
        removeCommand = .remove(filters: self.items, fromGroupWithID: groupID)
      }
      
      let addCommand: FilterState.Command = .add(filters: filters, toGroupWithID: groupID)
      
      filterState.notify(removeCommand, addCommand)
      
    }
    
  }
  
  func whenFilterStateChangedThenUpdateSelections(_ filterState: FilterState, groupID: FilterGroup.ID) {
    
    let onChange: (FiltersReadable) -> Void = { filters in
      self.selections = Set(filters.getFilters(forGroupWithID: groupID).compactMap { $0.filter as? Key })
    }
    
    onChange(filterState.filters)
    
    filterState.onChange.subscribePast(with: self, callback: onChange)
  }
  
}

public extension SelectableListViewModel where Key == Item, Item: FilterType {
  
  func connect<C: SelectableListController>(to controller: C) where C.Item == Item {
    
    func setControllerItemsWith(items: [Item], selections: Set<Key>) {
      let selectableItems = items.map { ($0, selections.contains($0)) }
      controller.setSelectableItems(selectableItems: selectableItems)
      controller.reload()
    }
    
    setControllerItemsWith(items: items, selections: selections)
    
    controller.onClick = computeSelections(selectingItemForKey:)
    
    onItemsChanged.subscribePast(with: self) { [weak self] items in
      guard let selections = self?.selections else { return }
      setControllerItemsWith(items: items, selections: selections)
    }
    
    onSelectionsChanged.subscribePast(with: self) { [weak self] selections in
      guard let tags = self?.items else { return }
      setControllerItemsWith(items: tags, selections: selections)
    }
    
  }
  
}
