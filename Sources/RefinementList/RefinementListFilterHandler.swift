//
//  RefinementListFilterHandler.swift
//  InstantSearchCore
//
//  Created by Guy Daher on 28/03/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public protocol RefinementListFilterDelegate {
  func didSelect(value: String, operator: RefinementListViewModel.Settings.RefinementOperator)
  func isRefined(value: String, operator: RefinementListViewModel.Settings.RefinementOperator) -> Bool
  func selectedValues() -> [String]
}

/// Business logic for the different actions on the Refinement list related to filtering.
/// Mainly, the onSelect action, and determining if a certain value is selected or not.
class RefinementListFilterHandler: RefinementListFilterDelegate {

  let filterState: FilterState
  let attribute: Attribute
  let group: Group

  private var orGroup: OrFilterGroupID<Filter.Facet> {
    return OrFilterGroupID(name: group.name)
  }

  private var andGroup: AndFilterGroupID {
    return AndFilterGroupID(name: group.name)
  }

  public init(attribute: Attribute, filterState: FilterState, group: Group) {
    self.filterState = filterState
    self.group = group
    self.attribute = attribute
  }

  public func didSelect(value: String, operator: RefinementListViewModel.Settings.RefinementOperator) {
    let filterFacet = Filter.Facet(attribute: attribute, stringValue: value)

    switch `operator` {
    case .or:
      filterState.toggle(filterFacet, in: orGroup)
    case .and(.multiple):
      filterState.toggle(filterFacet, in: andGroup)
    case .and(selection: .single):
      if filterState.contains(filterFacet, in: orGroup) {
        filterState.remove(filterFacet, from: orGroup)
      } else {
        filterState.removeAll(from: orGroup)
        filterState.add(filterFacet, to: orGroup)
      }
    }
  }

  public func isRefined(value: String, operator: RefinementListViewModel.Settings.RefinementOperator) -> Bool {
    let filterFacet = Filter.Facet(attribute: attribute, stringValue: value)

    switch `operator` {
    case .or, .and(selection: .single):
      return filterState.contains(filterFacet, in: orGroup)
    case .and(selection: .multiple):
      return filterState.contains(filterFacet, in: andGroup)
    }
  }

  public func selectedValues() -> [String] {
    let refinedFilterFacets: Set<Filter.Facet> = filterState.getFilters(for: attribute)
    return refinedFilterFacets.map { $0.value.description }
  }
}
