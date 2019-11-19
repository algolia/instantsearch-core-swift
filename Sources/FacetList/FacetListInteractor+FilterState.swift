//
//  FacetListInteractor+FilterState.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 02/08/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public extension FacetListInteractor {
  
  func connectFilterState(_ filterState: FilterState,
                          with attribute: Attribute,
                          operator: RefinementOperator,
                          groupName: String? = nil) {
    
    let groupName = groupName ?? attribute.name
    
    switch `operator` {
    case .and:
      connectFilterState(filterState, with: attribute, via: SpecializedAndGroupAccessor(filterState[and: groupName]))
    case .or:
      connectFilterState(filterState, with: attribute, via: filterState[or: groupName])
    }
  }
  
}

private extension FacetListInteractor {
  
  func connectFilterState<Accessor: SpecializedGroupAccessor>(_ filterState: FilterState, with attribute: Attribute, via accessor: Accessor) where Accessor.Filter == Filter.Facet {
    whenSelectionsComputedThenUpdateFilterState(filterState, attribute: attribute, via: accessor)
    whenFilterStateChangedThenUpdateSelections(filterState: filterState, via: accessor)
  }
  
  func whenSelectionsComputedThenUpdateFilterState<Accessor: SpecializedGroupAccessor>(_ filterState: FilterState,
                                                                                       attribute: Attribute,
                                                                                       via accessor: Accessor) where Accessor.Filter == Filter.Facet {
    onSelectionsComputed.subscribePast(with: self) { [weak filterState] _, selections in
      let filters = selections.map { Filter.Facet(attribute: attribute, stringValue: $0) }
      accessor.removeAll()
      accessor.addAll(filters)
      filterState?.notifyChange()
    }
    
  }
  
  func whenFilterStateChangedThenUpdateSelections<Accessor: SpecializedGroupAccessor>(filterState: FilterState, via accessor: Accessor) where Accessor.Filter == Filter.Facet {
    
    func extractString(from filter: Filter.Facet) -> String? {
      if case .string(let stringValue) = filter.value {
        return stringValue
      } else {
        return nil
      }
    }
    
    filterState.onChange.subscribePast(with: self) { interactor, _ in
      interactor.selections = Set(accessor.filters().compactMap(extractString))
    }
  }
    
}
