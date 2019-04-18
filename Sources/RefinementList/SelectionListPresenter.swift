//
//  SelectionListPresenter.swift
//  InstantSearchCore
//
//  Created by Guy Daher on 18/04/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

class RefinementFacetsPresenter: SelectionListPresenter<FacetValue> {

  var sortBy: [SortCriterion] = [.count(order: .descending), .alphabetical(order: .ascending)]

  public init(sortBy: [SortCriterion],
              limit: Int = 10) {
    super.init { (lhs, rhs) -> Bool in
      return sortBy.map { (criterion) -> Bool? in
        switch criterion {
        case .isRefined:
          if lhs.1 != rhs.1 {
            return lhs.1
          }
          
        case .count(order: .descending):
          if lhs.0.count != rhs.0.count {
            return lhs.0.count > rhs.0.count
          }
          
        case .count(order: .ascending):
          if lhs.0.count != rhs.0.count {
            return lhs.0.count < rhs.0.count
          }
          
        case .alphabetical(order: .descending):
          if lhs.0.value.lowercased() != rhs.0.value.lowercased() {
            return lhs.0.value.lowercased() > rhs.0.value.lowercased()
          }
          
        case .alphabetical(order: .ascending):
          // Sort by Name ascending. Else, Biggest Count wins by default
          if lhs.0.value.lowercased() != rhs.0.value.lowercased() {
            return lhs.0.value.lowercased() < rhs.0.value.lowercased()
          }
        }
        
        return nil
      }.compactMap { $0 }.first ?? true
      
    }
    self.sortBy = sortBy
  }

}

public class SelectionListPresenter<T: Equatable> {

  public typealias SelectableItemComparator = (SelectableItem<T>, SelectableItem<T>) -> Bool

  public let comparator: SelectableItemComparator

  public init(comparator: @escaping SelectableItemComparator) {
    self.comparator = comparator
  }

  var limit: Int = 10 {
    didSet {
      values = computeValues(values)
    }
  }

  public var values: [SelectableItem<T>] = [] {
    didSet {
      values = computeValues(values)
    }
  }

  public var onValuesChanged = Observer<SelectableItem<T>>()

  private func computeValues(_ values: [SelectableItem<T>]) -> [SelectableItem<T>] {
    return Array(values.sorted(by: comparator)[..<limit])
  }
}
