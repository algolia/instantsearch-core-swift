//
//  SelectableSegmentInteractor+Filter+FilterState.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 02/08/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public extension SelectableSegmentInteractor where SegmentKey == Int, Segment: FilterType {

  func connectFilterState(_ filterState: FilterState,
                          attribute: Attribute,
                          operator: RefinementOperator,
                          groupName: String? = nil) {
    
    let groupName = groupName ?? attribute.name
    
    switch `operator` {
    case .and:
      connectFilterState(filterState, via: SpecializedAndGroupAccessor(filterState[and: groupName]))
    case .or:
      connectFilterState(filterState, via: filterState[or: groupName])
    }
    
  }
  
}

private extension SelectableSegmentInteractor where SegmentKey == Int, Segment: FilterType {

  func connectFilterState<Accessor: SpecializedGroupAccessor>(_ filterState: FilterState,
                                                              via accessor: Accessor) where Accessor.Filter == Segment {
    whenSelectedComputedThenUpdateFilterState(filterState, via: accessor)
    whenFilterStateChangedThenUpdateSelected(filterState, via: accessor)
  }
  
  func whenSelectedComputedThenUpdateFilterState<Accessor: SpecializedGroupAccessor>(_ filterState: FilterState,
                                                                                     via accessor: Accessor) where Accessor.Filter == Segment {
    
    let removeSelectedItem = { [weak self] in
      self?.selected.flatMap { self?.items[$0] }.flatMap(accessor.remove)
    }
    
    let addItem: (SegmentKey?) -> Void = { [weak self] itemKey in
      itemKey.flatMap { self?.items[$0] }.flatMap { accessor.add($0) }
    }
    
    onSelectedComputed.subscribePast(with: self) { [weak filterState] _, computedSelectionKey in
      removeSelectedItem()
      addItem(computedSelectionKey)
      filterState?.notifyChange()
    }
    
  }
  
  func whenFilterStateChangedThenUpdateSelected<Accessor: SpecializedGroupAccessor>(_ filterState: FilterState,
                                                                                    via accessor: Accessor) where Accessor.Filter == Segment {
    let onChange: (SelectableSegmentInteractor, ReadOnlyFiltersContainer) -> Void = { interactor, _ in
      interactor.selected = interactor.items.first(where: { accessor.contains($0.value) })?.key
    }
    
    onChange(self, ReadOnlyFiltersContainer(filtersContainer: filterState))
    
    filterState.onChange.subscribePast(with: self, callback: onChange)
  }
  
}
