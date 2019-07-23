//
//  SelectableSegmentInteractor+Filter.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 13/05/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public extension SelectableSegmentInteractor where SegmentKey == Int, Segment: FilterType {

  func connectSearcher(_ searcher: SingleIndexSearcher, attribute: Attribute) {
    searcher.indexQueryState.query.updateQueryFacets(with: attribute)
  }
  
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
  
  private func connectFilterState<Accessor: SpecializedGroupAccessor>(_ filterState: FilterState,
                                                                      via accessor: Accessor) where Accessor.Filter == Segment {
    whenSelectedComputedThenUpdateFilterState(filterState, via: accessor)
    whenFilterStateChangedThenUpdateSelected(filterState, via: accessor)
  }
  
  private func whenSelectedComputedThenUpdateFilterState<Accessor: SpecializedGroupAccessor>(_ filterState: FilterState,
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
    
  private func whenFilterStateChangedThenUpdateSelected<Accessor: SpecializedGroupAccessor>(_ filterState: FilterState,
                                                                                            via accessor: Accessor) where Accessor.Filter == Segment {
    let onChange: (SelectableSegmentViewModel, ReadOnlyFiltersContainer) -> Void = { viewModel, _ in
      viewModel.selected = viewModel.items.first(where: { accessor.contains($0.value) })?.key
    }
    
    onChange(self, ReadOnlyFiltersContainer(filtersContainer: filterState))
    
    filterState.onChange.subscribePast(with: self, callback: onChange)
  }
  
}

public extension SelectableSegmentInteractor where Segment: FilterType {
  
  func connectController<C: SelectableSegmentController>(_ controller: C, presenter: FilterPresenter? = .none) where C.SegmentKey == SegmentKey {
    
    func setControllerItems(controller: C, with items: [SegmentKey: Segment]) {
      let presenter = presenter ?? DefaultPresenter.Filter.present
      let itemsToPresent = items
        .map { ($0.key, presenter(Filter($0.value))) }
        .reduce(into: [:]) { $0[$1.0] = $1.1 }
      controller.setItems(items: itemsToPresent)
    }
    
    controller.setSelected(selected)
    controller.onClick = computeSelected(selecting:)
    onSelectedChanged.subscribePast(with: controller) { controller, selectedItem in
      controller.setSelected(selectedItem)
    }
    onItemsChanged.subscribePast(with: controller, callback: setControllerItems)
    
  }
  
}
