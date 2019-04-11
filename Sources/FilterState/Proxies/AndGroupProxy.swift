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
    
    let filterState: FilterState
    let group: AnyFilterGroup
    
    /// A Boolean value indicating whether group contains at least on filter
    public var isEmpty: Bool {
        if let filtersForGroup = filterState.groups[group] {
            return filtersForGroup.isEmpty
        } else {
            return true
        }
    }
    
    init(filterState: FilterState, group: AndFilterGroup) {
        self.filterState = filterState
        self.group = AnyFilterGroup(group)
    }
    
    /// Adds filter to group
    /// - parameter filter: filter to add
    public func add<T: FilterType>(_ filter: T) {
        filterState.add(filter, to: group)
    }
    
    /// Adds the filters of a sequence to group
    /// - parameter filters: sequence of filters to add
    public func addAll<T: FilterType, S: Sequence>(_ filters: S) where S.Element == T {
        filterState.addAll(filters: filters, to: group)
    }
    
    /// Tests whether group contains a filter
    /// - parameter filter: sought filter
    public func contains<T: FilterType>(_ filter: T) -> Bool {
        return filterState.contains(filter, in: group)
    }
    
    /// Removes filter from current group and adds it to destination conjunctive group
    /// - parameter filter: filter to move
    /// - parameter destination: target group
    /// - returns: true if movement succeeded, otherwise returns false
    public func move<T: FilterType>(_ filter: T, to destination: AndFilterGroup) -> Bool {
        return filterState.move(filter: filter, from: group, to: AnyFilterGroup(destination))
    }
    
    /// Removes filter from current group and adds it to destination disjunctive group
    /// - parameter filter: filter to move
    /// - parameter destination: target group
    /// - returns: true if movement succeeded, otherwise returns false
    public func move<T: FilterType>(_ filter: T, to destination: OrFilterGroup<T>) -> Bool {
        return filterState.move(filter: filter, from: group, to: AnyFilterGroup(destination))
    }
    
    /// Replaces all the attribute by a provided one in group
    /// - parameter attribute: attribute to replace
    /// - parameter replacement: replacement attribute
    public func replace(_ attribute: Attribute, by replacement: Attribute) {
        return filterState.replace(attribute, by: replacement, in: group)
    }
    
    /// Replaces filter in group by specified filter replacement
    /// - parameter filter: filter to replace
    /// - parameter replacement: filter replacement
    public func replace<T: FilterType, D: FilterType>(_ filter: T, by replacement: D) {
        return filterState.replace(filter: filter, by: replacement, in: group)
    }
    
    /// Removes all filters with specified attribute from group
    /// - parameter attribute: specified attribute
    public func removeAll(for attribute: Attribute) {
        return filterState.removeAll(for: attribute, from: group)
    }
    
    /// Removes filter from group
    /// - parameter filter: filter to remove
    @discardableResult public func remove<T: FilterType>(_ filter: T) -> Bool {
        return filterState.remove(filter, from: group)
    }
    
    /// Removes a sequence of filters from group
    /// - parameter filters: sequence of filters to remove
    @discardableResult public func removeAll<T: FilterType, S: Sequence>(_ filters: S) -> Bool where S.Element == T {
        return filterState.removeAll(filters, from: group)
    }
    
    /// Removes all filters in group
    public func removeAll() {
        filterState.removeAll(from: group)
    }
    
    /// Removes filter from group if contained by it, otherwise adds filter to group
    /// - parameter filter: filter to toggle
    public func toggle<T: FilterType>(_ filter: T) {
        filterState.toggle(filter, in: group)
    }

    /// Constructs a string representation of filters in group
    /// If group is empty returns nil
    /// - parameter ignoringInversion: if set to true, ignores any filter negation
    /// - # Example of generated string: "A":"V1" AND "B":"11" AND "C":"true"
    public func build(ignoringInversion: Bool = false) -> String? {
        return filterState.build(group, ignoringInversion: ignoringInversion)
    }

}
