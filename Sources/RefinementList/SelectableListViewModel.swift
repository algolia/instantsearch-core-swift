//
//  SelectableListViewModel.swift
//  InstantSearchCore
//
//  Created by Guy Daher on 18/04/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

typealias RefinementFacetsViewModel = SelectableListViewModel<String, FacetValue>

extension RefinementFacetsViewModel {
  
  func connect<R: Codable>(attribute: Attribute, searcher: SingleIndexSearcher<R>, operator: RefinementOperator, groupName: String? = nil) {
    
    let groupID: FilterGroupID
    
    switch `operator` {
    case .and:
      groupID = .and(name: groupName ?? attribute.name)
    case .or:
      groupID = .or(name: groupName ?? attribute.name)
    }
    
    //TODO: FilterState listeners
    /*
    let filt
    */
    
    let filterStateListener: (FilterState) -> Void = { filterState in
      self.selections = Set(filterState.getFilters(for: groupID).map { filter -> String? in
        if
          case .facet(let filterFacet) = filter,
          case .string(let stringValue) = filterFacet.value {
          return stringValue
        } else {
          return nil
        }
      }.compactMap { $0 })
      searcher.search()
    }
    
    filterStateListener(searcher.indexSearchData.filterState)
    // add listener to searcher.indexSearchData.filterState
    
    searcher.onSearchResults.subscribe(with: self) { (_, result) in
      switch result {
      case .failure(let error):
        print(error)
        
      case .success(let searchResults):
        self.values = searchResults.facets?[attribute] ?? []
      }
    }
    
    selectedListeners.subscribe(with: self) { selections in
      let filters = selections.map { Filter.Facet(attribute: attribute, stringValue: $0) }
      searcher.indexSearchData.filterState.removeAll(from: groupID)
      searcher.indexSearchData.filterState.addAll(filters: filters, to: groupID)
    }
    
  }
  
}

extension RefinementFacetsViewModel {
  
  func connect(presenter: RefinementFacetsPresenter) {
    refinementsListeners.subscribe(with: self) { facetValues in
      presenter.values = facetValues.map { ($0, self.selections.contains($0.value)) }
    }
    selectionsListeners.subscribe(with: self) { selections in
      presenter.values = self.values.map { ($0, selections.contains($0.value)) }
    }
  }
  
}

class SelectableListViewModel<K: Hashable, V: Equatable> {

  public var selectionMode: SelectionMode

  public init(selectionMode: SelectionMode) {
    self.selectionMode = selectionMode
  }

  public var refinementsListeners = Observer<[V]>()
  public var selectionsListeners = Observer<Set<K>>()
  public var selectedListeners = Observer<Set<K>>()

  public var values: [V] = [] {
    didSet {
      if oldValue != values {
        refinementsListeners.fire(values)
      }
    }
  }

  public var selections = Set<K>() {
    didSet {
      if oldValue != selections {
        selectionsListeners.fire(selections)
      }
    }
  }

  public func select(key: K) {
    let selections: Set<K>
    switch selectionMode {
    case .single:
      selections = self.selections.contains(key) ? [] : [key]
    case .multiple:
      selections = self.selections.contains(key) ? self.selections.subtracting([key]) : self.selections.union([key])
    }

    selectionsListeners.fire(selections)
  }

}

public enum SelectionMode {
  case single
  case multiple
}
