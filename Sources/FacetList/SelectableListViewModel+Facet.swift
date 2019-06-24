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
    searcher.indexSearchData.query.updateQueryFacets(with: attribute)
  }

  func connectFacetSearcher(_ facetSearcher: FacetSearcher) {
    whenNewFacetSearchResultsThenUpdateItems(of: facetSearcher)
  }
  
  func connectFilterState(_ filterState: FilterState,
                          with attribute: Attribute,
                          operator: RefinementOperator,
                          groupName: String? = nil) {

    let groupID = FilterGroup.ID(groupName: groupName, attribute: attribute, operator: `operator`)

    whenSelectionsComputedThenUpdateFilterState(filterState, attribute: attribute, groupID: groupID)
    whenFilterStateChangedThenUpdateSelections(filterState: filterState, groupID: groupID)
  }

  private func whenSelectionsComputedThenUpdateFilterState(_ filterState: FilterState,
                                                           attribute: Attribute,
                                                           groupID: FilterGroup.ID) {
    
    onSelectionsComputed.subscribePast(with: self) { selections in
      let filters = selections.map { Filter.Facet(attribute: attribute, stringValue: $0) }
      
      filterState.notify(
        .removeAll(fromGroupWithID: groupID),
        .add(filters: filters, toGroupWithID: groupID)
      )
      print("Selections computed -> update filter state \(self.selections)")
    }
    
  }
  
  private func whenFilterStateChangedThenUpdateSelections(filterState: FilterState, groupID: FilterGroup.ID) {
    
    let onChange: (FiltersReadable) -> Void = { filterState in
      
      func filterToFacetString(_ filter: Filter) -> String? {
        if
          case .facet(let filterFacet) = filter,
          case .string(let stringValue) = filterFacet.value {
          return stringValue
        } else {
          return nil
        }
      }
      
      self.selections = Set(filterState.getFilters(forGroupWithID: groupID).compactMap(filterToFacetString))
      print("FilterState changed -> update selections: \(self.selections)")
    }
    
    onChange(filterState)
    
    filterState.onChange.subscribePast(with: self, callback: onChange)
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
