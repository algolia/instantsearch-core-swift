//
//  GroupStorage.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 15/07/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

struct GroupsStorage {
  
  var filterGroups: [FilterGroupType]
  
  init() {
    filterGroups = []
  }
  
}

extension GroupsStorage: FilterGroupsConvertible {
  
  func toFilterGroups() -> [FilterGroupType] {
    return filterGroups
  }
  
}

extension GroupsStorage: FiltersReadable {
  
  func getFilters(forGroupWithID groupID: FilterGroup.ID) -> Set<Filter> {
    return Set(filterGroups.first { FilterGroup.ID($0) == groupID }?.filters.map(Filter.init) ?? [])
  }
  
  func getFilters(for attribute: Attribute) -> Set<Filter> {
    return Set(getFilters().filter { $0.attribute == attribute })
  }
  
  func getFiltersAndID() -> Set<FilterAndID> {
    return Set(filterGroups
      .map { group -> [(FilterGroup.ID, FilterType)?] in
        guard let groupID = FilterGroup.ID(group) else {
          return []
        }
        return group.filters.map { (groupID, $0) }
      }
      .flatMap { $0 }
      .compactMap { $0 }
      .map { FilterAndID(filter: Filter($0.1), id: $0.0) })
  }
  
  func getFilters() -> Set<Filter> {
    return Set(filterGroups.flatMap { $0.filters }.map(Filter.init))
  }
  
  var isEmpty: Bool {
    return filterGroups.allSatisfy { $0.filters.isEmpty }
  }
  
  func contains(_ filter: FilterType, inGroupWithID groupID: FilterGroup.ID) -> Bool {
    return filterGroups.first { FilterGroup.ID($0) == groupID }?.contains(filter) ?? false
  }
  
  func getGroupIDs() -> Set<FilterGroup.ID> {
    return Set(filterGroups.compactMap(FilterGroup.ID.init))
  }
  
}

extension GroupsStorage: FiltersWritable {
  
  private func emptyGroup(with filterGroupID: FilterGroup.ID) -> FilterGroupType {
    switch filterGroupID {
    case .and(name: let name):
      return FilterGroup.And(filters: [], name: name)
    case .hierarchical(name: let name):
      return FilterGroup.Hierarchical(filters: [], name: name)
    case .or(name: let name, filterType: .facet):
      return FilterGroup.Or<Filter.Facet>(filters: [], name: name)
    case .or(name: let name, filterType: .numeric):
      return FilterGroup.Or<Filter.Numeric>(filters: [], name: name)
    case .or(name: let name, filterType: .tag):
      return FilterGroup.Or<Filter.Tag>(filters: [], name: name)
    }
  }
  
  mutating func addAll<S: Sequence>(filters: S, toGroupWithID groupID: FilterGroup.ID) where S.Element == FilterType {
    guard let indexOfExistingGroup = filterGroups.firstIndex(where: { FilterGroup.ID($0) == groupID }) else {
      let group = emptyGroup(with: groupID).withFilters(filters)
      self.filterGroups.append(group)
      return
    }
    
    let existingGroup = filterGroups[indexOfExistingGroup]
    let updatedFilters = Set(existingGroup.filters.map(Filter.init)).union(filters.map(Filter.init)).map { $0.filter }
    
    filterGroups[indexOfExistingGroup] = emptyGroup(with: groupID).withFilters(updatedFilters)
  }
  
  mutating func removeAll<S: Sequence>(_ filters: S, fromGroupWithID groupID: FilterGroup.ID) -> Bool where S.Element == FilterType {
    var wasRemoved: Bool = false
    let filtersToRemove = Set(filters.map(Filter.init))
    self.filterGroups = filterGroups.map { group in
      let updatedFilters = group.filters.filter { !filtersToRemove.contains(Filter($0)) }
      wasRemoved = wasRemoved || updatedFilters.count < group.filters.count
      return group.withFilters(updatedFilters)
    }
    return wasRemoved
  }
  
  mutating func removeAll(fromGroupWithIDs groupIDs: [FilterGroup.ID]) {
    self.filterGroups.removeAll(where: { return FilterGroup.ID($0).flatMap(groupIDs.contains) ?? false })
  }
  
  mutating func removeAllExcept(fromGroupWithIDs groupIDs: [FilterGroup.ID]) {
    self.filterGroups.removeAll(where: { return !(FilterGroup.ID($0).flatMap(groupIDs.contains) ?? false) })
  }
  
  mutating func removeAll<S: Sequence>(_ filters: S) where S.Element == FilterType {
    getGroupIDs().forEach { _ = removeAll(filters, fromGroupWithID: $0) }
  }
  
  mutating func removeAll(for attribute: Attribute, fromGroupWithID groupID: FilterGroup.ID) {
    self.filterGroups = filterGroups.map { group in
      if FilterGroup.ID(group) == groupID {
        let updatedFilters = group.filters.filter { $0.attribute != attribute }
        return group.withFilters(updatedFilters)
      } else {
        return group
      }
    }
  }
  
  mutating func removeAll(for attribute: Attribute) {
    self.filterGroups = filterGroups.map { group in
      let updatedFilters = group.filters.filter { $0.attribute != attribute }
      return group.withFilters(updatedFilters)
    }
  }
  
  mutating func removeAll() {
    filterGroups.removeAll()
  }
  
}

extension GroupsStorage: HierarchicalManageable {
  
  func hierarchicalGroup(withName groupName: String) -> FilterGroup.Hierarchical? {
    return filterGroups.first(where: { FilterGroup.ID($0) == .hierarchical(name: groupName) }).flatMap { $0 as? FilterGroup.Hierarchical }
  }
  
  func hierarchicalAttributes(forGroupWithName groupName: String) -> [Attribute] {
    return hierarchicalGroup(withName: groupName)?.hierarchicalAttributes ?? []
  }
  
  func hierarchicalFilters(forGroupWithName groupName: String) -> [Filter.Facet] {
    return hierarchicalGroup(withName: groupName)?.hierarchicalFilters ?? []

  }
  
  mutating func set(_ hierarchicalAttributes: [Attribute], forGroupWithName groupName: String) {
    guard let existingIndex = filterGroups.firstIndex (where: { FilterGroup.ID($0) == .hierarchical(name: groupName) }) else {
      var newGroup = FilterGroup.Hierarchical(filters: [], name: groupName)
      newGroup.hierarchicalAttributes = hierarchicalAttributes
      filterGroups.append(newGroup)
      return
    }
    var existingGroup = filterGroups[existingIndex] as! FilterGroup.Hierarchical
    existingGroup.hierarchicalAttributes = hierarchicalAttributes
    filterGroups[existingIndex] = existingGroup
  }
  
  mutating func set(_ hierarchicalFilters: [Filter.Facet], forGroupWithName groupName: String) {
    guard let existingIndex = filterGroups.firstIndex (where: { FilterGroup.ID($0) == .hierarchical(name: groupName) }) else {
      var newGroup = FilterGroup.Hierarchical(filters: [], name: groupName)
      newGroup.hierarchicalFilters = hierarchicalFilters
      filterGroups.append(newGroup)
      return
    }
    var existingGroup = filterGroups[existingIndex] as! FilterGroup.Hierarchical
    existingGroup.hierarchicalFilters = hierarchicalFilters
    filterGroups[existingIndex] = existingGroup
  }
  
}
