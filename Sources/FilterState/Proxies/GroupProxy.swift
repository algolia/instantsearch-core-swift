//
//  GroupProxy.swift
//  AlgoliaSearch OSX
//
//  Created by Vladislav Fitc on 24/12/2018.
//  Copyright © 2018 Algolia. All rights reserved.
//

import Foundation

public protocol FiltersContainer: class {
  var filters: FiltersReadable & FiltersWritable & FilterGroupsConvertible & HierarchicalManageable { get set }
}

public extension FiltersContainer {
  
  subscript(and groupName: String) -> AndGroupProxy {
    return .init(filtersContainer: self, groupName: groupName)
  }
  
  subscript<F: FilterType>(or groupName: String, type: F.Type) -> OrGroupProxy<F> {
    return .init(filtersContainer: self, groupName: groupName)
  }
  
  subscript<F: FilterType>(or groupName: String) -> OrGroupProxy<F> {
    return .init(filtersContainer: self, groupName: groupName)
  }
  
  subscript(hierarchical groupName: String) -> HierarchicalGroupProxy {
    return .init(filtersContainer: self, groupName: groupName)
  }
}

/// Group proxy provides a specific type-safe interface for FilterState specialized for a concrete group
internal protocol GroupProxy {
    var filtersContainer: FiltersContainer { get }
    var groupID: FilterGroup.ID { get }
  
  var isEmpty: Bool { get }
    
}
