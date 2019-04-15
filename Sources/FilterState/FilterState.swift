//
//  FilterState.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 10/04/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public struct FilterState {
  
  var groups: [FilterGroup.ID: Set<Filter>]
  
  public init() {
    self.groups = [:]
  }
  
  /// Copy constructor
  public init(_ filterState: FilterState) {
    self = filterState
  }
  
  private mutating func update(_ filters: Set<Filter>, for group: FilterGroup.ID) {
    groups[group] = filters.isEmpty ? nil : filters
  }
  
  private func getAllFilters() -> Set<Filter> {
    return groups.values.reduce(Set<Filter>(), { $0.union($1) })
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
  
  /// Checks whether specified group contains a filter
  /// - parameter filter: filter to check
  /// - parameter group: target group
  /// - returns: true if filter is contained by specified group
  
  func contains<T: FilterType>(_ filter: T, in group: FilterGroup.ID) -> Bool {
    guard
      let filter = Filter(filter),
      let filtersForGroup = groups[group] else {
        return false
    }
    return filtersForGroup.contains(filter)
  }

  func getFilters(for groupID: FilterGroup.ID) -> Set<Filter> {
    return groups[groupID] ?? []
  }
  
  /// Returns a set of filters of specified type for attribute
  /// - parameter attribute: target attribute
  func getFilters(for attribute: Attribute) -> Set<Filter> {
    let filtersArray = getAllFilters()
      .filter { $0.filter.attribute == attribute }
    return Set(filtersArray)
  }

}

// MARK: - Public mutating interface

public extension FilterState {
  
  /// Adds filter to group
  /// - parameter filter: filter to add
  /// - parameter groupID: target group
  
  mutating func add<T: FilterType>(_ filter: T, to groupID: FilterGroup.ID) {
    addAll(filters: [filter], to: groupID)
  }
  
  /// Adds the filters of a sequence to group
  /// - parameter filters: sequence of filters to add
  /// - parameter groupID: target group
  
  mutating func addAll<T: FilterType, S: Sequence>(filters: S, to groupID: FilterGroup.ID) where S.Element == T {
    let existingFilters = groups[groupID] ?? []
    let updatedFilters = existingFilters.union(filters.compactMap(Filter.init))
    update(updatedFilters, for: groupID)
  }
  
  /// Removes filter from group if contained by it, otherwise adds filter to group
  /// - parameter filter: filter to toggle
  /// - parameter groupID: target group
  
  mutating func toggle<T: FilterType>(_ filter: T, in groupID: FilterGroup.ID) {
    if contains(filter, in: groupID) {
      remove(filter, from: groupID)
    } else {
      add(filter, to: groupID)
    }
  }
  
  /// Removes filter from source group and adds it to destination group
  /// - parameter filter: filter to move
  /// - parameter source: source group
  /// - parameter destination: target group
  /// - returns: true if movement succeeded, otherwise returns false
  
  @discardableResult mutating func remove<T: FilterType>(_ filter: T, from groupID: FilterGroup.ID) -> Bool {
    return removeAll([filter], from: groupID)
  }
  
  /// Removes filter from group
  /// - parameter filter: filter to remove
  /// - parameter groupID: target group
  
  @discardableResult mutating func removeAll<T: FilterType, S: Sequence>(_ filters: S, from groupID: FilterGroup.ID) -> Bool where S.Element == T {
    let filtersToRemove = filters.compactMap(Filter.init)
    guard let existingFilters = groups[groupID], !existingFilters.isDisjoint(with: filtersToRemove) else {
      return false
    }
    let updatedFilters = existingFilters.subtracting(filtersToRemove)
    update(updatedFilters, for: groupID)
    return true
  }
  
  /// Removes all filters from group
  /// - parameter group: target group
  mutating func removeAll(from groupID: FilterGroup.ID) {
    groups.removeValue(forKey: groupID)
  }
  
  /// Removes filter from FilterState
  /// - parameter filter: filter to remove
  @discardableResult mutating func remove<T: FilterType>(_ filter: T) -> Bool {
    return groups.map { remove(filter, from: $0.key) }.reduce(false) { $0 || $1 }
  }
  
  /// Removes a sequence of filters from FilterState
  /// - parameter filters: sequence of filters to remove
  mutating func removeAll<T: FilterType, S: Sequence>(_ filters: S) where S.Element == T {
    let anyFilters = filters.compactMap(Filter.init)
    groups.keys.forEach { group in
      let existingFilters = groups[group] ?? []
      let updatedFilters = existingFilters.subtracting(anyFilters)
      update(updatedFilters, for: group)
    }
  }
  
  mutating func removeAll(for attribute: Attribute, from groupID: FilterGroup.ID) {
    guard let filtersForGroup = groups[groupID] else { return }
    let updatedFilters = filtersForGroup.filter { $0.filter.attribute != attribute }
    update(updatedFilters, for: groupID)
  }
  
  /// Removes all filters with specified attribute in all groups
  /// - parameter attribute: target attribute
  mutating func removeAll(for attribute: Attribute) {
    groups.keys.forEach { group in
      removeAll(for: attribute, from: group)
    }
  }
  
  /// Removes all filters in all groups
  mutating func removeAll() {
    groups.removeAll()
  }
  
}

// MARK: Convenient methods for search for facet values and search disjunctive faceting

extension FilterState {
  
  /// Returns a set of attributes suitable for disjunctive faceting
  func getDisjunctiveFacetsAttributes() -> Set<Attribute> {
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
    return getFacetFilters()
      .map { ($0.key.name, $0.value.map { $0.description }) }
      .reduce([String: [String]]()) { (refinements, arg1) in
        let (attribute, values) = arg1
        return refinements.merging([attribute: values], uniquingKeysWith: { (_, new) -> [String] in
          new
        })
      }
  }
  
}

public extension FilterState {
  
  func getFilterGroups() -> [FilterGroupType] {
    
    // There is a need to sort groups and filters in them for
    // getting a constant output of converters
    
    let filterComparator: (Filter, Filter) -> Bool = {
      let converter = SQLFilterConverter()
      let lhsString = converter.convert($0)
      let rhsString = converter.convert($1)
      return lhsString < rhsString
    }
    
    let groupIDComparator: (FilterGroup.ID, FilterGroup.ID) -> Bool = {
      guard $0.name != $1.name else {
        switch ($0, $1) {
        case (.or, .and):
          return true
        default:
          return false
        }
      }
      return $0.name < $1.name
    }
    
    let transform: (FilterGroup.ID, Set<Filter>) -> FilterGroupType? = { (groupID, filters) in
      guard let firstFilter = filters.first else {
        return nil
      }
      
      let sortedFilters = filters.sorted(by: filterComparator)
      
      switch groupID {
      case .and:
        return FilterGroup.And(filters: sortedFilters.map { $0.filter })
      case .or:
        switch firstFilter {
        case .facet:
          return FilterGroup.Or(filters: sortedFilters.compactMap { $0.filter as? Filter.Facet })
        case .numeric:
          return FilterGroup.Or(filters: sortedFilters.compactMap { $0.filter as? Filter.Numeric })
        case .tag:
          return FilterGroup.Or(filters: sortedFilters.compactMap { $0.filter as? Filter.Tag })
        }
      }
    }
    
    return groups
      .sorted(by: { groupIDComparator($0.key, $1.key) })
      .compactMap(transform)
    
  }
  
}
