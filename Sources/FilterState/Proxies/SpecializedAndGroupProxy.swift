//
//  SpecializedAndGroupProxy.swift
//  AlgoliaSearch OSX
//
//  Created by Vladislav Fitc on 26/12/2018.
//  Copyright © 2018 Algolia. All rights reserved.
//

import Foundation

/// Provides a specific type-safe interface for FilterState specialized for a conjunctive group specialized for filters of concrete type

public struct SpecializedAndGroupProxy<T: FilterType> {
    
    private let genericProxy: AndGroupProxy
    
    var groupID: AnyFilterGroupID {
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
    public func add(_ filter: T) {
        genericProxy.add(filter)
    }
    
    /// Adds the filters of a sequence to group
    /// - parameter filters: sequence of filters to add
    public func addAll<T: FilterType, S: Sequence>(_ filters: S) where S.Element == T {
        genericProxy.addAll(filters)
    }
    
    /// Tests whether group contains a filter
    /// - parameter filter: sought filter
    public func contains(_ filter: T) -> Bool {
        return genericProxy.contains(filter)
    }
    
    /// Removes filter from current group and adds it to destination conjunctive group
    /// - parameter filter: filter to move
    /// - parameter destination: target group
    /// - returns: true if movement succeeded, otherwise returns false
    public func move(_ filter: T, to destination: FilterGroup.And.ID) -> Bool {
        return genericProxy.move(filter, to: destination)
    }
    
    /// Removes filter from current group and adds it to destination disjunctive group
    /// - parameter filter: filter to move
    /// - parameter destination: target group
    /// - returns: true if movement succeeded, otherwise returns false
    public func move(_ filter: T, to destination: FilterGroup.Or<T>.ID) -> Bool {
        return genericProxy.move(filter, to: destination)
    }
    
    /// Removes all filters with specified attribute from group
    /// - parameter attribute: specified attribute
    public func removeAll(for attribute: Attribute) {
        return genericProxy.removeAll(for: attribute)
    }
    
    /// Removes filter from group
    /// - parameter filter: filter to remove
    @discardableResult public func remove(_ filter: T) -> Bool {
        return genericProxy.remove(filter)
    }
    
    /// Removes a sequence of filters from group
    /// - parameter filters: sequence of filters to remove
    @discardableResult public func removeAll<S: Sequence>(_ filters: S) -> Bool where S.Element == T {
        return genericProxy.removeAll(filters)
    }
    
    /// Removes all filters in group
    public func removeAll() {
        genericProxy.removeAll()
    }
    
    /// Removes filter from group if contained by it, otherwise adds filter to group
    /// - parameter filter: filter to toggle
    public func toggle(_ filter: T) {
        genericProxy.toggle(filter)
    }
    
}
