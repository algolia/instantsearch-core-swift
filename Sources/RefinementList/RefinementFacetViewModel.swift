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

  func connectController<T: RefinementFacetsViewController>(_ controller: T, with presenter: SelectableListPresentable? = nil) {

    /// Add missing refinements with a count of 0 to all returned facets
    /// Example: if in result we have color: [(red, 10), (green, 5)] and that in the refinements
    /// we have "color: red" and "color: yellow", the final output would be [(red, 10), (green, 5), (yellow, 0)]
    func merge(_ facets: [Facet], withSelectedValues selections: Set<String>) -> [RefinementFacet] {

      return facets.map { RefinementFacet($0, selections.contains($0.value)) }
//      var values = [RefinementFacet]()
//
//      facets.forEach { (facet) in
//          values.append((facet, selections.contains(facet.value)))
//      }
//
//      // Make sure there is a value at least for the refined values.
//      selections.forEach { (refinementValue) in
//        if !facets.contains { $0.value == refinementValue } {
//          values.append((FacetValue(value: refinementValue, count: 0, highlighted: .none), true))
//        }
//      }
//
//      return values
    }

    func assignSelectableItems(facets: [Facet], selections: Set<String>) {
      let refinementFacets = merge(facets, withSelectedValues: self.selections)

      let sortedFacetValues = presenter?.transform(refinementFacets: refinementFacets) ?? refinementFacets

      controller.setSelectableItems(selectableItems: sortedFacetValues)
      controller.reload()
    }

    controller.onClick = { facet in
      self.selectItem(forKey: facet.value)
    }

    assignSelectableItems(facets: items, selections: selections)

    self.onItemsChanged.subscribe(with: self) { [weak self] (facets) in
      guard let strongSelf = self else { return }

      assignSelectableItems(facets: facets, selections: strongSelf.selections)
    }

    self.onSelectionsChanged.subscribe(with: self) { [weak self] (selections) in
      guard let strongSelf = self else { return }

      assignSelectableItems(facets: strongSelf.items, selections: selections)
    }
  }

  func connectSearcher<R: Codable>(_ searcher: SingleIndexSearcher<R>, with attribute: Attribute, operator: RefinementOperator, groupName: String? = nil) {

    updateQueryFacets(of: searcher, with: attribute)
    
    let groupID = self.groupID(with: `operator`, attribute: attribute, groupName: groupName)

    whenSelectionsComputedThenUpdateFilterState(attribute, searcher, groupID)

    whenFilterStateChangedThenUpdateSelections(of: searcher, groupID: groupID)

    whenNewSearchResultsThenUpdateItems(of: searcher, attribute)
  }
  
}

fileprivate extension SelectableFacetsViewModel {

  func updateQueryFacets<R: Codable>(of searcher: SingleIndexSearcher<R>, with attribute: Attribute) {

    guard let facets = searcher.indexSearchData.query.facets else {
      searcher.indexSearchData.query.facets = [attribute.name]

      return
    }

    guard facets.contains(attribute.name) else {
      searcher.indexSearchData.query.facets! += [attribute.name]

      return
    }
  }

  func whenSelectionsComputedThenUpdateFilterState<R: Codable>(_ attribute: Attribute, _ searcher: SingleIndexSearcher<R>, _ groupID: FilterGroup.ID) {

    onSelectionsComputed.subscribe(with: self) { selections in
      let filters = selections.map { Filter.Facet(attribute: attribute, stringValue: $0) }

      searcher.indexSearchData.filterState.notify { filterState in
        filterState.removeAll(fromGroupWithID: groupID)
        filterState.addAll(filters: filters, toGroupWithID: groupID)
      }
      
      print(searcher.indexSearchData.filterState.toFilterGroups().compactMap({ $0 as? FilterGroupType & SQLSyntaxConvertible }).sqlForm)
    }
  }

  func groupID(with operator: RefinementOperator, attribute: Attribute, groupName: String?) -> FilterGroup.ID {
    switch `operator` {
    case .and:
      return .and(name: groupName ?? attribute.name)
    case .or:
      return .or(name: groupName ?? attribute.name)
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
