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
  
}

extension FilterState: FiltersContainer {}

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
