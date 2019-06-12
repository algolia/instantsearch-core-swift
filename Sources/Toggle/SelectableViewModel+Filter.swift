//
//  SelectableViewModel+Filter.swift
//  InstantSearchCore-iOS
//
//  Created by Vladislav Fitc on 06/05/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public extension SelectableViewModel where Item: FilterType {

  func connectTo(_ filterState: FilterState,
                 operator: RefinementOperator = .or,
                 groupName: String? = nil) {
    
    let groupID = FilterGroup.ID(groupName: groupName,
                                 attribute: item.attribute,
                                 operator: `operator`)
    
    whenSelectionsComputedThenUpdateFilterState(filterState, attribute: item.attribute, groupID: groupID)
    whenFilterStateChangedThenUpdateSelections(filterState, groupID: groupID)
  }
  
  func connectTo<F: FilterType>(_ filterState: FilterState,
                 operator: RefinementOperator = .or,
                 groupName: String? = nil,
                 default: F) {
    
    let groupID = FilterGroup.ID(groupName: groupName,
                                 attribute: item.attribute,
                                 operator: `operator`)
    
    whenSelectionsComputedThenUpdateFilterState(filterState, attribute: item.attribute, groupID: groupID, default: `default`)
    whenFilterStateChangedThenUpdateSelections(filterState, groupID: groupID)
    filterState.notify(.add(filter: `default`, toGroupWithID: groupID))
  }
  
}



private extension SelectableViewModel where Item: FilterType {
  
  func whenFilterStateChangedThenUpdateSelections(_ filterState: FilterState, groupID: FilterGroup.ID) {
    
    let onChange: (FiltersReadable) -> Void = { [weak self] filterState in
      guard let filter = self?.item else { return }
      self?.isSelected = filterState.contains(filter, inGroupWithID: groupID)
    }
    
    onChange(filterState)
    
    filterState.onChange.subscribePast(with: self, callback: onChange)
  }

  
  func whenSelectionsComputedThenUpdateFilterState(_ filterState: FilterState,
                                                           attribute: Attribute,
                                                           groupID: FilterGroup.ID) {
    
    onSelectedComputed.subscribePast(with: self) { [weak self, weak filterState] computedSelected in
      
      guard
        let item = self?.item,
        let filterState = filterState
        else { return }
      
      if computedSelected {
        filterState.add(item, toGroupWithID: groupID)
      } else {
        filterState.remove(item, fromGroupWithID: groupID)
      }
      
      filterState.notifyChange()
      
    }
    
  }
  
  func whenSelectionsComputedThenUpdateFilterState<F: FilterType>(_ filterState: FilterState,
                                                                          attribute: Attribute,
                                                                          groupID: FilterGroup.ID,
                                                                          default: F) {
    
    onSelectedComputed.subscribePast(with: self) { [weak self, weak filterState] computedSelected in
      
      guard
        let item = self?.item,
        let filterState = filterState
        else { return }
      
      if computedSelected {
        filterState.remove(`default`, fromGroupWithID: groupID)
        filterState.add(item, toGroupWithID: groupID)
      } else {
        filterState.remove(item, fromGroupWithID: groupID)
        filterState.add(`default`, toGroupWithID: groupID)
      }
      
      filterState.notifyChange()
      
    }
    
  }

  
}

public extension SelectableViewModel where Item: FilterType {

  func connectController<C: SelectableController>(_ controller: C) where C.Item == Item {
    controller.setItem(item)
    controller.setSelected(isSelected)
    controller.onClick = computeIsSelected(selecting:)
    onSelectedChanged.subscribePast(with: controller, callback: controller.setSelected)
    onItemChanged.subscribePast(with: controller, callback: controller.setItem)
  }

}
