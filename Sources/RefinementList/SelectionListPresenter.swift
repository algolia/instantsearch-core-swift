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
    super.init(comparator: <#T##((FacetValue, Bool), (FacetValue, Bool)) -> Bool#>)
    self.sortBy = sortBy
  }

  let comparator = 

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
