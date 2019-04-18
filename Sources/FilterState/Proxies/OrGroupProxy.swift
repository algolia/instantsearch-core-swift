//
//  OrGroupProxy.swift
//  AlgoliaSearch OSX
//
//  Created by Vladislav Fitc on 24/12/2018.
//  Copyright © 2018 Algolia. All rights reserved.
//

import Foundation

/// Provides a specific type-safe interface for FilterState specialized for a disjunctive group

public struct OrGroupProxy<T: FilterType>: GroupProxy {
    
    let filterStateDSL: FilterStateDSL
    let groupID: FilterGroup.ID
    
    /// A Boolean value indicating whether group contains at least on filter
    public var isEmpty: Bool {
      return filterStateDSL.filters.getFilters(forGroupWithID: groupID).isEmpty
    }
    
    init(filterStateDSL: FilterStateDSL, groupName: String) {
        self.filterStateDSL = filterStateDSL
        self.groupID = .or(name: groupName)
    }
    
    /// Adds filter to group
    /// - parameter filter: filter to add
    public func add(_ filter: T) {
        filterStateDSL.filters.add(filter, toGroupWithID: groupID)
    }
    
    /// Adds the filters of a sequence to group
    /// - parameter filters: sequence of filters to add
    public func addAll<S: Sequence>(_ filters: S) where S.Element == T {
        filterStateDSL.filters.addAll(filters: filters, toGroupWithID: groupID)
    }
    
    /// Tests whether group contains a filter
    /// - parameter filter: sought filter
    public func contains(_ filter: T) -> Bool {
        return filterStateDSL.filters.contains(filter, inGroupWithID: groupID)
    }
    
    /// Removes all filters with specified attribute from group
    /// - parameter attribute: specified attribute
    public func removeAll(for attribute: Attribute) {
        return filterStateDSL.filters.removeAll(for: attribute, fromGroupWithID: groupID)
    }
    
    @discardableResult public func remove(_ filter: T) -> Bool {
        return filterStateDSL.filters.remove(filter, fromGroupWithID: groupID)
    }
    
    /// Removes a sequence of filters from group
    /// - parameter filters: sequence of filters to remove
    @discardableResult public func removeAll<S: Sequence>(_ filters: S) -> Bool where S.Element == T {
        return filterStateDSL.filters.removeAll(filters, fromGroupWithID: groupID)
    }
    
    /// Removes all filters in group
    public func removeAll() {
        filterStateDSL.filters.removeAll(fromGroupWithID: groupID)
    }
    
    /// Removes filter from group if contained by it, otherwise adds filter to group
    /// - parameter filter: filter to toggleE
    public func toggle(_ filter: T) {
        filterStateDSL.filters.toggle(filter, inGroupWithID: groupID)
    }
    
}
