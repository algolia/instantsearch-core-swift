//
//  FilterState.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 10/04/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public class FilterState {
  
  var groups: [FilterGroup.ID: Set<Filter>]
  
  public init() {
    self.groups = [:]
  }
  
  public init(_ filterState: FilterState) {
    self.groups = filterState.groups
  }
  
  private func update(_ filters: Set<Filter>, for group: FilterGroup.ID) {
    groups[group] = filters.isEmpty ? nil : filters
  }
  
  /// Adds filter to group
  /// - parameter filter: filter to add
  /// - parameter group: target group
  
  func add<T: FilterType>(_ filter: T, to group: FilterGroup.ID) {
    addAll(filters: [filter], to: group)
  }
  
  /// Adds the filters of a sequence to group
  /// - parameter filters: sequence of filters to add
  /// - parameter group: target group
  
  func addAll<T: FilterType, S: Sequence>(filters: S, to group: FilterGroup.ID) where S.Element == T {
    let existingFilters = groups[group] ?? []
    let updatedFilters = existingFilters.union(filters.compactMap(Filter.init))
    update(updatedFilters, for: group)
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
  
  /// Removes filter from source group and adds it to destination group
  /// - parameter filter: filter to move
  /// - parameter source: source group
  /// - parameter destination: target group
  /// - returns: true if movement succeeded, otherwise returns false
  
  @discardableResult func remove<T: FilterType>(_ filter: T, from anyGroup: FilterGroup.ID) -> Bool {
    return removeAll([filter], from: anyGroup)
  }

  /// Removes filter from group
  /// - parameter filter: filter to remove
  /// - parameter group: target group
  
  @discardableResult func removeAll<T: FilterType, S: Sequence>(_ filters: S, from anyGroup: FilterGroup.ID) -> Bool where S.Element == T {
    let filtersToRemove = filters.compactMap(Filter.init)
    guard let existingFilters = groups[anyGroup], !existingFilters.isDisjoint(with: filtersToRemove) else {
      return false
    }
    let updatedFilters = existingFilters.subtracting(filtersToRemove)
    update(updatedFilters, for: anyGroup)
    return true
  }
  
  /// Removes all filters from group
  /// - parameter group: target group
  
  func removeAll(from group: FilterGroup.ID) {
    groups.removeValue(forKey: group)
  }
  
  func removeAll(for attribute: Attribute, from group: FilterGroup.ID) {
    guard let filtersForGroup = groups[group] else { return }
    let updatedFilters = filtersForGroup.filter { $0.filter.attribute != attribute }
    update(updatedFilters, for: group)
  }
  
  /// Removes filter from group if contained by it, otherwise adds filter to group
  /// - parameter filter: filter to toggle
  /// - parameter group: target group
  
  func toggle<T: FilterType>(_ filter: T, in group: FilterGroup.ID) {
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

  func getFilters(for groupID: FilterGroup.ID) -> Set<Filter> {
    return groups[groupID] ?? []
  }

}

// MARK: Convenient methods for search for facet values and search disjunctive faceting

extension FilterState {
  
  /// Returns a set of attributes suitable for disjunctive faceting
  func getDisjunctiveFacetsAttributes() -> Set<Attribute> {
    //is Disjunctive
    let attributes = groups
      .filter {
        if case .or = $0.key {
          return true
        } else {
          return false
        }
      }
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

public extension FilterState {
  
  func getFilterGroups() -> [FilterGroupType] {
    
    var result: [FilterGroupType] = []
    
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
    
    for (groupID, filters) in groups.sorted(by: { groupIDComparator($0.key, $1.key) }) {
      
      let group: FilterGroupType
      
      let sortedFilters = filters.sorted(by: filterComparator)
      
      switch groupID {
      case .and:
        group = FilterGroup.And(filters: sortedFilters.map { $0.filter })
      case .or:
        switch filters.first! {
        case .facet:
          group = FilterGroup.Or(filters: sortedFilters.compactMap { $0.filter as? Filter.Facet })
        case .numeric:
          group = FilterGroup.Or(filters: sortedFilters.compactMap { $0.filter as? Filter.Numeric })
        case .tag:
          group = FilterGroup.Or(filters: sortedFilters.compactMap { $0.filter as? Filter.Tag })
        }
      }
      
      result.append(group)
      
    }
    
    return result
    
  }
  
}
