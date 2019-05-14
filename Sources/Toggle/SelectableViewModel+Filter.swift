//
//  SelectableViewModel+Filter.swift
//  InstantSearchCore-iOS
//
//  Created by Vladislav Fitc on 06/05/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public extension SelectableViewModel where Item: FilterType {

  func connectFilterState(_ filterState: FilterState,
                                   operator: RefinementOperator = .or,
                                   groupName: String? = nil) {
    
    let groupID = FilterGroup.ID(groupName: groupName, attribute: item.attribute, operator: `operator`)
    
    whenSelectionsComputedThenUpdateFilterState(item.attribute, filterState, groupID)
    
    whenFilterStateChangedThenUpdateSelections(filterState, groupID: groupID)
  }
  
  func connectViewController<VC: SelectableViewController>(_ viewController: VC) {
    viewController.setSelected(isSelected)
    viewController.onClick = computeIsSelected(selecting:)
    onSelectedChanged.subscribe(with: viewController) { isSelected in
      viewController.setSelected(isSelected)
    }
  }
  
}

fileprivate extension SelectableViewModel where Item: FilterType {
  
  func whenSelectionsComputedThenUpdateFilterState(_ attribute: Attribute, _ filterState: FilterState, _ groupID: FilterGroup.ID) {
    
    onSelectedComputed.subscribe(with: self) { [weak self] selected in
      
      guard let item = self?.item else { return }
      
      filterState.notify { filterState in
        if selected {
          filterState.add(item, toGroupWithID: groupID)
        } else {
          filterState.remove(item)
        }
      }
      
    }
  }
  
  func whenFilterStateChangedThenUpdateSelections(_ filterState: FilterState, groupID: FilterGroup.ID) {
    let onChange: (FiltersReadable) -> Void = { [weak self] filterState in
      guard let filter = self?.item else { return }
      self?.isSelected = filterState.contains(filter, inGroupWithID: groupID)
    }
    
    onChange(filterState)
    
    filterState.onChange.subscribe(with: self, callback: onChange)
  }
  
}
