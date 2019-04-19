//
//  RefinementFacetsPresenter.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 19/04/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

class RefinementFacetsPresenter: SelectionListPresenter {

  typealias Item = FacetValue
  
  var values: [SelectableItem<FacetValue>]
  
  var sortBy: [SortCriterion] = [.count(order: .descending), .alphabetical(order: .ascending)] {
    didSet {
      recomputeValues()
    }
  }
  
  var limit: Int {
    didSet {
      recomputeValues()
    }
  }
  
  let onValuesChanged: Observer<[(item: FacetValue, isSelected: Bool)]>

  var comparator: SelectableItemComparator {
    return { (lhs, rhs) -> Bool in
      return self.sortBy.map { (criterion) -> Bool? in
        
        switch criterion {
        case .isRefined where lhs.isSelected != rhs.isSelected:
          return lhs.1
          
        case .count(order: .descending) where lhs.item.count != rhs.item.count:
          return lhs.item.count > rhs.item.count
          
        case .count(order: .ascending) where lhs.item.count != rhs.item.count:
          return lhs.item.count < rhs.item.count
          
        case .alphabetical(order: .descending) where lhs.item.value.lowercased() != rhs.item.value.lowercased():
          return lhs.item.value.lowercased() > rhs.item.value.lowercased()
          
        case .alphabetical(order: .ascending) where lhs.item.value.lowercased() != rhs.item.value.lowercased():
          // Sort by Name ascending. Else, Biggest Count wins by default
          return lhs.item.value.lowercased() < rhs.item.value.lowercased()
          
        default:
          return nil
        }
        }.compactMap { $0 }.first ?? true
      
    }
  }
  
  public init(sortBy: [SortCriterion], limit: Int = 10, values: [SelectableItem<FacetValue>]) {
    self.sortBy = sortBy
    self.limit = limit
    self.values = values
    self.onValuesChanged = Observer()
    recomputeValues()
  }
  
  func recomputeValues() {
    self.values = Array(values.sorted(by: comparator)[..<limit])
  }
  
}
