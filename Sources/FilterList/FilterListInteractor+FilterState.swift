//
//  FilterListInteractor+FilterState.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 02/08/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

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
