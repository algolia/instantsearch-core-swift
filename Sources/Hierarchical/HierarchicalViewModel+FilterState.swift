//
//  HierarchicalViewModel+FilterState.swift
//  InstantSearchCore
//
//  Created by Guy Daher on 03/07/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public extension HierarchicalViewModel {
  func connectFilterState(_ filterState: FilterState, attribute: Attribute) {
    let filterGroupID = FilterGroup.ID(attribute: attribute, operator: .and)

    filterState.hierarchicalAttributes = hierarchicalAttributes

    onSelectionsComputed.subscribePast(with: self) { (selections) in

      filterState.removeAll(fromGroupWithID: filterGroupID)

      guard let lastSelectedFilter = selections.last else {
        filterState.hierarchicalFilters = []
        return
      }

      filterState.add(lastSelectedFilter, toGroupWithID: filterGroupID)
      filterState.hierarchicalFilters = selections
      filterState.notifyChange()

    }

    filterState.onChange.subscribePast(with: self) { (filters) in
      // TODO
    }
  }
}
