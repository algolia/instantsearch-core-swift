//
//  NumberRangeViewModel+FilterState.swift
//  InstantSearchCore
//
//  Created by Guy Daher on 14/06/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public extension NumberRangeViewModel {
  func connectFilterState(_ filterState: FilterState, attribute: Attribute, groupID: FilterGroup.ID? = nil) {

    let finalGroupID = groupID ?? FilterGroup.ID.and(name: attribute.name)

    filterState.onChange.subscribePast(with: self) { [weak self] (filterStateReadable) in

      let numericFilters: [Filter.Numeric] =
        filterStateReadable
          .getFilters(forGroupWithID: finalGroupID)
          .filter { $0.filter.attribute == attribute }
          .compactMap { $0.filter as? Filter.Numeric }

      self?.item = numericFilters.compactMap { numericFilter in
        switch numericFilter.value {
        case .range(let closedRange): return Number(closedRange.lowerBound)...Number(closedRange.upperBound)
        case .comparison: return nil
        }
        }.first
    }

    onNumberRangeComputed.subscribePast(with: self) { [weak self] (computed) in
      guard let strongSelf = self else { return }

      if let item = strongSelf.item {
        filterState.remove(Filter.Numeric(attribute: attribute, range: item.lowerBound.toFloat()...item.upperBound.toFloat()), fromGroupWithID: finalGroupID)
      }

      if let computed = computed {
        filterState.add(Filter.Numeric(attribute: attribute, range: computed.lowerBound.toFloat()...computed.upperBound.toFloat()), toGroupWithID: finalGroupID)
      }

      filterState.notifyChange()
    }
  }
}
