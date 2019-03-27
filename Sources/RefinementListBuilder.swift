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
  func getRefinementList(refinementValues: [String],
                         facetValues: [FacetValue]?,
                         sorting: RefinementListViewModel.Sorting,
                         showSelectedValuesOnTop: Bool,
                         keepSelectedValuesWithZeroCount: Bool) -> [FacetValue]
}

class RefinementListBuilder: RefinementListBuilding {

  /// Add missing refinements with a count of 0 to all returned facetValues
  /// Example: if in result we have color: [(red, 10), (green, 5)] and that in the refinements
  /// we have "color: red" and "color: yellow", the final output would be [(red, 10), (green, 5), (yellow, 0)]
  func merge(_ facetValues: [FacetValue]?, withRefinementValues refinementValues: [String]) -> [FacetValue] {
    var values = [FacetValue]()
    if let facetValues = facetValues {
      facetValues.forEach { (facetValue) in
        values.append(facetValue)
      }
    }
    // Make sure there is a value at least for the refined values.
    refinementValues.forEach { (refinementValue) in
      if facetValues == nil || !facetValues!.contains { $0.value == refinementValue } {
        values.append(FacetValue(value: refinementValue, count: 0, highlighted: .none))
      }
    }

    return values
  }

  func getRefinementList(refinementValues: [String],
                         facetValues: [FacetValue]?,
                         sorting: RefinementListViewModel.Sorting,
                         showSelectedValuesOnTop: Bool,
                         keepSelectedValuesWithZeroCount: Bool) -> [FacetValue] {

    let facetList: [FacetValue]
    if keepSelectedValuesWithZeroCount {
      facetList = merge(facetValues, withRefinementValues: refinementValues)
    } else {
      facetList = facetValues ?? []
    }

    let sortedFacetList = facetList.sorted { (lhs, rhs) in

      let lhsChecked: Bool = refinementValues.contains(lhs.value)
      let rhsChecked: Bool = refinementValues.contains(rhs.value)

      if showSelectedValuesOnTop && lhsChecked != rhsChecked { // Refined wins
        return lhsChecked
      }

      let leftCount = lhs.count
      let rightCount = rhs.count
      let leftValueLowercased = lhs.value.lowercased()
      let rightValueLowercased = rhs.value.lowercased()

      switch sorting {
      case .count(order: .descending):
        // Biggest Count wins, else alphabetically by name
        return leftCount != rightCount ? leftCount > rightCount : leftValueLowercased < rightValueLowercased

      case .count(order: .ascending):
        // Smallest Count wins, else alphabetically by name
        return leftCount != rightCount ? leftCount < rightCount : leftValueLowercased < rightValueLowercased

      case .name(order: .descending):
        // Sort by Name descending. Else, Biggest Count wins by default
        return leftValueLowercased != rightValueLowercased ? leftValueLowercased > rightValueLowercased : leftCount > rightCount

      case .name(order: .ascending):
        // Sort by Name ascending. Else, Biggest Count wins by default
        return leftValueLowercased != rightValueLowercased ? leftValueLowercased < rightValueLowercased : leftCount > rightCount
      }
    }

    return sortedFacetList
  }
}
