//
//  HierarchicalViewModel+FilterState.swift
//  InstantSearchCore
//
//  Created by Guy Daher on 03/07/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public extension HierarchicalViewModel {

  func connectFilterState(_ filterState: FilterState) {
    
    let groupName = "_hierarchical"

    filterState[hierarchical: groupName].set(hierarchicalAttributes)

    onSelectionsComputed.subscribePast(with: self) { (selections) in

      self.selections = selections.map { $0.value.description }

      filterState[hierarchical: groupName].removeAll()

      guard let lastSelectedFilter = selections.last else {
        filterState[hierarchical: groupName].set([Filter.Facet]())
        return
      }

      filterState[hierarchical: groupName].add(lastSelectedFilter)
      filterState[hierarchical: groupName].set(selections)
      filterState.notifyChange()

    }

    filterState.onChange.subscribePast(with: self) { (filters) in
      // TODO
    }
  }
}
