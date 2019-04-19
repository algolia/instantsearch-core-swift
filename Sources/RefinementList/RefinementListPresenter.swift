//
//  RefinementListBuilder.swift
//  InstantSearchCore
//
//  Created by Guy Daher on 18/03/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public typealias SelectableItem<T> = (item: T, isSelected: Bool)
public typealias SelectableRefinement = SelectableItem<FacetValue>

public protocol SelectableListPresentable {

  func processFacetValues(selectedValues: [String],
                          resultValues: [FacetValue]?,
                          sortBy: [SortCriterion],
                          keepSelectedValuesWithZeroCount: Bool) -> [FacetValue]
}

/// Takes care of building the content of a refinement list given the following:
/// - The list of Facets + Associated Count
/// - The list of Facets that have been refined
/// - Layout settings such as sortBy
public class RefinementListPresenter: SelectableListPresentable {

  /// Builds the final list to be displayed in the refinement list
  public func processFacetValues(selectedValues: [String],
                                 resultValues: [FacetValue]?,
                                 sortBy: [SortCriterion],
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
        case .isRefined where lhsChecked != rhsChecked:
          return lhsChecked

        case .count(order: .descending) where leftCount != rightCount:
          return leftCount > rightCount

        case .count(order: .ascending) where leftCount != rightCount:
          return leftCount < rightCount

        case .alphabetical(order: .descending) where leftValueLowercased != rightValueLowercased:
          return leftValueLowercased > rightValueLowercased

        // Sort by Name ascending. Else, Biggest Count wins by default
        case .alphabetical(order: .ascending) where leftValueLowercased != rightValueLowercased:
          return leftValueLowercased < rightValueLowercased
          
        default:
          break
        }
        
      }
      
      return true

    }

    return sortedFacetList
  }
}

private extension RefinementListPresenter {
  
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
  
}
