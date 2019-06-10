//
//  FilterState.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 18/04/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation
import Signals

public class FilterState {
  
  var filters: Filters
  
  public var onChange: Observer<FiltersReadable>

  public init(groups: [FilterGroup.ID: Set<Filter>]? = nil) {
    if let groups = groups {
      self.filters = Filters(groups)
    } else {
      self.filters = Filters()
    }

    self.onChange = Observer<FiltersReadable>()
  }

  public func notifyChange() {
    onChange.fire(filters)
  }
  
}

extension FilterState: FiltersReadable {
  
  public var isEmpty: Bool {
    return self.filters.isEmpty
  }
  
  public func contains<T>(_ filter: T) -> Bool where T: FilterType {
    return self.filters.contains(filter)
  }
  
  public func contains<T>(_ filter: T, inGroupWithID groupID: FilterGroup.ID) -> Bool where T: FilterType {
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
  
}

extension FilterState: FiltersWritable {
  
  public func add<T>(_ filter: T, toGroupWithID groupID: FilterGroup.ID) where T: FilterType {
    self.filters.add(filter, toGroupWithID: groupID)
  }
  
  public func addAll<T, S>(filters: S, toGroupWithID groupID: FilterGroup.ID) where T: FilterType, T == S.Element, S: Sequence {
    self.filters.addAll(filters: filters, toGroupWithID: groupID)
  }
  
  @discardableResult public func remove<T>(_ filter: T, fromGroupWithID groupID: FilterGroup.ID) -> Bool where T: FilterType {
    return self.filters.remove(filter, fromGroupWithID: groupID)
  }
  
  @discardableResult public func removeAll<T, S>(_ filters: S, fromGroupWithID groupID: FilterGroup.ID) -> Bool where T: FilterType, T == S.Element, S: Sequence {
    return self.filters.removeAll(filters, fromGroupWithID: groupID)
  }
  
  public func removeAll(fromGroupWithID groupID: FilterGroup.ID) {
    return self.filters.removeAll(fromGroupWithID: groupID)
  }
  
  @discardableResult public func remove<T>(_ filter: T) -> Bool where T: FilterType {
    return self.filters.remove(filter)
  }
  
  public func removeAll<T, S>(_ filters: S) where T: FilterType, T == S.Element, S: Sequence {
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
  
  public func toggle<T>(_ filter: T, inGroupWithID groupID: FilterGroup.ID) where T: FilterType {
    self.filters.toggle(filter, inGroupWithID: groupID)
  }
  
  public func toggle<T, S>(_ filters: S, inGroupWithID groupID: FilterGroup.ID) where T: FilterType, T == S.Element, S: Sequence {
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
  
  public var disjunctiveFacetsAttributes: [String] {
    return Array(filters.getDisjunctiveFacetsAttributes()).map { $0.description }
  }
  
  public var facetFilters: [String: [String]] {
    return filters.getRawFacetFilters()
  }
  
}
