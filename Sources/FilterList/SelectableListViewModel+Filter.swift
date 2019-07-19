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
                          operator: RefinementOperator,
                          groupName: String = "") {
    switch `operator` {
    case .or:
      connectFilterState(filterState, via: filterState[or: groupName])
    case .and:
      connectFilterState(filterState, via: SpecializedAndGroupAccessor(filterState[and: groupName]))
    }
  }
  
}

private extension SelectableListViewModel where Key == Item, Item: FilterType {
  
  func connectFilterState<Accessor: SpecializedGroupAccessor>(_ filterState: FilterState, via accessor: Accessor) where Accessor.Filter == Key {
    whenSelectionsComputedThenUpdateFilterState(filterState, via: accessor)
    whenFilterStateChangedThenUpdateSelections(filterState, via: accessor)
  }
  
  func whenSelectionsComputedThenUpdateFilterState<Accessor: SpecializedGroupAccessor>(_ filterState: FilterState,
                                                                                       via accessor: Accessor) where Accessor.Filter == Item {
    
    onSelectionsComputed.subscribePast(with: self) { [weak filterState] filters in
      
      switch self.selectionMode {
      case .multiple:
        accessor.removeAll()
        
      case .single:
        accessor.removeAll(self.items)
      }
      
      accessor.addAll(filters)
      
      filterState?.notifyChange()
    }
    
  }
  
  func whenFilterStateChangedThenUpdateSelections<Accessor: SpecializedGroupAccessor>(_ filterState: FilterState,
                                                                                      via accessor: Accessor) where Accessor.Filter == Item {

    filterState.onChange.subscribePast(with: self) { _ in
      self.selections = Set(accessor.filters())
    }
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
