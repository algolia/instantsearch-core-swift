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

//public extension FiltersContainer {
//  
//  func and(_ groupName: String) -> AndGroupProxy {
//    return AndGroupProxy(filtersContainer: self, groupName: groupName)
//  }
//  
//  func or <F: FilterType>(_ groupName: String, type: F.Type) -> OrGroupProxy<F> {
//    return OrGroupProxy(filtersContainer: self, groupName: groupName)
//  }
//  
//  func or <F: FilterType>(_ groupName: String) -> OrGroupProxy<F> {
//    return OrGroupProxy(filtersContainer: self, groupName: groupName)
//  }
//  
//  func hierarchical(_ groupName: String) -> SpecializedAndGroupProxy<Filter.Facet> {
//    return SpecializedAndGroupProxy(genericProxy: AndGroupProxy(filtersContainer: self, groupName: groupName))
//  }
//  
//}

/// Group proxy provides a specific type-safe interface for FilterState specialized for a concrete group
internal protocol GroupProxy {
    var filtersContainer: FiltersContainer { get }
    var groupID: FilterGroup.ID { get }
}
