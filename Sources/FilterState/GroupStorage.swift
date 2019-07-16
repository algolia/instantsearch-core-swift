//
//  GroupStorage.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 15/07/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

struct GroupsStorage {
  
  var filterGroups: [FilterGroup.ID: FilterGroupType]
  
  init() {
    filterGroups = [:]
  }
  
}

extension GroupsStorage: FilterGroupsConvertible {
  
  func toFilterGroups() -> [FilterGroupType] {
    return filterGroups.values.map { $0 }
  }
  
}

extension GroupsStorage: FiltersReadable {
  
  func getFilters(forGroupWithID groupID: FilterGroup.ID) -> Set<Filter> {
    return Set(filterGroups[groupID]?.filters.map(Filter.init) ?? [])
  }
  
  func getFilters(for attribute: Attribute) -> Set<Filter> {
    return Set(getFilters().filter { $0.attribute == attribute })
  }
  
  func getFiltersAndID() -> Set<FilterAndID> {
    return Set(filterGroups
      .map { (id, group) in group.filters.map { (id, $0)  } }
      .flatMap { $0 }
      .map { FilterAndID(filter: Filter($0.1), id: $0.0) })
  }
  
  func getFilters() -> Set<Filter> {
    return Set(filterGroups.values.flatMap { $0.filters }.map(Filter.init))
  }
  
  var isEmpty: Bool {
    return filterGroups.values.allSatisfy { $0.filters.isEmpty }
  }
  
  func contains(_ filter: FilterType, inGroupWithID groupID: FilterGroup.ID) -> Bool {
    return filterGroups[groupID]?.contains(filter) == true
  }
  
  func getGroupIDs() -> Set<FilterGroup.ID> {
    return Set(filterGroups.keys)
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
    let group = filterGroups[groupID] ?? emptyGroup(with: groupID)
    let updatedFilters = Set(group.filters.map(Filter.init)).union(filters.map(Filter.init)).map { $0.filter }
    filterGroups[groupID] = group.withFilters(updatedFilters)
  }
  
  mutating func removeAll<S: Sequence>(_ filters: S, fromGroupWithID groupID: FilterGroup.ID) -> Bool where S.Element == FilterType {
    guard let existingGroup = filterGroups[groupID] else {
      return false
    }
    
    let updatedFilters = Set(existingGroup.filters.map(Filter.init)).subtracting(filters.map(Filter.init)).map { $0.filter }
    filterGroups[groupID] = existingGroup.withFilters(updatedFilters)
    return existingGroup.filters.count > updatedFilters.count
  }
  
  mutating func removeAll(fromGroupWithIDs groupIDs: [FilterGroup.ID]) {
    groupIDs.forEach { filterGroups.removeValue(forKey: $0) }
  }
  
  mutating func removeAllExcept(fromGroupWithIDs groupIDs: [FilterGroup.ID]) {
    filterGroups.keys
      .filter { !groupIDs.contains($0) }
      .forEach { filterGroups.removeValue(forKey: $0) }
  }
  
  mutating func removeAll<S: Sequence>(_ filters: S) where S.Element == FilterType {
    getGroupIDs().forEach { _ = removeAll(filters, fromGroupWithID: $0) }
  }
  
  mutating func removeAll(for attribute: Attribute, fromGroupWithID groupID: FilterGroup.ID) {
    guard let existingGroup = filterGroups[groupID] else {
      return
    }
    
    let updatedFilters = existingGroup.filters.filter { $0.attribute != attribute }
    filterGroups[groupID] = existingGroup.withFilters(updatedFilters)
  }
  
  mutating func removeAll(for attribute: Attribute) {
    for (groupID, group) in filterGroups {
      let updatedFilters = group.filters.filter { $0.attribute != attribute }
      filterGroups[groupID] = group.withFilters(updatedFilters)
    }
  }
  
  mutating func removeAll() {
    filterGroups.removeAll()
  }
  
}

extension GroupsStorage: HierarchicalManageable {
  
  func hierarchicalGroup(withName groupName: String) -> FilterGroup.Hierarchical? {
    return filterGroups[.hierarchical(name: groupName)].flatMap { $0 as? FilterGroup.Hierarchical }
  }
  
  func hierarchicalAttributes(forGroupWithName groupName: String) -> [Attribute] {
    return hierarchicalGroup(withName: groupName)?.hierarchicalAttributes ?? []
  }
  
  func hierarchicalFilters(forGroupWithName groupName: String) -> [Filter.Facet] {
    return hierarchicalGroup(withName: groupName)?.hierarchicalFilters ?? []

  }
  
  mutating func set(_ hierarchicalAttributes: [Attribute], forGroupWithName groupName: String) {
    let groupID: FilterGroup.ID = .hierarchical(name: groupName)
    var updatedGroup: FilterGroup.Hierarchical = (filterGroups[groupID] as? FilterGroup.Hierarchical) ?? .init(filters: [], name: groupName)
    updatedGroup.hierarchicalAttributes = hierarchicalAttributes
    filterGroups[groupID] = updatedGroup
  }
  
  mutating func set(_ hierarchicalFilters: [Filter.Facet], forGroupWithName groupName: String) {
    let groupID: FilterGroup.ID = .hierarchical(name: groupName)
    var updatedGroup: FilterGroup.Hierarchical = (filterGroups[groupID] as? FilterGroup.Hierarchical) ?? .init(filters: [], name: groupName)
    updatedGroup.hierarchicalFilters = hierarchicalFilters
    filterGroups[groupID] = updatedGroup
  }
  
}
