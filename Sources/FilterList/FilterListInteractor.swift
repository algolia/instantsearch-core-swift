//
//  SelectableListInteractor+Filter.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 17/05/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public typealias FilterListInteractor<F: FilterType & Hashable> = SelectableListInteractor<F, F>

public extension SelectableListInteractor where Key == Item, Item: FilterType {
  
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

private extension SelectableListInteractor where Key == Item, Item: FilterType {
  
  func connectFilterState<Accessor: SpecializedGroupAccessor>(_ filterState: FilterState, via accessor: Accessor) where Accessor.Filter == Key {
    whenSelectionsComputedThenUpdateFilterState(filterState, via: accessor)
    whenFilterStateChangedThenUpdateSelections(filterState, via: accessor)
  }
  
  func whenSelectionsComputedThenUpdateFilterState<Accessor: SpecializedGroupAccessor>(_ filterState: FilterState,
                                                                                       via accessor: Accessor) where Accessor.Filter == Item {
    
    onSelectionsComputed.subscribePast(with: self) { [weak filterState] interactor, filters in
      
      switch interactor.selectionMode {
      case .multiple:
        accessor.removeAll()
        
      case .single:
        accessor.removeAll(interactor.items)
      }
      
      accessor.addAll(filters)
      
      filterState?.notifyChange()
    }
    
  }
  
  func whenFilterStateChangedThenUpdateSelections<Accessor: SpecializedGroupAccessor>(_ filterState: FilterState,
                                                                                      via accessor: Accessor) where Accessor.Filter == Item {

    filterState.onChange.subscribePast(with: self) { interactor, _ in
      interactor.selections = Set(accessor.filters())
    }
  }
  
}

public extension SelectableListInteractor where Key == Item, Item: FilterType {
  
  func connectController<C: SelectableListController>(_ controller: C) where C.Item == Item {
    
    func setControllerItemsWith(items: [Item], selections: Set<Key>) {
      let selectableItems = items.map { ($0, selections.contains($0)) }
      controller.setSelectableItems(selectableItems: selectableItems)
      controller.reload()
    }
    
    setControllerItemsWith(items: items, selections: selections)
    
    controller.onClick = computeSelections(selectingItemForKey:)
    
    onItemsChanged.subscribePast(with: self) { interactor, items in
      setControllerItemsWith(items: items, selections: interactor.selections)
    }
    
    onSelectionsChanged.subscribePast(with: self) { interactor, selections in
      setControllerItemsWith(items: interactor.items, selections: selections)
    }
    
  }
  
}
