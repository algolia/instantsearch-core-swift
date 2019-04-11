//
//  FilterState.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 10/04/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public class FilterState {
  
  var groups: [AnyFilterGroupID: Set<Filter>]
  
  public func getFilterGroups() -> [FilterGroupType] {
    
    func extractOrGroup<F: FilterType>(from id: AnyFilterGroupID, with filters: Set<Filter>) -> FilterGroup.Or<F>? {
      if let _: OrFilterGroupID<F> = id.extractAs() {
        return FilterGroup.Or(filters: filters.map { $0.filter }.compactMap { $0 as? F })
      } else {
        return nil
      }
    }
    
    func filterGroup(with id: AnyFilterGroupID, filters: Set<Filter>) -> FilterGroupType? {
            
      if let _: AndFilterGroupID = id.extractAs() {
        return FilterGroup.And(filters.map { $0.filter})
      } else if let tagGroup: FilterGroup.Or<Filter.Tag> = extractOrGroup(from: id, with: filters) {
        return tagGroup
      } else if let facetGroup: FilterGroup.Or<Filter.Facet> = extractOrGroup(from: id, with: filters) {
        return facetGroup
      } else if let numericGroup: FilterGroup.Or<Filter.Numeric> = extractOrGroup(from: id, with: filters) {
        return numericGroup
      } else {
        return nil
      }
      
    }
    
    return groups.compactMap(filterGroup)
    
  }
  
  public init() {
    self.groups = [:]
  }
  
  public init(_ filterState: FilterState) {
    self.groups = filterState.groups
  }
  
  private func update(_ filters: Set<Filter>, for group: AnyFilterGroupID) {
    groups[group] = filters.isEmpty ? nil : filters
  }
  
  func add<T: FilterType>(_ filter: T, to group: AnyFilterGroupID) {
    addAll(filters: [filter], to: group)
  }
  
  func addAll<T: FilterType, S: Sequence>(filters: S, to group: AnyFilterGroupID) where S.Element == T {
    let existingFilters = groups[group] ?? []
    let updatedFilters = existingFilters.union(filters.compactMap(Filter.init))
    update(updatedFilters, for: group)
  }
  
  func contains<T: FilterType>(_ filter: T, in group: AnyFilterGroupID) -> Bool {
    guard
      let filter = Filter(filter),
      let filtersForGroup = groups[group] else {
        return false
    }
    return filtersForGroup.contains(filter)
  }
  
  func move<T: FilterType>(filter: T, from origin: AnyFilterGroupID, to destination: AnyFilterGroupID) -> Bool {
    if remove(filter, from: origin) {
      add(filter, to: destination)
      return true
    }
    return false
  }
  
  @discardableResult func remove<T: FilterType>(_ filter: T, from anyGroup: AnyFilterGroupID) -> Bool {
    return removeAll([filter], from: anyGroup)
  }
  
  @discardableResult func removeAll<T: FilterType, S: Sequence>(_ filters: S, from anyGroup: AnyFilterGroupID) -> Bool where S.Element == T {
    let filtersToRemove = filters.compactMap(Filter.init)
    guard let existingFilters = groups[anyGroup], !existingFilters.isDisjoint(with: filtersToRemove) else {
      return false
    }
    let updatedFilters = existingFilters.subtracting(filtersToRemove)
    update(updatedFilters, for: anyGroup)
    return true
  }
  
  func removeAll(from group: AnyFilterGroupID) {
    groups.removeValue(forKey: group)
  }
  
  func removeAll(for attribute: Attribute, from group: AnyFilterGroupID) {
    guard let filtersForGroup = groups[group] else { return }
    let updatedFilters = filtersForGroup.filter { $0.filter.attribute != attribute }
    update(updatedFilters, for: group)
  }
  
  func toggle<T: FilterType>(_ filter: T, in group: AnyFilterGroupID) {
    if contains(filter, in: group) {
      remove(filter, from: group)
    } else {
      add(filter, to: group)
    }
  }
  
  func getAllFilters() -> Set<Filter> {
    return groups.values.reduce(Set<Filter>(), { $0.union($1) })
  }
  
  /// Returns a set of filters of specified type for attribute
  /// - parameter attribute: target attribute
  func getFilters(for attribute: Attribute) -> Set<Filter> {
    let filtersArray = getAllFilters()
      .filter { $0.filter.attribute == attribute }
    return Set(filtersArray)
  }
  
}

// MARK: - Public interface

public extension FilterState {
  
  /// A Boolean value indicating whether FilterState contains at least on filter
  var isEmpty: Bool {
    return groups.isEmpty
  }
  
  /// Tests whether FilterState contains a filter
  /// - parameter filter:
  func contains<T: FilterType>(_ filter: T) -> Bool {
    guard let filter = Filter(filter) else { return false }
    return getAllFilters().contains(filter)
  }
  
  /// Removes filter from source conjunctive group and adds it to destination conjunctive group
  /// - parameter filter: filter to move
  /// - parameter source: source group
  /// - parameter destination: target group
  /// - returns: true if movement succeeded, otherwise returns false
  func move<T: FilterType>(_ filter: T, from source: OrFilterGroupID<T>, to destination: AndFilterGroupID) -> Bool {
    return move(filter: filter, from: AnyFilterGroupID(source), to: AnyFilterGroupID(destination))
  }
  
  /// Removes filter from source conjunctive group and adds it to destination disjunctive group
  /// - parameter filter: filter to move
  /// - parameter source: source group
  /// - parameter destination: target group
  /// - returns: true if movement succeeded, otherwise returns false
  func move<T: FilterType>(_ filter: T, from source: AndFilterGroupID, to destination: OrFilterGroupID<T>) -> Bool {
    return move(filter: filter, from: AnyFilterGroupID(source), to: AnyFilterGroupID(destination))
  }
  
  /// Removes filter from FilterState
  /// - parameter filter: filter to remove
  @discardableResult func remove<T: FilterType>(_ filter: T) -> Bool {
    return groups.map { remove(filter, from: $0.key) }.reduce(false) { $0 || $1 }
  }
  
  /// Removes a sequence of filters from FilterState
  /// - parameter filters: sequence of filters to remove
  func removeAll<T: FilterType, S: Sequence>(_ filters: S) where S.Element == T {
    let anyFilters = filters.compactMap(Filter.init)
    groups.keys.forEach { group in
      let existingFilters = groups[group] ?? []
      let updatedFilters = existingFilters.subtracting(anyFilters)
      update(updatedFilters, for: group)
    }
  }
  
  /// Removes all filters with specified attribute in all groups
  /// - parameter attribute: target attribute
  func removeAll(for attribute: Attribute) {
    groups.keys.forEach { group in
      removeAll(for: attribute, from: group)
    }
  }
  
  /// Removes all filters in all groups
  func removeAll() {
    groups.removeAll()
  }
  
  func getFilters<F: FilterType>(for attribute: Attribute) -> Set<F> {
    return []
  }
  
}

// MARK: Convenient methods for search for facet values and search disjunctive faceting

extension FilterState {
  
  /// Returns a set of attributes suitable for disjunctive faceting
  func getDisjunctiveFacetsAttributes() -> Set<Attribute> {
    //is Disjunctive
    let attributes = groups
      .filter { $0.key.isDisjunctive }
      .compactMap { $0.value }
      .flatMap { $0 }
      .map { $0.filter.attribute }
    return Set(attributes)
    
  }
  
  /// Returns a Boolean value indicating if FilterState contains attributes suitable for disjunctive faceting
  func isDisjunctiveFacetingAvailable() -> Bool {
    return !getDisjunctiveFacetsAttributes().isEmpty
  }
  
  /// Returns a dictionary of all facet filters with their associated values
  func getFacetFilters() -> [Attribute: Set<Filter.Facet.ValueType>] {
    let facetFilters: [Filter.Facet] = groups
      .compactMap { $0.value }
      .flatMap { $0 }.compactMap { filter in
        guard case .facet(let filterFacet) = filter else {
          return nil
        }
        return filterFacet
    }
    var refinements: [Attribute: Set<Filter.Facet.ValueType>] = [:]
    for filter in facetFilters {
      let existingValues = refinements[filter.attribute, default: []]
      let updatedValues = existingValues.union([filter.value])
      refinements[filter.attribute] = updatedValues
    }
    return refinements
  }
  
  /// Returns a raw representaton of all facet filters with their associated values
  func getRawFacetFilters() -> [String: [String]] {
    var rawRefinments: [String: [String]] = [:]
    getFacetFilters()
      .map { ($0.key.name, $0.value.map { $0.description }) }
      .forEach { attribute, values in
        rawRefinments[attribute] = values
    }
    return rawRefinments
  }
  
}

// MARK: Public methods for conjunctive group

public extension FilterState {
  
  /// Adds filter to conjunctive group
  /// - parameter filter: filter to add
  /// - parameter group: target group
  func add<T: FilterType>(_ filter: T, to group: AndFilterGroupID) {
    add(filter, to: AnyFilterGroupID(group))
  }
  
  /// Adds the filters of a sequence to conjunctive group
  /// - parameter filters: sequence of filters to add
  /// - parameter group: target group
  func addAll<T: FilterType, S: Sequence>(_ filters: S, to group: AndFilterGroupID) where S.Element == T {
    addAll(filters: filters, to: AnyFilterGroupID(group))
  }
  
  /// Checks whether specified conjunctive group contains a filter
  /// - parameter filter: filter to check
  /// - parameter group: target group
  /// - returns: true if filter is contained by specified group
  func contains<T: FilterType>(_ filter: T, in group: AndFilterGroupID) -> Bool {
    return contains(filter, in: AnyFilterGroupID(group))
  }
  
  /// Removes filter from source group and adds it to destination group
  /// - parameter filter: filter to move
  /// - parameter source: source group
  /// - parameter destination: target group
  /// - returns: true if movement succeeded, otherwise returns false
  func move<T: FilterType>(_ filter: T, from source: AndFilterGroupID, to destination: AndFilterGroupID) -> Bool {
    return move(filter: filter, from: AnyFilterGroupID(source), to: AnyFilterGroupID(destination))
  }
  
  /// Removes filter from conjunctive group
  /// - parameter filter: filter to remove
  /// - parameter group: target group
  @discardableResult func remove<T: FilterType>(_ filter: T, from group: AndFilterGroupID) -> Bool {
    return remove(filter, from: AnyFilterGroupID(group))
  }
  
  /// Removes all filters from conjunctive group
  /// - parameter group: target group
  func removeAll(from group: AndFilterGroupID) {
    removeAll(from: AnyFilterGroupID(group))
  }
  
  /// Removes filter from conjunctive group if contained by it, otherwise adds filter to group
  /// - parameter filter: filter to toggle
  /// - parameter group: target group
  func toggle<T: FilterType>(_ filter: T, in group: AndFilterGroupID) {
    toggle(filter, in: AnyFilterGroupID(group))
  }
  
}

// MARK: - Public methods for disjunctive group

public extension FilterState {
  
  /// Adds filter to disjunctive group
  /// - parameter filter: filter to add
  /// - parameter group: target group
  func add<T: FilterType>(_ filter: T, to group: OrFilterGroupID<T>) {
    add(filter, to: AnyFilterGroupID(group))
  }
  
  /// Adds the filters of a sequence to disjunctive group
  /// - parameter filters: sequence of filters to add
  /// - parameter group: target group
  func addAll<T: FilterType, S: Sequence>(_ filters: S, to group: OrFilterGroupID<T>) where S.Element == T {
    addAll(filters: filters, to: AnyFilterGroupID(group))
  }
  
  /// Checks whether specified disjunctive group contains a filter
  /// - parameter filter: filter to check
  /// - parameter group: target group
  /// - returns: true if filter is contained by specified group
  func contains<T: FilterType>(_ filter: T, in group: OrFilterGroupID<T>) -> Bool {
    return contains(filter, in: AnyFilterGroupID(group))
  }
  
  /// Removes filter from source group and adds it to destination group
  /// - parameter filter: filter to move
  /// - parameter source: source group
  /// - parameter destination: target group
  /// - returns: true if movement succeeded, otherwise returns false
  func move<T: FilterType>(_ filter: T, from source: OrFilterGroupID<T>, to destination: OrFilterGroupID<T>) -> Bool {
    return move(filter: filter, from: AnyFilterGroupID(source), to: AnyFilterGroupID(destination))
  }
  
  /// Removes filter from disjunctive group
  /// - parameter filter: filter to remove
  /// - parameter group: target group
  @discardableResult func remove<T: FilterType>(_ filter: T, from group: OrFilterGroupID<T>) -> Bool {
    return remove(filter, from: AnyFilterGroupID(group))
  }
  
  /// Removes all filters from disjunctive group
  /// - parameter group: target group
  func removeAll<T: FilterType>(from group: OrFilterGroupID<T>) {
    removeAll(from: AnyFilterGroupID(group))
  }
  
  /// Removes filter from disjunctive group if contained by it, otherwise adds filter to group
  /// - parameter filter: filter to toggle
  /// - parameter group: target group
  func toggle<T: FilterType>(_ filter: T, in group: OrFilterGroupID<T>) {
    toggle(filter, in: AnyFilterGroupID(group))
  }
  
}
