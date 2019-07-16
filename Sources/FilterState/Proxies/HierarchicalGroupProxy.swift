//
//  HierarchicalGroupProxy.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 12/07/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public struct HierarchicalGroupProxy {
  
  let groupID: FilterGroup.ID
  var filtersContainer: FiltersContainer
  
  var hierarchicalAttributes: [Attribute] {
    return filtersContainer.filters.hierarchicalAttributes(forGroupWithName: groupID.name)
  }
  
  var hierarchicalFilters: [Filter.Facet] {
    return filtersContainer.filters.hierarchicalFilters(forGroupWithName: groupID.name)
  }
  
  func set(_ hierarchicalAttributes: [Attribute]) {
    filtersContainer.filters.set(hierarchicalAttributes, forGroupWithName: groupID.name)
  }
  
  func set(_ hierarchicalFilters: [Filter.Facet]) {
    filtersContainer.filters.set(hierarchicalFilters, forGroupWithName: groupID.name)
  }

  init(filtersContainer: FiltersContainer, groupName: String) {
    self.filtersContainer = filtersContainer
    self.groupID = .hierarchical(name: groupName)
  }
  
}
