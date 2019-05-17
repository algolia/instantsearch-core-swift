//
//  FilterListViewModel.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 17/05/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public enum FilterListViewModel {
  
  public typealias Facet = SelectableListViewModel<Filter.Facet, Filter.Facet>
  public typealias Numeric = SelectableListViewModel<Filter.Numeric, Filter.Numeric>
  public typealias Tag = SelectableListViewModel<Filter.Tag, Filter.Tag>
  
}

public extension SelectableListViewModel where Key == Item, Item: FilterType {
  
  func connectFilterState(_ filterState: FilterState, groupName: String = "", operator: RefinementOperator) {
    
    let groupID: FilterGroup.ID
    
    switch `operator` {
    case .or:
      groupID = .or(name: groupName)
      
    case .and:
      groupID = .and(name: groupName)
    }
    
    whenSelectionsComputedThenUpdateFilterState(filterState, groupID)
    whenFilterStateChangedThenUpdateSelections(filterState, groupID: groupID)
  }
  
  func whenSelectionsComputedThenUpdateFilterState(_ filterState: FilterState, _ groupID: FilterGroup.ID) {
    
    onSelectionsComputed.subscribe(with: self) { filters in
      
      let removeCommand: FilterState.Command
      
      switch self.selectionMode {
      case .multiple:
        removeCommand = .removeAll(fromGroupWithID: groupID)
        
      case .single:
        removeCommand = .remove(filters: self.items, fromGroupWithID: groupID)
      }
            
      let addCommand: FilterState.Command = .add(filters: filters, toGroupWithID: groupID)
      
      filterState.notify(removeCommand, addCommand)
      
    }
    
  }
  
  func whenFilterStateChangedThenUpdateSelections(_ filterState: FilterState, groupID: FilterGroup.ID) {
    let onChange: (FiltersReadable) -> Void = { filters in
      self.selections = Set(filters.getFilters(forGroupWithID: groupID).compactMap { $0.filter as? Key })
    }
    
    onChange(filterState.filters)
    
    filterState.onChange.subscribe(with: self, callback: onChange)
  }

}

public extension SelectableListViewModel where Key == Item, Item: FilterType {
  
  func connectController<VC: SelectableListController>(_ controller: VC) where VC.Item == Item {
    
    func assignSelectableItems(items: [Item], selectedTags: Set<Key>) {
      let selectableItems = items.map { ($0, selectedTags.contains($0)) }
      controller.setSelectableItems(selectableItems: selectableItems)
      controller.reload()
    }
    
    controller.onClick = { key in
      self.computeSelections(selectingItemForKey: key)
    }
    
    assignSelectableItems(items: items, selectedTags: selections)
    
    self.onItemsChanged.subscribe(with: self) { [weak self] items in
      guard let selections = self?.selections else { return }
      assignSelectableItems(items: items, selectedTags: selections)
    }
    
    self.onSelectionsChanged.subscribe(with: self) { [weak self] (selections) in
      guard let tags = self?.items else { return }
      assignSelectableItems(items: tags, selectedTags: selections)
    }
    
  }
  
}
