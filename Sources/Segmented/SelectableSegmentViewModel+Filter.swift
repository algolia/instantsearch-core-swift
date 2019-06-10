//
//  SelectableSegmentViewModel+Filter.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 13/05/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public extension SelectableSegmentViewModel where SegmentKey == Int, Segment: FilterType {

  func connectSearcher(_ searcher: SingleIndexSearcher, attribute: Attribute) {
    searcher.indexSearchData.query.updateQueryFacets(with: attribute)
  }
  
  func connectFilterState(_ filterState: FilterState,
                          attribute: Attribute,
                          operator: RefinementOperator,
                          groupName: String? = nil) {
    
    let groupID = FilterGroup.ID(groupName: groupName, attribute: attribute, operator: `operator`)
    
    whenSelectedComputedThenUpdateFilterState(filterState, groupID: groupID)
    whenFilterStateChangedThenUpdateSelected(groupID: groupID, filterState: filterState)

  }
  
  private func whenSelectedComputedThenUpdateFilterState(_ filterState: FilterState,
                                                         groupID: FilterGroup.ID) {
    
    onSelectedComputed.subscribePast(with: self) { [weak self, weak filterState]  computedSelected in
      
      guard let filterState = filterState else {
        return
      }
      
      if let currentlySelected = self?.selected.flatMap({ self?.items[$0] }) {
        filterState.remove(currentlySelected, fromGroupWithID: groupID)
      }
      
      if let computedSelected = computedSelected.flatMap({ self?.items[$0] }) {
        filterState.add(computedSelected, toGroupWithID: groupID)
      }
      
      filterState.notifyChange()
      
    }
    
  }
  
  private func whenFilterStateChangedThenUpdateSelected(groupID: FilterGroup.ID,
                                                        filterState: FilterState) {
    
    let onChange: (FiltersReadable) -> Void = { [weak self] filterState in
      let filtersInGroup = filterState.getFilters(forGroupWithID: groupID)
      let selectedKey = self?.items.first(where: {
        filtersInGroup.contains(Filter($0.value))
      })?.key
      self?.selected = selectedKey
    }
    
    onChange(filterState.filters)
    
    filterState.onChange.subscribePast(with: self, callback: onChange)
  }
  
}

public extension SelectableSegmentViewModel where Segment: FilterType {
  
  func connectController<C: SelectableSegmentController>(_ controller: C, presenter: FilterPresenter? = .none) where C.SegmentKey == SegmentKey {
    
    func setControllerItems(with items: [SegmentKey: Segment]) {
      let presenter = presenter ?? DefaultFilterPresenter.present
      let itemsToPresent = items
        .map { ($0.key, presenter(Filter($0.value))) }
        .reduce(into: [:]) { $0[$1.0] = $1.1 }
      controller.setItems(items: itemsToPresent)
    }
    
    setControllerItems(with: items)
    controller.setSelected(selected)
    controller.onClick = computeSelected(selecting:)
    onSelectedChanged.subscribePast(with: controller, callback: controller.setSelected)
    onItemsChanged.subscribePast(with: controller, callback: setControllerItems)
    
  }
  
}
