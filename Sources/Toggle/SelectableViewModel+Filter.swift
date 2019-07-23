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
      connectTo(filterState, via: SpecializedAndGroupAccessor(filterState[and: groupName]))
    case .or:
      connectTo(filterState, via: filterState[or: groupName])
    }

  }
  
}

private extension SelectableInteractor where Item: FilterType {
  
  func connectTo<GroupAccessor: SpecializedGroupAccessor>(_ filterState: FilterState,
                                                          via accessor: GroupAccessor) where GroupAccessor.Filter == Item {
    whenFilterStateChangedThenUpdateSelections(filterState, via: accessor)
    whenSelectionsComputedThenUpdateFilterState(filterState, attribute: item.attribute, via: accessor)
  }
  
  func whenFilterStateChangedThenUpdateSelections<GroupAccessor: SpecializedGroupAccessor>(_ filterState: FilterState, via accessor: GroupAccessor) where GroupAccessor.Filter == Item {
    
    let onChange: (SelectableViewModel, ReadOnlyFiltersContainer) -> Void = {  viewModel, _ in
      viewModel.isSelected = accessor.contains(viewModel.item)
    }
    
    onChange(self, ReadOnlyFiltersContainer(filtersContainer: filterState))
    
    filterState.onChange.subscribePast(with: self, callback: onChange)
  }

  func whenSelectionsComputedThenUpdateFilterState<GroupAccessor: SpecializedGroupAccessor>(_ filterState: FilterState,
                                                                                            attribute: Attribute,
                                                                                            via accessor: GroupAccessor) where GroupAccessor.Filter == Item {
    
    onSelectedComputed.subscribePast(with: self) { [weak filterState] viewModel, computedSelected in
      
      guard
        let filterState = filterState
        else { return }
      
      if computedSelected {
        accessor.add(viewModel.item)
      } else {
        accessor.remove(viewModel.item)
      }
      
      filterState.notifyChange()
      
    }
    
  }
  
  func whenSelectionsComputedThenUpdateFilterState<F: FilterType>(_ filterState: FilterState,
                                                                  attribute: Attribute,
                                                                  groupID: FilterGroup.ID,
                                                                  default: F) {
    
    onSelectedComputed.subscribePast(with: self) { [weak filterState] viewModel, computedSelected in
      
      guard let filterState = filterState else { return }
      
      if computedSelected {
        filterState.filters.remove(`default`, fromGroupWithID: groupID)
        filterState.filters.add(viewModel.item, toGroupWithID: groupID)
      } else {
        filterState.filters.remove(viewModel.item, fromGroupWithID: groupID)
        filterState.filters.add(`default`, toGroupWithID: groupID)
      }
      
      filterState.notifyChange()
      
    }
    
  }

}

public extension SelectableInteractor where Item: FilterType {

  func connectController<C: SelectableController>(_ controller: C) where C.Item == Item {
    controller.setItem(item)
    controller.setSelected(isSelected)
    controller.onClick = computeIsSelected(selecting:)
    onSelectedChanged.subscribePast(with: controller) { controller, isSelected in
      controller.setSelected(isSelected)
    }
    onItemChanged.subscribePast(with: controller) { controller, item in
      controller.setItem(item)
    }
  }

}
