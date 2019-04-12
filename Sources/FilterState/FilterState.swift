//
//  FilterState.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 10/04/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public class FilterState {
  
  var groups: [FilterGroupID: Set<Filter>]
  
  public init() {
    self.groups = [:]
  }
  
  public init(_ filterState: FilterState) {
    self.groups = filterState.groups
  }
  
  private func update(_ filters: Set<Filter>, for group: FilterGroupID) {
    groups[group] = filters.isEmpty ? nil : filters
  }
  
  /// Adds filter to group
  /// - parameter filter: filter to add
  /// - parameter group: target group
  
  func add<T: FilterType>(_ filter: T, to group: FilterGroupID) {
    addAll(filters: [filter], to: group)
  }
  
  /// Adds the filters of a sequence to group
  /// - parameter filters: sequence of filters to add
  /// - parameter group: target group
  
  func addAll<T: FilterType, S: Sequence>(filters: S, to group: FilterGroupID) where S.Element == T {
    let existingFilters = groups[group] ?? []
    let updatedFilters = existingFilters.union(filters.compactMap(Filter.init))
    update(updatedFilters, for: group)
  }
  
  /// Checks whether specified group contains a filter
  /// - parameter filter: filter to check
  /// - parameter group: target group
  /// - returns: true if filter is contained by specified group
  
  func contains<T: FilterType>(_ filter: T, in group: FilterGroupID) -> Bool {
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
  
  @discardableResult func remove<T: FilterType>(_ filter: T, from anyGroup: FilterGroupID) -> Bool {
    return removeAll([filter], from: anyGroup)
  }

  /// Removes filter from group
  /// - parameter filter: filter to remove
  /// - parameter group: target group
  
  @discardableResult func removeAll<T: FilterType, S: Sequence>(_ filters: S, from anyGroup: FilterGroupID) -> Bool where S.Element == T {
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
  
  func removeAll(from group: FilterGroupID) {
    groups.removeValue(forKey: group)
  }
  
  func removeAll(for attribute: Attribute, from group: FilterGroupID) {
    guard let filtersForGroup = groups[group] else { return }
    let updatedFilters = filtersForGroup.filter { $0.filter.attribute != attribute }
    update(updatedFilters, for: group)
  }
  
  /// Removes filter from group if contained by it, otherwise adds filter to group
  /// - parameter filter: filter to toggle
  /// - parameter group: target group
  
  func toggle<T: FilterType>(_ filter: T, in group: FilterGroupID) {
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
  
//  subscript(groupID: FilterGroup.And.ID) -> AndGroupProxy {
//    return AndGroupProxy(filterState: self, groupID: groupID)
//  }
//
//  subscript<T: FilterType>(groupID: FilterGroup.Or<T>.ID) -> OrGroupProxy<T> {
//    return OrGroupProxy(filterState: self, groupID: groupID)
//  }
  
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
  
//  func getFilters<F: FilterType>(for attribute: Attribute) -> Set<F> {
//    return []
//  }

  
  func getFilters(for groupID: FilterGroupID) -> Set<Filter> {
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
    
    for (groupID, filters) in groups {
      
      let group: FilterGroupType
      
      switch groupID {
      case .and:
        group = FilterGroup.And(filters: filters.map { $0.filter })
      case .or:
        switch filters.first! {
        case .facet:
          group = FilterGroup.Or(filters: filters.compactMap{ $0.filter as? Filter.Facet } )
        case .numeric:
          group = FilterGroup.Or(filters: filters.compactMap{ $0.filter as? Filter.Numeric } )
        case .tag:
          group = FilterGroup.Or(filters: filters.compactMap{ $0.filter as? Filter.Tag } )
        }
      }
      
      result.append(group)
      
    }
    
    return result
    
//    func extractOrGroup<F: FilterType>(from id: FilterGroupID, with filters: Set<Filter>) -> FilterGroup.Or<F>? {
//
//      if let _: FilterGroup.Or<F>.ID = id.extractAs() {
//        return FilterGroup.Or(filters: filters.sorted { SQLFilterConverter().convert($0) < SQLFilterConverter().convert($1) } .map { $0.filter }.compactMap { $0 as? F })
//      } else {
//        return nil
//      }
//    }
//
//    func filterGroup(with id: FilterGroupID, filters: Set<Filter>) -> FilterGroupType? {
//
//      for (groupID, filters) in groups {
//
//      }
//
//      if let _: FilterGroup.And.ID = id.extractAs() {
//        return FilterGroup.And(filters: filters.sorted { SQLFilterConverter().convert($0) < SQLFilterConverter().convert($1) }.map { $0.filter })
//      } else if let tagGroup: FilterGroup.Or<Filter.Tag> = extractOrGroup(from: id, with: filters) {
//        return tagGroup
//      } else if let facetGroup: FilterGroup.Or<Filter.Facet> = extractOrGroup(from: id, with: filters) {
//        return facetGroup
//      } else if let numericGroup: FilterGroup.Or<Filter.Numeric> = extractOrGroup(from: id, with: filters) {
//        return numericGroup
//      } else {
//        return nil
//      }
//
//    }
//
//    return groups.sorted { $0.0.name < $1.0.name }.compactMap(filterGroup)
    
  }
  
}
