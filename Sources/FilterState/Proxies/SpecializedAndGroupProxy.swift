//
//  SpecializedAndGroupProxy.swift
//  AlgoliaSearch OSX
//
//  Created by Vladislav Fitc on 26/12/2018.
//  Copyright © 2018 Algolia. All rights reserved.
//

import Foundation

/// Provides a specific type-safe interface for FilterState specialized for a conjunctive group specialized for filters of concrete type

public struct SpecializedAndGroupProxy<T: FilterType>: GroupProxy {
    
    private var genericProxy: AndGroupProxy
  
    var filtersContainer: FiltersContainer {
      return genericProxy.filtersContainer
    }
    
    var groupID: FilterGroup.ID {
        return genericProxy.groupID
    }
    
    /// A Boolean value indicating whether group contains at least on filter
    public var isEmpty: Bool {
        return genericProxy.isEmpty
    }
    
    init(genericProxy: AndGroupProxy) {
        self.genericProxy = genericProxy
    }
    
    /// Adds filter to group
    /// - parameter filter: filter to add
    public mutating func add(_ filter: T) {
        genericProxy.add(filter)
    }
    
    /// Adds the filters of a sequence to group
    /// - parameter filters: sequence of filters to add
    public mutating func addAll<S: Sequence>(_ filters: S) where S.Element == FilterType {
        genericProxy.addAll(filters)
    }
    
    /// Tests whether group contains a filter
    /// - parameter filter: sought filter
    public func contains(_ filter: T) -> Bool {
        return genericProxy.contains(filter)
    }
    
    /// Removes all filters with specified attribute from group
    /// - parameter attribute: specified attribute
    public mutating func removeAll(for attribute: Attribute) {
        return genericProxy.removeAll(for: attribute)
    }
    
    /// Removes filter from group
    /// - parameter filter: filter to remove
    @discardableResult public mutating func remove(_ filter: T) -> Bool {
        return genericProxy.remove(filter)
    }
    
    /// Removes a sequence of filters from group
    /// - parameter filters: sequence of filters to remove
    @discardableResult public mutating func removeAll<S: Sequence>(_ filters: S) -> Bool where S.Element == T {
        return genericProxy.removeAll(filters.map { $0 as FilterType })
    }
    
    /// Removes all filters in group
    public mutating func removeAll() {
        genericProxy.removeAll()
    }
    
    /// Removes filter from group if contained by it, otherwise adds filter to group
    /// - parameter filter: filter to toggle
    public mutating func toggle(_ filter: T) {
        genericProxy.toggle(filter)
    }
    
}
