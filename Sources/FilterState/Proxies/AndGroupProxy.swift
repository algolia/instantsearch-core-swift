//
//  AndGroupProxy.swift
//  AlgoliaSearch OSX
//
//  Created by Vladislav Fitc on 24/12/2018.
//  Copyright © 2018 Algolia. All rights reserved.
//

import Foundation

/// Provides a specific type-safe interface for FilterState specialized for a conjunctive group

public struct AndGroupProxy: GroupProxy {
    
    let filterStateDSL: FilterStateDSL
    let groupID: FilterGroup.ID
    
    /// A Boolean value indicating whether group contains at least on filter
    public var isEmpty: Bool {
        if let filtersForGroup = filterStateDSL.filterState.groups[groupID] {
            return filtersForGroup.isEmpty
        } else {
            return true
        }
    }
    
    init(filterStateDSL: FilterStateDSL, groupName: String) {
        self.filterStateDSL = filterStateDSL
        self.groupID = .and(name: groupName)
    }
    
    /// Adds filter to group
    /// - parameter filter: filter to add
    public func add<T: FilterType>(_ filter: T) {
        filterStateDSL.filterState.add(filter, toGroupWithID: groupID)
    }
    
    /// Adds the filters of a sequence to group
    /// - parameter filters: sequence of filters to add
    public func addAll<T: FilterType, S: Sequence>(_ filters: S) where S.Element == T {
        filterStateDSL.filterState.addAll(filters: filters, toGroupWithID: groupID)
    }
    
    /// Tests whether group contains a filter
    /// - parameter filter: sought filter
    public func contains<T: FilterType>(_ filter: T) -> Bool {
        return filterStateDSL.filterState.contains(filter, inGroupWithID: groupID)
    }
    
    /// Removes all filters with specified attribute from group
    /// - parameter attribute: specified attribute
    public func removeAll(for attribute: Attribute) {
        return filterStateDSL.filterState.removeAll(for: attribute, fromGroupWithID: groupID)
    }
    
    /// Removes filter from group
    /// - parameter filter: filter to remove
    @discardableResult public func remove<T: FilterType>(_ filter: T) -> Bool {
        return filterStateDSL.filterState.remove(filter, fromGroupWithID: groupID)
    }
    
    /// Removes a sequence of filters from group
    /// - parameter filters: sequence of filters to remove
    @discardableResult public func removeAll<T: FilterType, S: Sequence>(_ filters: S) -> Bool where S.Element == T {
        return filterStateDSL.filterState.removeAll(filters, fromGroupWithID: groupID)
    }
    
    /// Removes all filters in group
    public func removeAll() {
        filterStateDSL.filterState.removeAll(fromGroupWithID: groupID)
    }
    
    /// Removes filter from group if contained by it, otherwise adds filter to group
    /// - parameter filter: filter to toggle
    public func toggle<T: FilterType>(_ filter: T) {
        filterStateDSL.filterState.toggle(filter, inGroupWithID: groupID)
    }

}
