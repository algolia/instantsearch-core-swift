//
//  SelectableInteractor+Filter.swift
//  InstantSearchCore-iOS
//
//  Created by Vladislav Fitc on 06/05/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public extension SelectableInteractor where Item: FilterType {

  func connectFilterState(_ filterState: FilterState,
                          operator: RefinementOperator = .or,
                          groupName: String? = nil) {
    
    let groupName = groupName ?? item.attribute.name
    
    switch `operator` {
    case .and:
      connectFilterState(filterState, via: SpecializedAndGroupAccessor(filterState[and: groupName]))
    case .or:
      connectFilterState(filterState, via: filterState[or: groupName])
    }

  }
  
}

private extension SelectableInteractor where Item: FilterType {
  
  func connectFilterState<GroupAccessor: SpecializedGroupAccessor>(_ filterState: FilterState,
                                                                   via accessor: GroupAccessor) where GroupAccessor.Filter == Item {
    whenFilterStateChangedThenUpdateSelections(filterState, via: accessor)
    whenSelectionsComputedThenUpdateFilterState(filterState, attribute: item.attribute, via: accessor)
  }
  
  func whenFilterStateChangedThenUpdateSelections<GroupAccessor: SpecializedGroupAccessor>(_ filterState: FilterState, via accessor: GroupAccessor) where GroupAccessor.Filter == Item {
    
    let onChange: (SelectableInteractor, ReadOnlyFiltersContainer) -> Void = {  interactor, _ in
      interactor.isSelected = accessor.contains(interactor.item)
    }
    
    onChange(self, ReadOnlyFiltersContainer(filtersContainer: filterState))
    
    filterState.onChange.subscribePast(with: self, callback: onChange)
  }

  func whenSelectionsComputedThenUpdateFilterState<GroupAccessor: SpecializedGroupAccessor>(_ filterState: FilterState,
                                                                                            attribute: Attribute,
                                                                                            via accessor: GroupAccessor) where GroupAccessor.Filter == Item {
    
    onSelectedComputed.subscribePast(with: self) { [weak filterState] interactor, computedSelected in
      
      guard
        let filterState = filterState
        else { return }
      
      if computedSelected {
        accessor.add(interactor.item)
      } else {
        accessor.remove(interactor.item)
      }
      
      filterState.notifyChange()
      
    }
    
  }
  
  func whenSelectionsComputedThenUpdateFilterState<F: FilterType>(_ filterState: FilterState,
                                                                  attribute: Attribute,
                                                                  groupID: FilterGroup.ID,
                                                                  default: F) {
    
    onSelectedComputed.subscribePast(with: self) { [weak filterState] interactor, computedSelected in
      
      guard let filterState = filterState else { return }
      
      if computedSelected {
        filterState.filters.remove(`default`, fromGroupWithID: groupID)
        filterState.filters.add(interactor.item, toGroupWithID: groupID)
      } else {
        filterState.filters.remove(interactor.item, fromGroupWithID: groupID)
        filterState.filters.add(`default`, toGroupWithID: groupID)
      }
      
      filterState.notifyChange()
      
    }
    
  }

}
