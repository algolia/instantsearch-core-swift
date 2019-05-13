//
//  SelectableMapViewModel+Filter.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 13/05/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

typealias RefinementFiltersViewModel<F: FilterType> = SelectableMapViewModel<Int, F>

extension SelectableMapViewModel where Key == Int, Value: FilterType {
  
  func connectSearcher<R: Codable>(_ searcher: SingleIndexSearcher<R>, attribute: Attribute, operator: RefinementOperator, groupName: String? = nil) {
    
    func whenSelectedComputedThenUpdateFilterState(groupID: FilterGroup.ID) {
      onSelectedComputed.subscribe(with: self) { computed in
        let selectedToRemove = self.selected.flatMap { self.items[$0] }!
        let computedToSelect = computed.flatMap { self.items[$0] }!
        searcher.indexSearchData.filterState.notify(
          .remove(filter: selectedToRemove, fromGroupWithID: groupID),
          .add(filter: computedToSelect, toGroupWithID: groupID)
        )
      }
    }
    
    func whenFilterStateChangedThenUpdateSelected(groupID: FilterGroup.ID) {
      
      let onChange: (FiltersReadable) -> Void = { filters in
        self.selected = self.items.first(where: { (arg) -> Bool in
          let (_, value) = arg
          return Filter(value) == filters.getFilters(forGroupWithID: groupID).first
        })?.key
      }
      onChange(searcher.indexSearchData.filterState.filters)
      searcher.indexSearchData.filterState.onChange.subscribe(with: self, callback: onChange)
    }
    
    let groupID = FilterGroup.ID(groupName: groupName, attribute: attribute, operator: `operator`)
    
    searcher.updateQueryFacets(with: attribute)
    
    whenSelectedComputedThenUpdateFilterState(groupID: groupID)
    whenFilterStateChangedThenUpdateSelected(groupID: groupID)
    
  }
  
}

extension SelectableMapViewModel {
  
  func connectController<C: SelectableMapController>(_ controller: C) where C.Key == Key, C.Value == Value {
    controller.setItems(items: items)
    controller.setSelected(selected)
    controller.onClick = { selected in
      self.computeSelected(selected: selected)
    }
    onSelectedChanged.subscribe(with: controller) { selected in
      self.selected = selected
    }
  }
  
}
