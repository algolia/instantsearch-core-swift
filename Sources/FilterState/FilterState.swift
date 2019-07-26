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
  
  var filters: FiltersReadable & FiltersWritable & FilterGroupsConvertible & HierarchicalManageable
  
  public var onChange: Observer<ReadOnlyFiltersContainer>

  public init() {
    self.filters = GroupsStorage()
    self.onChange = .init()
  }

  public func notifyChange() {
    onChange.fire(ReadOnlyFiltersContainer(filtersContainer: self))
  }
  
  public subscript(and groupName: String) -> AndGroupAccessor {
    return .init(filtersContainer: self, groupName: groupName)
  }
  
  public subscript<F: FilterType>(or groupName: String, type: F.Type) -> OrGroupAccessor<F> {
    return .init(filtersContainer: self, groupName: groupName)
  }
  
  public subscript<F: FilterType>(or groupName: String) -> OrGroupAccessor<F> {
    return .init(filtersContainer: self, groupName: groupName)
  }
  
  public subscript(hierarchical groupName: String) -> HierarchicalGroupAccessor {
    return .init(filtersContainer: self, groupName: groupName)
  }
  
}

extension FilterState: FiltersContainer {}

extension FilterState: FilterGroupsConvertible {
  
  public func toFilterGroups() -> [FilterGroupType] {
    return filters.toFilterGroups()
  }
  
}

extension FilterState: CustomStringConvertible {
  
  public var description: String {
    return FilterGroupConverter().sql(toFilterGroups()) ?? ""
  }

}

extension FilterState: CustomDebugStringConvertible {

  public var debugDescription: String {
    let filterGroups = toFilterGroups()
    guard !filterGroups.isEmpty else {
      return "FilterState {}"
    }
    let body = filterGroups.map { group in
      let groupName = (group.name ?? "")
      let filtersDescription = FilterGroupConverter().sql(group) ?? ""
      return " \"\(groupName)\": \(filtersDescription)"
    }.joined(separator: "\n")
    return "FilterState {\n\(body)\n}"
  }

}

extension FilterState: DisjunctiveFacetingDelegate {
    
  public var disjunctiveFacetsAttributes: Set<Attribute> {
    return filters.disjunctiveFacetsAttributes
  }
  
}

extension FilterState: HierarchicalDelegate {
  
  private var hierarchicalGroupName: String {
    return "_hierarchical"
  }
  
  public var hierarchicalFilters: [Filter.Facet] {
    get {
      return self[hierarchical: hierarchicalGroupName].hierarchicalFilters
    }
    
    set {
      self[hierarchical: hierarchicalGroupName].set(newValue)

    }
  }
  
  public var hierarchicalAttributes: [Attribute] {
    get {
      return self[hierarchical: hierarchicalGroupName].hierarchicalAttributes
    }
    
    set {
      self[hierarchical: hierarchicalGroupName].set(newValue)
    }
  }
  
}
