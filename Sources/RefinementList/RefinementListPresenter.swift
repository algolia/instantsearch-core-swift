//
//  RefinementListBuilder.swift
//  InstantSearchCore
//
//  Created by Guy Daher on 18/03/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public typealias SelectableItem<T> = (item: T, isSelected: Bool)
public typealias RefinementFacet = SelectableItem<Facet>

public protocol SelectableListPresentable {

  func transform(refinementFacets: [RefinementFacet]) -> [RefinementFacet]
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
  public func transform(refinementFacets: [RefinementFacet]) -> [RefinementFacet] {

    let sortedFacetList = refinementFacets.sorted { (lhs, rhs) in

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
