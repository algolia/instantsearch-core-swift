//
//  FilterState+FiltersWritable.swift
//  InstantSearchCore-iOS
//
//  Created by Vladislav Fitc on 19/07/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

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
    return self.filters.removeAllExcept(groupIDs)
  }
  
  @discardableResult public func remove(_ filter: FilterType) -> Bool {
    return self.filters.remove(filter)
  }
  
  public func removeAll<S: Sequence>(_ filters: S) -> Bool where S.Element == FilterType {
    return self.filters.removeAll(filters)
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
