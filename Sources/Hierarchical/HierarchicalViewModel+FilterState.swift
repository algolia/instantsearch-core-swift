//
//  HierarchicalViewModel+FilterState.swift
//  InstantSearchCore
//
//  Created by Guy Daher on 03/07/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public extension HierarchicalViewModel {

  func connectFilterState(_ filterState: FilterState, groupName: String? = nil) {
    
    let groupName = groupName ?? hierarchicalAttributes.first?.description ?? "_hierarchical"
    let filterGroupID = FilterGroup.ID.hierarchical(name: groupName)

    filterState.hierarchical(name: groupName).set(hierarchicalAttributes)

    onSelectionsComputed.subscribePast(with: self) { (selections) in

      self.selections = selections.map { $0.value.description }

      filterState.removeAll(fromGroupWithID: filterGroupID)

      guard let lastSelectedFilter = selections.last else {
        filterState.hierarchical(name: groupName).set([Filter.Facet]())
        return
      }

      filterState.add(lastSelectedFilter, toGroupWithID: filterGroupID)
      filterState.hierarchical(name: groupName).set(selections)
      filterState.notifyChange()

    }

    filterState.onChange.subscribePast(with: self) { (filters) in
      // TODO
    }
  }
}
