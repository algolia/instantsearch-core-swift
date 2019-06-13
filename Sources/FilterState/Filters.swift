//
//  FilterState.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 10/04/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public protocol FiltersReadable {
  
  var isEmpty: Bool { get }
  
  func contains<T: FilterType>(_ filter: T) -> Bool
  func contains<T: FilterType>(_ filter: T, inGroupWithID groupID: FilterGroup.ID) -> Bool
  func getFilters(forGroupWithID groupID: FilterGroup.ID) -> Set<Filter>
  func getFilters(for attribute: Attribute) -> Set<Filter>
  func getFiltersAndID() -> Set<FilterAndID>
  func getFilters() -> Set<Filter>
  
}

public protocol FiltersWritable {
  
  mutating func add<T: FilterType>(_ filter: T, toGroupWithID groupID: FilterGroup.ID)
  mutating func addAll<T: FilterType, S: Sequence>(filters: S, toGroupWithID groupID: FilterGroup.ID) where S.Element == T
  
  @discardableResult mutating func remove<T: FilterType>(_ filter: T, fromGroupWithID groupID: FilterGroup.ID) -> Bool
  @discardableResult mutating func removeAll<T: FilterType, S: Sequence>(_ filters: S, fromGroupWithID groupID: FilterGroup.ID) -> Bool where S.Element == T
  mutating func removeAll(fromGroupWithID groupID: FilterGroup.ID)
  mutating func removeAll(fromGroupWithIDs groupIDs: [FilterGroup.ID])
  mutating func removeAllExcept(fromGroupWithIDs groupIDs: [FilterGroup.ID])
  @discardableResult mutating func remove<T: FilterType>(_ filter: T) -> Bool
  mutating func removeAll<T: FilterType, S: Sequence>(_ filters: S) where S.Element == T
  mutating func removeAll(for attribute: Attribute, fromGroupWithID groupID: FilterGroup.ID)
  mutating func removeAll(for attribute: Attribute)
  mutating func removeAll()
  
  mutating func toggle<T: FilterType>(_ filter: T, inGroupWithID groupID: FilterGroup.ID)
  
  mutating func toggle<T: FilterType, S: Sequence>(_ filters: S, inGroupWithID groupID: FilterGroup.ID) where S.Element == T
  
}

public protocol FilterGroupsConvertible {
  
  func toFilterGroups() -> [FilterGroupType]
  
}

struct Filters {
  
  var groups: [FilterGroup.ID: Set<Filter>]
  
  public init() {
    self.groups = [:]
  }
  
  /// Copy constructor
  
  public init(_ filters: Filters) {
    self = filters
  }

  public init(_ groups: [FilterGroup.ID: Set<Filter>]) {
    self.groups = groups
  }
  
  private mutating func update(_ filters: Set<Filter>, forGroupWithID groupID: FilterGroup.ID) {
    groups[groupID] = filters.isEmpty ? nil : filters
  }
  
}

// MARK: - Public interface

extension Filters: FiltersReadable {
    
  /// A Boolean value indicating whether FilterState contains at least on filter
  
  public var isEmpty: Bool {
    return groups.isEmpty
  }
  
  /// Tests whether FilterState contains a filter
  /// - parameter filter: desired filter
  
  public func contains<T: FilterType>(_ filter: T) -> Bool {
    return getFilters().contains(Filter(filter))
  }
  
  /// Checks whether specified group contains a filter
  /// - parameter filter: filter to check
  /// - parameter groupID: target group ID
  /// - returns: true if filter is contained by specified group
  
  public func contains<T: FilterType>(_ filter: T, inGroupWithID groupID: FilterGroup.ID) -> Bool {
    guard let filtersForGroup = groups[groupID] else {
        return false
    }
    return filtersForGroup.contains(Filter(filter))
  }

  /// Returns a set of filters in group with specified ID
  /// - parameter groupID: target group ID
  
  public func getFilters(forGroupWithID groupID: FilterGroup.ID) -> Set<Filter> {
    return groups[groupID] ?? []
  }
  
  /// Returns a set of filters for attribute
  /// - parameter attribute: target attribute
  
  public func getFilters(for attribute: Attribute) -> Set<Filter> {
    let filtersArray = getFilters()
      .filter { $0.filter.attribute == attribute }
    return Set(filtersArray)
  }
  
  /// Returns a set of all the filters contained by all the groups
  
  public func getFilters() -> Set<Filter> {
    return groups.values.reduce(Set<Filter>(), { $0.union($1) })
  }

  func getFiltersAndID() -> Set<FilterAndID> {
    return Set(groups.map { entry in entry.value.map { f in FilterAndID(filter: f, id: entry.key) } }.flatMap { $0 })
  }

}

// MARK: - Public mutating interface

extension Filters: FiltersWritable {

  /// Adds filter to a specified group
  /// - parameter filter: filter to add
  /// - parameter groupID: target group ID
  
  public mutating func add<T: FilterType>(_ filter: T, toGroupWithID groupID: FilterGroup.ID) {
    addAll(filters: [filter], toGroupWithID: groupID)
  }

  mutating func add(_ filter: Filter, toGroupWithID groupID: FilterGroup.ID) {
    addAll(filters: [filter], toGroupWithID: groupID)
  }

  mutating func addAll<S: Sequence>(filters: S, toGroupWithID groupID: FilterGroup.ID) where S.Element == Filter {
    let existingFilters = groups[groupID] ?? []
    let updatedFilters = existingFilters.union(filters)
    update(updatedFilters, forGroupWithID: groupID)
  }
  
  /// Adds a sequence of filters to a specified group
  /// - parameter filters: sequence of filters to add
  /// - parameter groupID: target group ID
  
  public mutating func addAll<T: FilterType, S: Sequence>(filters: S, toGroupWithID groupID: FilterGroup.ID) where S.Element == T {
    let existingFilters = groups[groupID] ?? []
    let updatedFilters = existingFilters.union(filters.compactMap(Filter.init))
    update(updatedFilters, forGroupWithID: groupID)
  }
  
  /// Removes filter from a specified group
  /// - parameter filter: filter to remove
  /// - parameter groupID: target group ID
  /// - returns: true if removal succeeded, otherwise returns false

  @discardableResult public mutating func remove<T: FilterType>(_ filter: T, fromGroupWithID groupID: FilterGroup.ID) -> Bool {
    return removeAll([filter], fromGroupWithID: groupID)
  }
  
  /// Removes a sequence of filters from a specified group
  /// - parameter filters: sequence of filters to remove
  /// - parameter groupID: target group ID
  /// - returns: true if at least one filter in filters sequence is contained by a specified group and so has been removed, otherwise returns false

  @discardableResult public mutating func removeAll<T: FilterType, S: Sequence>(_ filters: S, fromGroupWithID groupID: FilterGroup.ID) -> Bool where S.Element == T {
    let filtersToRemove = filters.compactMap(Filter.init)
    guard let existingFilters = groups[groupID], !existingFilters.isDisjoint(with: filtersToRemove) else {
      return false
    }
    let updatedFilters = existingFilters.subtracting(filtersToRemove)
    update(updatedFilters, forGroupWithID: groupID)
    return true
  }
  
  /// Removes all filters from a specifed group
  /// - parameter group: target group ID
  
  public mutating func removeAll(fromGroupWithID groupID: FilterGroup.ID) {
    groups.removeValue(forKey: groupID)
  }

  public mutating func removeAll(fromGroupWithIDs groupIDs: [FilterGroup.ID]) {
    groupIDs.forEach { groups.removeValue(forKey: $0) }
  }

  public mutating func removeAllExcept(fromGroupWithIDs groupIDs: [FilterGroup.ID]) {
    var newGroups: [FilterGroup.ID: Set<Filter>] = [:]
    for (id, filters) in groups {
      if groupIDs.contains(id) {
        newGroups[id] = filters
      }
    }

    groups = newGroups
  }
  
  /// Removes filter from all the groups
  /// - parameter filter: filter to remove
  /// - returns: true if specified filter has been removed from at least one group, otherwise returns false

  @discardableResult public mutating func remove<T: FilterType>(_ filter: T) -> Bool {
    return groups.map { remove(filter, fromGroupWithID: $0.key) }.reduce(false) { $0 || $1 }
  }
  
  /// Removes a sequence of filters from all the groups
  /// - parameter filters: sequence of filters to remove
  
  public mutating func removeAll<T: FilterType, S: Sequence>(_ filters: S) where S.Element == T {
    let anyFilters = filters.compactMap(Filter.init)
    groups.keys.forEach { group in
      let existingFilters = groups[group] ?? []
      let updatedFilters = existingFilters.subtracting(anyFilters)
      update(updatedFilters, forGroupWithID: group)
    }
  }
  
  /// Removes all filters with specified attribute in a specified group
  /// - parameter attribute: target attribute
  /// - parameter groupID: target group ID
  
  public mutating func removeAll(for attribute: Attribute, fromGroupWithID groupID: FilterGroup.ID) {
    guard let filtersForGroup = groups[groupID] else { return }
    let updatedFilters = filtersForGroup.filter { $0.filter.attribute != attribute }
    update(updatedFilters, forGroupWithID: groupID)
  }
  
  /// Removes all filters with specified attribute in all the groups
  /// - parameter attribute: target attribute
  
  public mutating func removeAll(for attribute: Attribute) {
    groups.keys.forEach { group in
      removeAll(for: attribute, fromGroupWithID: group)
    }
  }
  
  /// Removes all filters from all the groups
  
  public mutating func removeAll() {
    groups.removeAll()
  }
  
  /// Removes filter from group if contained by it, otherwise adds filter to group
  /// - parameter filter: filter to toggle
  /// - parameter groupID: target group ID
  
  public mutating func toggle<T: FilterType>(_ filter: T, inGroupWithID groupID: FilterGroup.ID) {
    toggle([filter], inGroupWithID: groupID)
  }
  
  /// Toggles a sequence of filters in group
  /// - parameter filters: sequence of filters to toggle
  /// - parameter groupID: target group ID
  
  public mutating func toggle<T: FilterType, S: Sequence>(_ filters: S, inGroupWithID groupID: FilterGroup.ID) where S.Element == T {
    for filter in filters {
      if contains(filter, inGroupWithID: groupID) {
        remove(filter, fromGroupWithID: groupID)
      } else {
        add(filter, toGroupWithID: groupID)
      }
    }
  }
  
}

// MARK: Convenient methods for search for facet values and search disjunctive faceting

extension Filters {
  
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

extension Filters: FilterGroupsConvertible {
  
  func toFilterGroups() -> [FilterGroupType] {
    
    // There is a need to sort groups and filters in them for
    // getting a constant output of converters
    
    let filterComparator: (Filter, Filter) -> Bool = {
      let converter = FilterConverter()
      let lhsString = converter.sql($0.filter)!
      let rhsString = converter.sql($1.filter)!
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
        return FilterGroup.And(filters: sortedFilters.map { $0.filter }, name: groupID.name)
      case .or:
        switch firstFilter {
        case .facet:
          return FilterGroup.Or(filters: sortedFilters.compactMap { $0.filter as? Filter.Facet }, name: groupID.name)
        case .numeric:
          return FilterGroup.Or(filters: sortedFilters.compactMap { $0.filter as? Filter.Numeric }, name: groupID.name)
        case .tag:
          return FilterGroup.Or(filters: sortedFilters.compactMap { $0.filter as? Filter.Tag }, name: groupID.name)
        }
      }
    }
    
    return groups
      .sorted(by: { groupIDComparator($0.key, $1.key) })
      .compactMap(transform)
    
  }
  
}
