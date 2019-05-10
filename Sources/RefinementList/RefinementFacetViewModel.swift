//
//  RefinementFacetViewModel.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 19/04/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public typealias SelectableFacetsViewModel = SelectableListViewModel<String, Facet>

public class RefinementFacetsViewModel: SelectableFacetsViewModel {
  public override init(selectionMode: SelectionMode = .multiple) {
    super.init(selectionMode: selectionMode)
  }
}

public class MenuFacetsViewModel: SelectableFacetsViewModel {
  public override init(selectionMode: SelectionMode = .single) {
    super.init(selectionMode: selectionMode)
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
  
  func connectSearcher<R: Codable>(_ searcher: SingleIndexSearcher<R>, with attribute: Attribute, operator: RefinementOperator, groupName: String? = nil) {
    
    searcher.updateQueryFacets(with: attribute)
    
    let groupID = FilterGroup.ID(groupName: groupName, attribute: attribute, operator: `operator`)
    
    whenSelectionsComputedThenUpdateFilterState(attribute, searcher, groupID)
    
    whenFilterStateChangedThenUpdateSelections(of: searcher, groupID: groupID)
    
    whenNewSearchResultsThenUpdateItems(of: searcher, attribute)
  }

  func connectController<T: RefinementFacetsViewController>(_ controller: T, with presenter: SelectableListPresentable? = nil) {

    /// Add missing refinements with a count of 0 to all returned facets
    /// Example: if in result we have color: [(red, 10), (green, 5)] and that in the refinements
    /// we have "color: red" and "color: yellow", the final output would be [(red, 10), (green, 5), (yellow, 0)]
    func merge(_ facets: [Facet], withSelectedValues selections: Set<String>) -> [RefinementFacet] {
      let receivedFacets = facets.map { RefinementFacet($0, selections.contains($0.value)) }
//      let persistentlySelectedFacets = selections
//        .filter { !facets.map { $0.value }.contains($0) }
//        .map { (Facet(value: $0, count: 0, highlighted: .none), true) }
      return receivedFacets// + persistentlySelectedFacets
    }

    func assignSelectableItems(facets: [Facet], selections: Set<String>) {
      let refinementFacets = merge(facets, withSelectedValues: self.selections)

      let sortedFacetValues = presenter?.transform(refinementFacets: refinementFacets) ?? refinementFacets

      controller.setSelectableItems(selectableItems: sortedFacetValues)
      controller.reload()
    }

    controller.onClick = { facet in
      self.computeSelections(selectingItemForKey: facet.value)
    }

    assignSelectableItems(facets: items, selections: selections)

    self.onItemsChanged.subscribe(with: self) { [weak self] (facets) in
      guard let selections = self?.selections else { return }
      assignSelectableItems(facets: facets, selections: selections)
    }

    self.onSelectionsChanged.subscribe(with: self) { [weak self] (selections) in
      guard let facets = self?.items else { return }
      assignSelectableItems(facets: facets, selections: selections)
    }
  }

}

fileprivate extension SelectableFacetsViewModel {

  func whenSelectionsComputedThenUpdateFilterState<R: Codable>(_ attribute: Attribute, _ searcher: SingleIndexSearcher<R>, _ groupID: FilterGroup.ID) {

    onSelectionsComputed.subscribe(with: self) { selections in
      let filters = selections.map { Filter.Facet(attribute: attribute, stringValue: $0) }

      searcher.indexSearchData.filterState.notify { filterState in
        filterState.removeAll(fromGroupWithID: groupID)
        filterState.addAll(filters: filters, toGroupWithID: groupID)
      }
    }
    
  }

  func whenFilterStateChangedThenUpdateSelections<R: Codable>(of searcher: SingleIndexSearcher<R>, groupID: FilterGroup.ID) {
    let onChange: (FiltersReadable) -> Void = { filterState in
      self.selections = Set(filterState.getFilters(forGroupWithID: groupID).map { filter -> String? in
        if
          case .facet(let filterFacet) = filter,
          case .string(let stringValue) = filterFacet.value {
          return stringValue
        } else {
          return nil
        }
        }.compactMap { $0 })
    }

    onChange(searcher.indexSearchData.filterState)

    searcher.indexSearchData.filterState.onChange.subscribe(with: self, callback: onChange)
  }

  func whenNewSearchResultsThenUpdateItems<R: Codable>(of searcher: SingleIndexSearcher<R>, _ attribute: Attribute) {
    searcher.onResultsChanged.subscribe(with: self) { (_, result) in
      if case .success(let searchResults) = result {
        self.items = searchResults.disjunctiveFacets?[attribute] ?? searchResults.facets?[attribute] ?? []
      }
    }
  }
}

extension FilterGroup.ID {
  
  init(groupName: String? = nil, attribute: Attribute, operator: RefinementOperator) {
    
    let name = groupName ?? attribute.name
    
    switch `operator` {
    case .and:
      self = .and(name: name)
    case .or:
      self = .or(name: name)
    }
    
  }
  
}

extension SingleIndexSearcher {
  
  func updateQueryFacets(with attribute: Attribute) {
    let updatedFacets: [String]
    
    if let facets = indexSearchData.query.facets, !facets.contains(attribute.name) {
      updatedFacets = facets + [attribute.name]
    } else {
      updatedFacets = [attribute.name]
    }
    
    indexSearchData.query.facets = updatedFacets
  }
  
}
