//
//  RefinementFacetViewModel.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 19/04/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public typealias SelectableFacetsViewModel = SelectableListViewModel<String, Facet>

public class FacetListViewModel: SelectableListViewModel<String, Facet> {
  public init(selectionMode: SelectionMode = .multiple) {
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

public extension SelectableListViewModel where Key == String, Item == Facet {

  func connectSearcher(_ searcher: SingleIndexSearcher, with attribute: Attribute) {
    whenNewSearchResultsThenUpdateItems(of: searcher, attribute)
    searcher.indexQueryState.query.updateQueryFacets(with: attribute)
  }

  func connectFacetSearcher(_ facetSearcher: FacetSearcher) {
    whenNewFacetSearchResultsThenUpdateItems(of: facetSearcher)
  }
  
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
  
  private func connectFilterState<Accessor: SpecializedGroupAccessor>(_ filterState: FilterState, with attribute: Attribute, via accessor: Accessor) where Accessor.Filter == Filter.Facet {
    whenSelectionsComputedThenUpdateFilterState(filterState, attribute: attribute, via: accessor)
    whenFilterStateChangedThenUpdateSelections(filterState: filterState, via: accessor)
  }

  private func whenSelectionsComputedThenUpdateFilterState<Accessor: SpecializedGroupAccessor>(_ filterState: FilterState,
                                                                                               attribute: Attribute,
                                                                                               via accessor: Accessor) where Accessor.Filter == Filter.Facet {
    onSelectionsComputed.subscribePast(with: self) { [weak filterState] selections in
      let filters = selections.map { Filter.Facet(attribute: attribute, stringValue: $0) }
      accessor.removeAll()
      accessor.addAll(filters)
      filterState?.notifyChange()
    }
    
  }
  
  private func whenFilterStateChangedThenUpdateSelections<Accessor: SpecializedGroupAccessor>(filterState: FilterState, via accessor: Accessor) where Accessor.Filter == Filter.Facet {
    
    func extractString(from filter: Filter.Facet) -> String? {
      if case .string(let stringValue) = filter.value {
        return stringValue
      } else {
        return nil
      }
    }

    filterState.onChange.subscribePast(with: self) { [weak self] _ in
      self?.selections = Set(accessor.filters().compactMap(extractString))
    }
  }

  private func whenNewFacetSearchResultsThenUpdateItems(of facetSearcher: FacetSearcher) {
    
    facetSearcher.onResults.subscribePast(with: self) { searchResults in
      self.items = searchResults.facetHits
    }
    
    facetSearcher.onError.subscribe(with: self) { error in
      if let error = error.1 as? HTTPError, error.statusCode == StatusCode.badRequest.rawValue {
        // For the case of SFFV, very possible that we forgot to add the
        // attribute as searchable in `attributesForFaceting`.
        assertionFailure(error.message ?? "")
      }
    }
    
  }
  
  private func whenNewSearchResultsThenUpdateItems(of searcher: SingleIndexSearcher, _ attribute: Attribute) {
    searcher.onResults.subscribePast(with: self) { searchResults in
      self.items = searchResults.disjunctiveFacets?[attribute] ?? searchResults.facets?[attribute] ?? []
    }
  }
  
}

public extension SelectableListViewModel where Key == String, Item == Facet {
  
  func connectController<C: FacetListController>(_ controller: C, with presenter: SelectableListPresentable? = nil) {
    
    /// Add missing refinements with a count of 0 to all returned facets
    /// Example: if in result we have color: [(red, 10), (green, 5)] and that in the refinements
    /// we have "color: red" and "color: yellow", the final output would be [(red, 10), (green, 5), (yellow, 0)]
    func merge(_ facets: [Facet], withSelectedValues selections: Set<String>) -> [RefinementFacet] {
      return facets.map { RefinementFacet($0, selections.contains($0.value)) }
    }
    
    func setControllerItemsWith(facets: [Facet], selections: Set<String>) {
      let updatedFacets = merge(facets, withSelectedValues: selections)
      let sortedFacetValues = presenter?.transform(refinementFacets: updatedFacets) ?? updatedFacets
      controller.setSelectableItems(selectableItems: sortedFacetValues)
      controller.reload()
    }
    
    setControllerItemsWith(facets: items, selections: selections)
    
    controller.onClick = { [weak self] facet in
      self?.computeSelections(selectingItemForKey: facet.value)
    }
    
    onItemsChanged.subscribePast(with: self) { [weak self] facets in
      guard let selections = self?.selections else { return }
      setControllerItemsWith(facets: facets, selections: selections)
    }
    
    onSelectionsChanged.subscribePast(with: self) { [weak self] selections in
      guard let facets = self?.items else { return }
      setControllerItemsWith(facets: facets, selections: selections)
    }
    
  }

}
