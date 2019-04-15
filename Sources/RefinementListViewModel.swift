//
//  RefinementListViewModel.swift
//  InstantSearch
//
//  Created by Guy Daher on 04/03/2019.
//

import Foundation
import InstantSearchClient

public class RefinementListViewModel {

  // MARK: - Properties

  public var settings: Settings

  //TODO: Might want to kill this observer.
  public let onExecuteNewSearch = Observer<Void>()
  public let onReloadView = Observer<Void>()

  var attribute: Attribute

  var sortedFacetValues: [FacetValue]?
  var latestRawFacetValues: [FacetValue]?

  let refinementListPresenter: RefinementListPresenterDelegate
  let refinementListInteractor: RefinementListInteractorDelegate

  // MARK: - Init

  public init(attribute: Attribute, filterState: FilterState, refinementSettings: Settings? = nil, groupID: FilterGroupID? = nil) {
    self.attribute = attribute
    
    let settings = refinementSettings ?? Settings()
    
    let finalGroupID: FilterGroupID
    
    if let groupID = groupID {
      finalGroupID = groupID
    } else {
      switch settings.operator {
      case .and(selection: .single), .or:
        finalGroupID = .or(name: attribute.description)
      case .and(selection: .multiple):
        finalGroupID = .and(name: attribute.description)
      }
    }

    self.refinementListInteractor = RefinementListInteractor(attribute: attribute, filterState: filterState, groupID: finalGroupID)

    self.settings = settings
    refinementListPresenter = RefinementListPresenter()

    filterState.onFilterStateChange.subscribe(with: self) { [weak self] (groups) in
      print("onparam change!")
      // TODO: Here need to check if there was some actual change being made between what we had before and now,
      // in order to avoid a double reload
      self?.updateFacetResults(with: self?.latestRawFacetValues)
    }
  }

  public init(attribute: Attribute, refinementListInteractorDelegate: RefinementListInteractorDelegate, refinementListPresenterDelegate: RefinementListPresenterDelegate, refinementSettings: Settings? = nil) {
    self.attribute = attribute
    self.settings = refinementSettings ?? Settings()
    self.refinementListInteractor = refinementListInteractorDelegate
    refinementListPresenter = refinementListPresenterDelegate
  }

  // MARK: - Update with new results

  public func update(with facetResults: FacetResults) {
    let rawFacetResults = facetResults.facetHits
    updateFacetResults(with: rawFacetResults)
  }

  public func update<T>(with searchResults: SearchResults<T>) {
    let rawFacetResults: [FacetValue]? = searchResults.disjunctiveFacets?[attribute] ?? searchResults.facets?[attribute]

    updateFacetResults(with: rawFacetResults)
  }

  private func updateFacetResults(with rawFacetResults: [FacetValue]?) {
    latestRawFacetValues = rawFacetResults
    let selectedValues: [String] = refinementListInteractor.selectedValues(operator: settings.operator)

    self.sortedFacetValues = refinementListPresenter.processFacetValues(selectedValues: selectedValues,
                                                                resultValues: rawFacetResults,
                                                                sortBy: settings.sortBy,
                                                                keepSelectedValuesWithZeroCount: settings.keepSelectedValuesWithZeroCount)
    //print("facetResults \(self.sortedFacetValues)")
    onReloadView.fire(())
  }

  // MARK: - Public API

  public func numberOfFacets() -> Int {
    guard let facetResults = sortedFacetValues else { return 0 }

    switch settings.limit {
    case .none:
      return facetResults.count
    case .count(let count):
      return min(facetResults.count, count)
    }
  }

  public func facet(atIndex index: Int) -> FacetValue? {
    guard let facetResults = sortedFacetValues else { return nil }

    return facetResults[index]
  }

  public func isFacetRefined(atIndex index: Int) -> Bool {
    guard let facetResults = sortedFacetValues else { return false }

    let value = facetResults[index].value

    return refinementListInteractor.isRefined(value: value, operator: settings.operator)
  }

  public func didSelectFacet(atIndex index: Int) {
    guard let facetResults = sortedFacetValues else { return }

    let value = facetResults[index].value

    refinementListInteractor.didSelect(value: value, operator: settings.operator)

    onExecuteNewSearch.fire(())
  }

}

// MARK: - Helpers

extension RefinementListViewModel {
  public struct Settings {
    
    public init() {}
    
    public init(operator: RefinementOperator) {
      self.operator = `operator`
    }
    
    /// Whether to show or not the selected values that have count of 0
    public var keepSelectedValuesWithZeroCount = true

    /// The operator mode of the refinement list.
    /// Possible ones:
    /// - AND + Single Selection
    /// - AND + Multiple Selection
    /// - OR  + Multiple Selection
    public var `operator`: RefinementOperator = .or

    /// Maximum number of items to show in the list
    public var limit: Limit = .count(10)

    /// The Sorting strategy used when displaying the list.
    /// Possible ones:
    /// - Descending Count
    /// - Ascending Count
    /// - Alphabetical
    /// - Reverse Alphabetical
    public var sortBy: [Sorting] = [.isRefined, .count(order: .descending), .alphabetical(order: .ascending)]

    public enum Limit {
      case none
      case count(Int)
    }

    public enum RefinementOperator {
      // when operator is 'and' + one single value can be selected,
      // we want to keep the other values visible, so we have to do a disjunctive facet
      // In the case of multi value that can be selected in conjunctive case,
      // then we avoid doing a disjunctive facet and just do normal conjusctive facet
      // and only the remaining possible facets will appear.
      case and(selection: Selection)
      case or

      public enum Selection {
        case single
        case multiple
      }
    }
  }
  public enum Sorting {
    case count(order: Order)
    case alphabetical(order: Order)
    case isRefined

    public enum Order {
      case ascending
      case descending
    }
  }
}
