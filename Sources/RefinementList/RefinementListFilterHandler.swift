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

  let filterBuilder: FilterBuilder
  let attribute: Attribute
  let group: Group

  private var orGroup: OrFilterGroup<FilterFacet> {
    return OrFilterGroup(name: group.name)
  }

  private var andGroup: AndFilterGroup {
    return AndFilterGroup(name: group.name)
  }

  public init(attribute: Attribute, filterBuilder: FilterBuilder, group: Group) {
    self.filterBuilder = filterBuilder
    self.group = group
    self.attribute = attribute
  }

  public func didSelect(value: String, operator: RefinementListViewModel.Settings.RefinementOperator) {
    let filterFacet = FilterFacet(attribute: attribute, stringValue: value)

    switch `operator` {
    case .or:
      filterBuilder.toggle(filterFacet, in: orGroup)
    case .and(.multiple):
      filterBuilder.toggle(filterFacet, in: andGroup)
    case .and(selection: .single):
      if filterBuilder.contains(filterFacet, in: orGroup) {
        filterBuilder.remove(filterFacet, from: orGroup)
      } else {
        filterBuilder.removeAll(from: orGroup)
        filterBuilder.add(filterFacet, to: orGroup)
      }
    }
  }

  public func isRefined(value: String, operator: RefinementListViewModel.Settings.RefinementOperator) -> Bool {
    let filterFacet = FilterFacet(attribute: attribute, stringValue: value)

    switch `operator` {
    case .or, .and(selection: .single):
      return filterBuilder.contains(filterFacet, in: orGroup)
    case .and(selection: .multiple):
      return filterBuilder.contains(filterFacet, in: andGroup)
    }
  }

  public func selectedValues() -> [String] {
    let refinedFilterFacets: Set<FilterFacet> = filterBuilder.getFilters(for: attribute)
    return refinedFilterFacets.map { $0.value.description }
  }
}
