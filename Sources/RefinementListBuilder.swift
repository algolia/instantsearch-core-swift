//
//  RefinementListBuilder.swift
//  InstantSearchCore
//
//  Created by Guy Daher on 18/03/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

typealias IsRefinedHandler = (_ filterFacet: FilterFacet) -> Bool

protocol RefinementListBuilding {
  func getRefinementList(on attribute: Attribute,
                         refinedFilterFacets: Set<FilterFacet>,
                         facetValues: [FacetValue]?,
                         sorting: RefinementListViewModel.Sorting,
                         areRefinedValuesFirst: Bool,
                         isRefinedHandler: IsRefinedHandler?) -> [FacetValue]
}

class RefinementListBuilder: RefinementListBuilding {

  /// Add missing refinements with a count of 0 to all returned facetValues
  /// Example: if in result we have color: [(red, 10), (green, 5)] and that in the refinements
  /// we have "color: red" and "color: yellow", the final output would be [(red, 10), (green, 5), (yellow, 0)]
  func merge(_ facetValues: [FacetValue]?, with refinements: Set<FilterFacet>) -> [FacetValue] {
    var values = [FacetValue]()
    if let facetValues = facetValues {
      facetValues.forEach { (facetValue) in
        values.append(facetValue)
      }
    }
    // Make sure there is a value at least for the refined values.
    refinements.forEach { (filterFacet) in
      let refinementValue = filterFacet.value.description
      if facetValues == nil || !facetValues!.contains { $0.value == refinementValue } {
        values.append(FacetValue(value: refinementValue, count: 0, highlighted: .none))
      }
    }

    return values
  }

  func getRefinementList(on attribute: Attribute,
                         refinedFilterFacets: Set<FilterFacet>,
                         facetValues: [FacetValue]?,
                         sorting: RefinementListViewModel.Sorting,
                         areRefinedValuesFirst: Bool = false,
                         isRefinedHandler: IsRefinedHandler? = nil) -> [FacetValue] {

    let facetList = merge(facetValues, with: refinedFilterFacets)

    let sortedFacetList = facetList.sorted { (lhs, rhs) in
      let lhsFilterFacet = FilterFacet(attribute: attribute, stringValue: lhs.value)
      let rhsFilterFacet = FilterFacet(attribute: attribute, stringValue: rhs.value)

      let lhsChecked: Bool = isRefinedHandler?(lhsFilterFacet) ?? false
      let rhsChecked: Bool = isRefinedHandler?(rhsFilterFacet) ?? false

      if areRefinedValuesFirst && lhsChecked != rhsChecked { // Refined wins
        return lhsChecked
      }

      let leftCount = lhs.count
      let rightCount = rhs.count
      let leftValueLowercased = lhs.value.lowercased()
      let rightValueLowercased = rhs.value.lowercased()

      switch sorting {
      case .countDesc:
        if leftCount != rightCount { // Biggest Count wins
          return leftCount > rightCount
        } else {
          return leftValueLowercased < rightValueLowercased // Name ascending wins by default
        }

      case .countAsc:
        if leftCount != rightCount { // Smallest Count wins
          return leftCount < rightCount
        } else {
          return leftValueLowercased < rightValueLowercased // Name ascending wins by default
        }

      case .nameAsc:
        if leftValueLowercased != rightValueLowercased {
          return leftValueLowercased < rightValueLowercased // Name ascending
        } else {
          return leftCount > rightCount // Biggest Count wins by default
        }

      case .nameDsc:
        if leftValueLowercased != rightValueLowercased {
          return leftValueLowercased > rightValueLowercased // Name descending
        } else {
          return leftCount > rightCount // Biggest Count wins by default
        }
      }
    }

    return sortedFacetList
  }
}
