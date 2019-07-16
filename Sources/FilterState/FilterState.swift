//
//  FilterState.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 18/04/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation
import Signals

public class FilterState: FiltersContainer {
  
  public var filters: FiltersReadable & FiltersWritable & FilterGroupsConvertible & HierarchicalManageable
  
  public var onChange: Observer<FiltersReadable>

  public init() {
    self.filters = GroupsStorage()
    self.onChange = Observer<FiltersReadable>()
  }

  public func notifyChange() {
    onChange.fire(filters)
  }
  
  func and(name: String) -> AndGroupProxy {
    return .init(filtersContainer: self, groupName: name)
  }
  
  func or<F: FilterType>(name: String) -> OrGroupProxy<F> {
    return .init(filtersContainer: self, groupName: name)
  }
  
  func hierarchical(name: String) -> HierarchicalGroupProxy {
    return .init(filtersContainer: self, groupName: name)
  }
  
}

extension FilterState: FiltersReadable {
  
  public func getGroupIDs() -> Set<FilterGroup.ID> {
    return filters.getGroupIDs()
  }
  
  public var isEmpty: Bool {
    return self.filters.isEmpty
  }
  
  public func contains(_ filter: FilterType, inGroupWithID groupID: FilterGroup.ID) -> Bool {
    return self.filters.contains(filter, inGroupWithID: groupID)
  }
  
  public func getFilters(forGroupWithID groupID: FilterGroup.ID) -> Set<Filter> {
    return self.filters.getFilters(forGroupWithID: groupID)
  }
  
  public func getFilters(for attribute: Attribute) -> Set<Filter> {
    return self.filters.getFilters(for: attribute)
  }
  
  public func getFilters() -> Set<Filter> {
    return self.filters.getFilters()
  }

  public func getFiltersAndID() -> Set<FilterAndID> {
    return self.filters.getFiltersAndID()
  }
  
}

extension FilterState: FiltersWritable {
  
  public func add(_ filter: FilterType, toGroupWithID groupID: FilterGroup.ID) {
    self.filters.add(filter, toGroupWithID: groupID)
  }
  
  public func addAll<S: Sequence>(filters: S, toGroupWithID groupID: FilterGroup.ID) where S.Element == FilterType {
    self.filters.addAll(filters: filters, toGroupWithID: groupID)
  }
  
  @discardableResult public func remove(_ filter: FilterType, fromGroupWithID groupID: FilterGroup.ID) -> Bool {
    return self.filters.remove(filter, fromGroupWithID: groupID)
  }
  
  @discardableResult public func removeAll<S: Sequence>(_ filters: S, fromGroupWithID groupID: FilterGroup.ID) -> Bool where S.Element == FilterType {
    return self.filters.removeAll(filters, fromGroupWithID: groupID)
  }
  
  public func removeAll(fromGroupWithID groupID: FilterGroup.ID) {
    return self.filters.removeAll(fromGroupWithID: groupID)
  }

  public func removeAll(fromGroupWithIDs groupIDs: [FilterGroup.ID]) {
    return self.filters.removeAll(fromGroupWithIDs: groupIDs)
  }

  public func removeAllExcept(fromGroupWithIDs groupIDs: [FilterGroup.ID]) {
    return self.filters.removeAllExcept(fromGroupWithIDs: groupIDs)
  }
  
  @discardableResult public func remove(_ filter: FilterType) -> Bool {
    return self.filters.remove(filter)
  }
  
  public func removeAll<S: Sequence>(_ filters: S) where S.Element == FilterType {
    self.filters.removeAll(filters)
  }
  
  public func removeAll(for attribute: Attribute, fromGroupWithID groupID: FilterGroup.ID) {
    self.filters.removeAll(for: attribute, fromGroupWithID: groupID)
  }
  
  public func removeAll(for attribute: Attribute) {
    self.filters.removeAll(for: attribute)
  }
  
  public func removeAll() {
    self.filters.removeAll()
  }
  
  public func toggle(_ filter: FilterType, inGroupWithID groupID: FilterGroup.ID) {
    self.filters.toggle(filter, inGroupWithID: groupID)
  }
  
  public func toggle<S: Sequence>(_ filters: S, inGroupWithID groupID: FilterGroup.ID) where S.Element == FilterType {
    self.filters.toggle(filters, inGroupWithID: groupID)
  }
  
}

extension FilterState: FilterGroupsConvertible {
  
  public func toFilterGroups() -> [FilterGroupType] {
    return filters.toFilterGroups()
  }
  
}

extension FilterState: CustomDebugStringConvertible {

  public var debugDescription: String {
    return FilterGroupConverter().sql(toFilterGroups()) ?? "empty"
  }

}

extension FilterState: DisjunctiveFacetingDelegate {
    
  public var disjunctiveFacetsAttributes: Set<Attribute> {
    return filters.disjunctiveFacetsAttributes
  }
  
}
