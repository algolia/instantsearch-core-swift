//
//  FilterState.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 10/04/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

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
  
  func getGroupIDs() -> Set<FilterGroup.ID> {
    return Set(groups.keys.map { $0 })
  }
  
  public var isEmpty: Bool {
    return groups.isEmpty
  }
  
  public func contains(_ filter: FilterType, inGroupWithID groupID: FilterGroup.ID) -> Bool {
    guard let filtersForGroup = groups[groupID] else {
        return false
    }
    return filtersForGroup.contains(Filter(filter))
  }
  
  public func getFilters(forGroupWithID groupID: FilterGroup.ID) -> Set<Filter> {
    return groups[groupID] ?? []
  }
  
  public func getFilters(for attribute: Attribute) -> Set<Filter> {
    let filtersArray = getFilters()
      .filter { $0.filter.attribute == attribute }
    return Set(filtersArray)
  }
  
  public func getFilters() -> Set<Filter> {
    return groups.values.reduce(Set<Filter>(), { $0.union($1) })
  }

  func getFiltersAndID() -> Set<FilterAndID> {
    return Set(groups.map { entry in entry.value.map { f in FilterAndID(filter: f, id: entry.key) } }.flatMap { $0 })
  }

}

// MARK: - Public mutating interface

extension Filters: FiltersWritable {
  
  public mutating func add(_ filter: FilterType, toGroupWithID groupID: FilterGroup.ID) {
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
  
  public mutating func addAll<S: Sequence>(filters: S, toGroupWithID groupID: FilterGroup.ID) where S.Element == FilterType {
    let existingFilters = groups[groupID] ?? []
    let updatedFilters = existingFilters.union(filters.compactMap(Filter.init))
    update(updatedFilters, forGroupWithID: groupID)
  }

  @discardableResult public mutating func remove(_ filter: FilterType, fromGroupWithID groupID: FilterGroup.ID) -> Bool {
    return removeAll([filter], fromGroupWithID: groupID)
  }

  @discardableResult public mutating func removeAll<S: Sequence>(_ filters: S, fromGroupWithID groupID: FilterGroup.ID) -> Bool where S.Element == FilterType {
    let filtersToRemove = filters.compactMap(Filter.init)
    guard let existingFilters = groups[groupID], !existingFilters.isDisjoint(with: filtersToRemove) else {
      return false
    }
    let updatedFilters = existingFilters.subtracting(filtersToRemove)
    update(updatedFilters, forGroupWithID: groupID)
    return true
  }
  
  public mutating func removeAll(fromGroupWithID groupID: FilterGroup.ID) {
    groups.removeValue(forKey: groupID)
  }

  public mutating func removeAll(fromGroupWithIDs groupIDs: [FilterGroup.ID]) {
    groupIDs.forEach { groups.removeValue(forKey: $0) }
  }

  @discardableResult public mutating func remove(_ filter: FilterType) -> Bool {
    return groups.map { remove(filter, fromGroupWithID: $0.key) }.reduce(false) { $0 || $1 }
  }
  
  public mutating func removeAll<S: Sequence>(_ filters: S) where S.Element == FilterType {
    let anyFilters = filters.compactMap(Filter.init)
    groups.keys.forEach { group in
      let existingFilters = groups[group] ?? []
      let updatedFilters = existingFilters.subtracting(anyFilters)
      update(updatedFilters, forGroupWithID: group)
    }
  }
  
  public mutating func removeAll(for attribute: Attribute, fromGroupWithID groupID: FilterGroup.ID) {
    guard let filtersForGroup = groups[groupID] else { return }
    let updatedFilters = filtersForGroup.filter { $0.filter.attribute != attribute }
    update(updatedFilters, forGroupWithID: groupID)
  }
  
  public mutating func removeAll(for attribute: Attribute) {
    groups.keys.forEach { group in
      removeAll(for: attribute, fromGroupWithID: group)
    }
  }
  
  public mutating func removeAll() {
    groups.removeAll()
  }
  
  public mutating func toggle(_ filter: FilterType, inGroupWithID groupID: FilterGroup.ID) {
    toggle([filter], inGroupWithID: groupID)
  }
  
  public mutating func toggle<S: Sequence>(_ filters: S, inGroupWithID groupID: FilterGroup.ID) where S.Element == FilterType {
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
    
    let transform: (FilterGroup.ID, Set<Filter>) -> FilterGroupType = { (groupID, filters) in
      
      let sortedFilters = filters.sorted(by: filterComparator)
      
      switch groupID {
      case .and:
        return FilterGroup.And(filters: sortedFilters.map { $0.filter }, name: groupID.name)
      case .hierarchical:
        return FilterGroup.And(filters: sortedFilters.compactMap { $0.filter as? Filter.Facet }, name: groupID.name)
      case .or(_, .facet):
        return FilterGroup.Or(filters: sortedFilters.compactMap { $0.filter as? Filter.Facet }, name: groupID.name)
      case .or(_, .tag):
        return FilterGroup.Or(filters: sortedFilters.compactMap { $0.filter as? Filter.Tag }, name: groupID.name)
      case .or(_, .numeric):
        return FilterGroup.Or(filters: sortedFilters.compactMap { $0.filter as? Filter.Numeric }, name: groupID.name)
      }
      
    }
    
    return groups
      .sorted(by: { groupIDComparator($0.key, $1.key) })
      .compactMap(transform)
  }
  
}
