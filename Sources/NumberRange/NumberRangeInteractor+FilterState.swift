//
//  NumberRangeInteractor+FilterState.swift
//  InstantSearchCore
//
//  Created by Guy Daher on 14/06/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public extension NumberRangeInteractor {
  
  func connectFilterState(_ filterState: FilterState,
                          attribute: Attribute,
                          operator: RefinementOperator = .and,
                          groupName: String? = nil) {

    let groupName = groupName ?? attribute.name
    
    switch `operator` {
    case .and:
      connectFilterState(filterState, attribute: attribute, via: SpecializedAndGroupAccessor(filterState[and: groupName]))
    case .or:
      connectFilterState(filterState, attribute: attribute, via: filterState[or: groupName])
    }
    
  }
  
  private func connectFilterState<Accessor: SpecializedGroupAccessor>(_ filterState: FilterState, attribute: Attribute, via accessor: Accessor) where Accessor.Filter == Filter.Numeric {
    whenFilterStateChangedUpdateRange(filterState, attribute: attribute, accessor: accessor)
    whenRangeComputedUpdateFilterState(filterState, attribute: attribute, accessor: accessor)
  }
  
  private func whenFilterStateChangedUpdateRange<Accessor: SpecializedGroupAccessor>(_ filterState: FilterState, attribute: Attribute, accessor: Accessor) where Accessor.Filter == Filter.Numeric {
    
    func extractRange(from numericFilter: Filter.Numeric) -> ClosedRange<Number>? {
      switch numericFilter.value {
      case .range(let closedRange):
        return Number(closedRange.lowerBound)...Number(closedRange.upperBound)
      case .comparison:
        return nil
      }
    }
    
    filterState.onChange.subscribePast(with: self) { interactor, _ in
      interactor.item = accessor.filters(for: attribute).compactMap(extractRange).first
    }

  }
  
  private func whenRangeComputedUpdateFilterState<Accessor: SpecializedGroupAccessor>(_ filterState: FilterState, attribute: Attribute, accessor: Accessor) where Accessor.Filter == Filter.Numeric {
    
    func numericFilter(with range: ClosedRange<Number>) -> Filter.Numeric {
      let castedRange: ClosedRange<Float> = range.lowerBound.toFloat()...range.upperBound.toFloat()
      return .init(attribute: attribute, range: castedRange)

    }
    
    let removeCurrentItem = { [weak self] in
      guard let item = self?.item else { return }
      accessor.remove(numericFilter(with: item))
    }
    
    let addItem: (ClosedRange<Number>?) -> Void = { range in
      guard let range = range else { return }
      accessor.add(numericFilter(with: range))
    }
    
    onNumberRangeComputed.subscribePast(with: self) { [weak filterState] _, computedRange in
      removeCurrentItem()
      addItem(computedRange)
      filterState?.notifyChange()
    }

  }
  
}
