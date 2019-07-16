//
//  FiltersReadable.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 16/07/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public protocol FiltersReadable {
  
  /// A Boolean value indicating whether FilterState contains at least on filter
  
  var isEmpty: Bool { get }
  
  /// Tests whether FilterState contains a filter
  /// - parameter filter: desired filter
  
  func contains(_ filter: FilterType) -> Bool
  
  /// Checks whether specified group contains a filter
  /// - parameter filter: filter to check
  /// - parameter groupID: target group ID
  /// - returns: true if filter is contained by specified group
  
  func contains(_ filter: FilterType, inGroupWithID groupID: FilterGroup.ID) -> Bool
  
  /// Returns a set of filters in group with specified ID
  /// - parameter groupID: target group ID
  
  func getGroupIDs() -> Set<FilterGroup.ID>
  
  /// Returns a set of filters for attribute
  /// - parameter attribute: target attribute
  
  func getFilters(forGroupWithID groupID: FilterGroup.ID) -> Set<Filter>
  
  
  func getFilters(for attribute: Attribute) -> Set<Filter>
  func getFiltersAndID() -> Set<FilterAndID>
  
  /// Returns a set of all the filters contained by all the groups
  func getFilters() -> Set<Filter>
  
}

public extension FiltersReadable {
  
  func contains(_ filter: FilterType) -> Bool {
    return getGroupIDs().anySatisfy { self.contains(filter, inGroupWithID: $0) }
  }
  
}

extension FiltersReadable {
  
  var disjunctiveFacetsAttributes: Set<Attribute> {
    let attributes = getGroupIDs()
      .filter { groupID in
        switch groupID {
        case .or(_, .facet):
          return true
        default:
          return false
        }
      }
      .map(self.getFilters(forGroupWithID:))
      .flatMap({ $0 })
      .map { $0.attribute }
    return Set(attributes)
  }
  
}
