//
//  RefinementListBuilder.swift
//  InstantSearchCore
//
//  Created by Guy Daher on 18/03/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public protocol RefinementListPresenterDelegate {
  func processFacetValues(selectedValues: [String],
                         resultValues: [FacetValue]?,
                         sortBy: [RefinementListViewModel.Sorting],
                         keepSelectedValuesWithZeroCount: Bool) -> [FacetValue]
}

/// Takes care of building the content of a refinement list given the following:
/// - The list of Facets + Associated Count
/// - The list of Facets that have been refined
/// - Layout settings such as sortBy
class RefinementListPresenter: RefinementListPresenterDelegate {

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

  /// Builds the final list to be displayed in the refinement list
  func processFacetValues(selectedValues: [String],
                         resultValues: [FacetValue]?,
                         sortBy: [RefinementListViewModel.Sorting],
                         keepSelectedValuesWithZeroCount: Bool) -> [FacetValue] {

    let facetList: [FacetValue]
    if keepSelectedValuesWithZeroCount {
      facetList = merge(resultValues, withRefinementValues: selectedValues)
    } else {
      facetList = resultValues ?? []
    }

    let sortedFacetList = facetList.sorted { (lhs, rhs) in

      let lhsChecked: Bool = selectedValues.contains(lhs.value)
      let rhsChecked: Bool = selectedValues.contains(rhs.value)

      let leftCount = lhs.count
      let rightCount = rhs.count
      let leftValueLowercased = lhs.value.lowercased()
      let rightValueLowercased = rhs.value.lowercased()

      // tiebreaking algorithm to do determine the sorting. 
      for sorting in sortBy {

        switch sorting {
        case .isRefined:
          if lhsChecked != rhsChecked {
            return lhsChecked
          }

        case .count(order: .descending):
          if leftCount != rightCount {
            return leftCount > rightCount
          }

        case .count(order: .ascending):
          if leftCount != rightCount {
            return leftCount < rightCount
          }

        case .alphabetical(order: .descending):
          if leftValueLowercased != rightValueLowercased {
            return leftValueLowercased > rightValueLowercased
          }

        case .alphabetical(order: .ascending):
          // Sort by Name ascending. Else, Biggest Count wins by default
          if leftValueLowercased != rightValueLowercased {
            return leftValueLowercased < rightValueLowercased
          }
        }
      }

      return true
    }

    return sortedFacetList
  }
}
