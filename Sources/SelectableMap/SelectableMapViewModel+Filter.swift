//
//  SelectableMapViewModel+Filter.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 13/05/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

typealias RefinementFiltersViewModel<F: FilterType> = SelectableMapViewModel<Int, F>

public extension SelectableMapViewModel where Key == Int, Value: FilterType {
  
  private func whenSelectedComputedThenUpdateFilterState<R: Codable>(groupID: FilterGroup.ID, in searcher: SingleIndexSearcher<R>) {
    onSelectedComputed.subscribe(with: self) { computed in

      let removeSelected: FilterState.Command? = self.selected.flatMap { self.items[$0] }.flatMap { .remove(filter: $0, fromGroupWithID: groupID) }
      
      let addComputed: FilterState.Command? = computed.flatMap { self.items[$0] }.flatMap { .add(filter: $0, toGroupWithID: groupID) }
      
      for command in [removeSelected, addComputed].compactMap({ $0 }) {
        searcher.indexSearchData.filterState.notify(command)
      }
      
    }
  }
  
  private func whenFilterStateChangedThenUpdateSelected<R: Codable>(groupID: FilterGroup.ID, in searcher: SingleIndexSearcher<R>) {
    let onChange: (FiltersReadable) -> Void = { filters in
      let selectedKey = self.items.first(where: { (arg) -> Bool in
        let (_, value) = arg
        guard let selectedFilterInGroup = filters.getFilters(forGroupWithID: groupID).first else {
          return false
        }
        return Filter(value) == selectedFilterInGroup
      })?.key
      self.selected = selectedKey
    }
    onChange(searcher.indexSearchData.filterState.filters)
    searcher.indexSearchData.filterState.onChange.subscribe(with: self, callback: onChange)
  }

  
  func connectSearcher<R: Codable>(_ searcher: SingleIndexSearcher<R>, attribute: Attribute, operator: RefinementOperator, groupName: String? = nil) {

    searcher.indexSearchData.query.updateQueryFacets(with: attribute)
    
    let groupID = FilterGroup.ID(groupName: groupName, attribute: attribute, operator: `operator`)
    
    whenSelectedComputedThenUpdateFilterState(groupID: groupID, in: searcher)
    whenFilterStateChangedThenUpdateSelected(groupID: groupID, in: searcher)
    
  }
  
}

public typealias FilterPresenter = (Filter) -> String

public extension SelectableMapViewModel where Value: FilterType {
  
  internal func defaultFilterPresenter(_ filter: Filter) -> String {
    
    let attributeName = filter.filter.attribute.name
    
    switch filter {
    case .facet(let facetFilter):
      switch facetFilter.value {
      case .bool:
        return filter.filter.attribute.name
        
      case .float(let floatValue):
        return "\(attributeName): \(floatValue)"
        
      case .string(let stringValue):
        return stringValue
      }
      
    case .numeric(let numericFilter):

      switch numericFilter.value {
      case .comparison(let comp):
        return "\(attributeName) \(comp.0) \(comp.1)"
        
      case .range(let range):
        return "\(attributeName): \(range.lowerBound) to \(range.upperBound)"
      }
      
    case .tag(let tagFilter):
      return tagFilter.value
    }
  }
  
  func connectController<C: SelectableMapController>(_ controller: C, presenter: FilterPresenter? = .none) where C.Key == Key {
    
    let presenter = presenter ?? defaultFilterPresenter
    
    let itemsToPresent = items
      .map { ($0.key, presenter(Filter($0.value))) }
      .reduce(into: [:]) { $0[$1.0] = $1.1 }
    
    controller.setItems(items: itemsToPresent)
    controller.setSelected(selected)
    controller.onClick = { selected in
      self.computeSelected(selected: selected)
    }
    onSelectedChanged.subscribe(with: controller) { selected in
      controller.setSelected(selected)
    }
  }
  
}
