//
//  FilterComparisonConnectFilterState.swift
//  InstantSearchCore
//
//  Created by Guy Daher on 04/06/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public extension NumberViewModel {
  func connectFilterState(_ filterState: FilterState, attribute: Attribute, operator: Filter.Numeric.Operator, groupID: FilterGroup.ID? = nil) {

    let finalGroupID = groupID ?? FilterGroup.ID.and(name: attribute.name)

    filterState.onChange.subscribePast(with: self) { [weak self] (filterStateReadable) in

      let numericFilters: [Filter.Numeric] =
        filterStateReadable
          .getFilters(forGroupWithID: finalGroupID)
          .filter { $0.filter.attribute == attribute }
          .compactMap { $0.filter as? Filter.Numeric }

      self?.item = numericFilters.compactMap { numericFilter in
        switch numericFilter.value {
        case .range: return nil
        case .comparison(let potentialOperator, let value):
          return potentialOperator == `operator` ? Number(value) : nil
        }

      }.first
    }

    onNumberComputed.subscribePast(with: self) { [weak self] (computed) in
      guard let strongSelf = self else { return }
      
      if let item = strongSelf.item {
        filterState.filters.remove(Filter.Numeric(attribute: attribute, operator: `operator`, value: item.toFloat()), fromGroupWithID: finalGroupID)
      }

      if let computed = computed {
        filterState.filters.add(Filter.Numeric(attribute: attribute, operator: `operator`, value: computed.toFloat()), toGroupWithID: finalGroupID)
      }

      filterState.notifyChange()
    }
  }
}
