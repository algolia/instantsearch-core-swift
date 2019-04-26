//
//  RefinementFacetViewModel.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 19/04/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public typealias SelectableFacetsViewModel = SelectableListViewModel<String, FacetValue>

public class RefinementFacetsViewModel: SelectableFacetsViewModel {
  public init() {
    super.init(selectionMode: .multiple)
  }
}

public class MenuFacetsViewModel: SelectableFacetsViewModel {
  public init() {
    super.init(selectionMode: .single)
  }
}

public enum FacetSortCriterion {
  case count(order: Order)
  case alphabetical(order: Order)
  case isRefined

  public enum Order {
    case ascending
    case descending
  }
}

public enum RefinementOperator {
  // when operator is 'and' + one single value can be selected,
  // we want to keep the other values visible, so we have to do a disjunctive facet
  // In the case of multi value that can be selected in conjunctive case,
  // then we avoid doing a disjunctive facet and just do normal conjusctive facet
  // and only the remaining possible facets will appear.
  case and
  case or

}

public extension SelectableFacetsViewModel {

  func connect<T: RefinementFacetsView>(view: T, refinementPresenter: SelectableListPresentable = RefinementFacetsPresenter(), closure: @escaping ((T, [RefinementFacet]) -> Void)) {
    self.onItemsChanged.subscribe(with: self) { [weak self] (facetValues) in
      let sortedFacetValues =
        refinementPresenter.processFacetValues(
          selectedValues: Array(self?.selections ?? Set()),
          resultValues: facetValues)

      closure(view, sortedFacetValues)

    }
  }

  // TODO: Try to refactor to smaller connect methods for more readability and clarity 
  func connect<R: Codable>(attribute: Attribute, searcher: SingleIndexSearcher<R>, operator: RefinementOperator, groupName: String? = nil) {
    
    let groupID: FilterGroup.ID
    
    switch `operator` {
    case .and:
      groupID = .and(name: groupName ?? attribute.name)
    case .or:
      groupID = .or(name: groupName ?? attribute.name)
    }
    
    let filterStateListener: (FiltersReadable) -> Void = { filterState in
      self.selections = Set(filterState.getFilters(forGroupWithID: groupID).map { filter -> String? in
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
    
    searcher.indexSearchData.filterState.onChange.subscribe(with: self, callback: filterStateListener)
    
    searcher.onSearchResults.subscribe(with: self) { (_, result) in
      if case .success(let searchResults) = result {
        self.items = searchResults.disjunctiveFacets?[attribute] ?? searchResults.facets?[attribute] ?? []
      }
    }
    
    onSelectionsComputed.subscribe(with: self) { selections in
      let filters = selections.map { Filter.Facet(attribute: attribute, stringValue: $0) }
      searcher.indexSearchData.filterState.removeAll(fromGroupWithID: groupID)
      searcher.indexSearchData.filterState.addAll(filters: filters, toGroupWithID: groupID)
      print(searcher.indexSearchData.filterState.toFilterGroups().compactMap({ $0 as? FilterGroupType & SQLSyntaxConvertible }).sqlForm)
    }
    
  }
  
}
