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
    
    let groupName = groupName ?? item.attribute.name
    let groupID: FilterGroup.ID
    
    switch `operator` {
    case .and:
      groupID = .and(name: groupName)
      
    case .or:
      switch Item.self {
      case is Filter.Facet.Type:
        groupID = .or(name: groupName, filterType: .facet)
      case is Filter.Numeric.Type:
        groupID = .or(name: groupName, filterType: .numeric)
      case is Filter.Tag.Type:
        groupID = .or(name: groupName, filterType: .tag)
      default:
        return
      }
    }

    whenSelectionsComputedThenUpdateFilterState(filterState, attribute: item.attribute, groupID: groupID)
    whenFilterStateChangedThenUpdateSelections(filterState, groupID: groupID)
  }
  
//  func connectTo<F: FilterType>(_ filterState: FilterState,
//                                operator: RefinementOperator = .or,
//                                groupName: String? = nil,
//                                default: F) {
//    
//    let groupName = groupName ?? item.attribute.name
//    let groupID: FilterGroup.ID
//    
//    switch `operator` {
//    case .and:
//      groupID = .and(name: groupName)
//      
//    case .or:
//      switch Item.self {
//      case is Filter.Facet.Type:
//        groupID = .or(name: groupName, filterType: .facet)
//      case is Filter.Numeric.Type:
//        groupID = .or(name: groupName, filterType: .numeric)
//      case is Filter.Tag.Type:
//        groupID = .or(name: groupName, filterType: .tag)
//      default:
//        return
//      }
//    }
//
//    whenSelectionsComputedThenUpdateFilterState(filterState, attribute: item.attribute, groupID: groupID, default: `default`)
//    whenFilterStateChangedThenUpdateSelections(filterState, groupID: groupID)
//    filterState.notify(.add(filter: `default`, toGroupWithID: groupID))
//  }
  
}

private extension SelectableViewModel where Item: FilterType {
  
  func whenFilterStateChangedThenUpdateSelections(_ filterState: FilterState, groupID: FilterGroup.ID) {
    
    let onChange: (FiltersReadable) -> Void = { [weak self] filterState in
      guard let filter = self?.item else { return }
      self?.isSelected = filterState.contains(filter, inGroupWithID: groupID)
    }
    
    onChange(filterState.filters)
    
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
        filterState.filters.add(item, toGroupWithID: groupID)
      } else {
        filterState.filters.remove(item, fromGroupWithID: groupID)
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
        filterState.filters.remove(`default`, fromGroupWithID: groupID)
        filterState.filters.add(item, toGroupWithID: groupID)
      } else {
        filterState.filters.remove(item, fromGroupWithID: groupID)
        filterState.filters.add(`default`, toGroupWithID: groupID)
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
