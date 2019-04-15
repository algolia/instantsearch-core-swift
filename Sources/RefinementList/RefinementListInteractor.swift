//
//  RefinementListFilterHandler.swift
//  InstantSearchCore
//
//  Created by Guy Daher on 28/03/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public protocol RefinementListInteractorDelegate {
  func didSelect(value: String, operator: RefinementListViewModel.Settings.RefinementOperator)
  func isRefined(value: String, operator: RefinementListViewModel.Settings.RefinementOperator) -> Bool
  func selectedValues(operator: RefinementListViewModel.Settings.RefinementOperator) -> [String]
}

/// Business logic for the different actions on the Refinement list related to filtering.
/// Mainly, the onSelect action, and determining if a certain value is selected or not.
class RefinementListInteractor: RefinementListInteractorDelegate {

  var filterState: FilterState
  let attribute: Attribute
  let groupID: FilterGroup.ID

  public init(attribute: Attribute, filterState: FilterState, groupID: FilterGroup.ID) {
    self.filterState = filterState
    self.groupID = groupID
    self.attribute = attribute
  }

  public func didSelect(value: String, operator: RefinementListViewModel.Settings.RefinementOperator) {
    let filterFacet = Filter.Facet(attribute: attribute, stringValue: value)

    switch `operator` {
    case .or, .and(.multiple):
      filterState.toggle(filterFacet, in: groupID)
    case .and(selection: .single):
      if filterState.contains(filterFacet, in: groupID) {
        filterState.remove(filterFacet, from: groupID)
      } else {
        filterState.removeAll(from: groupID)
        filterState.add(filterFacet, to: groupID)
      }
    }
  }

  public func isRefined(value: String, operator: RefinementListViewModel.Settings.RefinementOperator) -> Bool {
    let filterFacet = Filter.Facet(attribute: attribute, stringValue: value)

    switch `operator` {
    case .or, .and(selection: .single):
      return filterState.contains(filterFacet, in: groupID)
    case .and(selection: .multiple):
      return filterState.contains(filterFacet, in: groupID)
    }
  }

  public func selectedValues(operator: RefinementListViewModel.Settings.RefinementOperator) -> [String] {
    let refinedFilterFacets: [Filter.Facet]
    switch `operator` {
    case .or, .and(selection: .single):
      refinedFilterFacets = filterState.getFilters(for: groupID).compactMap { $0.filter as? Filter.Facet }
    case .and(selection: .multiple):
      refinedFilterFacets = filterState.getFilters(for: groupID).compactMap { $0.filter as? Filter.Facet }
    }
    return refinedFilterFacets.map { $0.value.description }
  }
}
