//
//  FilterState+FiltersReadable.swift
//  InstantSearchCore-iOS
//
//  Created by Vladislav Fitc on 19/07/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

extension FilterState: FiltersReadable {
  
  public func getGroupIDs() -> Set<FilterGroup.ID> {
    return filters.getGroupIDs()
  }
  
  public var isEmpty: Bool {
    return self.filters.isEmpty
  }
  
  public func contains(_ filter: FilterType, inGroupWithID groupID: FilterGroup.ID) -> Bool {
    return self.filters.contains(filter, inGroupWithID: groupID)
  }
  
  public func getFilters(forGroupWithID groupID: FilterGroup.ID) -> Set<Filter> {
    return self.filters.getFilters(forGroupWithID: groupID)
  }
  
  public func getFilters(for attribute: Attribute) -> Set<Filter> {
    return self.filters.getFilters(for: attribute)
  }
  
  public func getFilters() -> Set<Filter> {
    return self.filters.getFilters()
  }
  
  public func getFiltersAndID() -> Set<FilterAndID> {
    return self.filters.getFiltersAndID()
  }
  
}
