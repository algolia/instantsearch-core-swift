//
//  RefinementListBuilder.swift
//  InstantSearchCore
//
//  Created by Guy Daher on 18/03/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public typealias SelectableItem<T> = (item: T, isSelected: Bool)
public typealias RefinementFacet = SelectableItem<FacetValue>

public protocol SelectableListPresentable {

  func processFacetValues(selectedValues: [String],
                          resultValues: [FacetValue]?) -> [RefinementFacet]
}

/// Takes care of building the content of a refinement list given the following:
/// - The list of Facets + Associated Count
/// - The list of Facets that have been refined
/// - Layout settings such as sortBy
public class RefinementFacetsPresenter: SelectableListPresentable {

  let sortBy: [FacetSortCriterion]
  let limit: Int

  public init(sortBy: [FacetSortCriterion] = [.count(order: .descending)],
              limit: Int = 10) {
    self.sortBy = sortBy
    self.limit = limit
  }

  /// Builds the final list to be displayed in the refinement list
  public func processFacetValues(selectedValues: [String],
                                 resultValues: [FacetValue]?) -> [RefinementFacet] {

    let facetList: [RefinementFacet] = merge(resultValues, withSelectedValues: selectedValues)

    let sortedFacetList = facetList.sorted { (lhs, rhs) in

      let lhsChecked: Bool = lhs.isSelected
      let rhsChecked: Bool = rhs.isSelected

      let leftCount = lhs.item.count
      let rightCount = rhs.item.count
      let leftValueLowercased = lhs.item.value.lowercased()
      let rightValueLowercased = rhs.item.value.lowercased()

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

    return Array(sortedFacetList[..<min(limit, sortedFacetList.count)])
  }
}

private extension RefinementFacetsPresenter {
  
  /// Add missing refinements with a count of 0 to all returned facetValues
  /// Example: if in result we have color: [(red, 10), (green, 5)] and that in the refinements
  /// we have "color: red" and "color: yellow", the final output would be [(red, 10), (green, 5), (yellow, 0)]
  
  //TODO: MOVE MERGE OUT OF PRESENTER
  // The signature for processFacetValues should be [RefinementFacet] -> [RefinementFacet]
  func merge(_ facetValues: [FacetValue]?, withSelectedValues selectedValues: [String]) -> [RefinementFacet] {

    var values = [RefinementFacet]()
    if let facetValues = facetValues {
      facetValues.forEach { (facetValue) in

        values.append((facetValue, selectedValues.contains(facetValue.value)))
      }
    }
    // Make sure there is a value at least for the refined values.
    selectedValues.forEach { (refinementValue) in
      if facetValues == nil || !facetValues!.contains { $0.value == refinementValue } {
        values.append((FacetValue(value: refinementValue, count: 0, highlighted: .none), true))
      }
    }
    
    return values
  }
  
}
