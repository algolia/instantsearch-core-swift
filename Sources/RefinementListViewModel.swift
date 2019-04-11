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
  public let onParamChange = Observer<Void>()

  var attribute: Attribute

  var facetResults: [FacetValue]?

  let refinementListBuilder: RefinementListBuilderProtocol
  let refinementListFilterDelegate: RefinementListFilterDelegate

  // MARK: - Init

  public init(attribute: Attribute, filterBuilder: FilterBuilder, refinementSettings: Settings? = nil, group: Group? = nil) {
    self.attribute = attribute
    let group = group ?? Group(attribute.description) // if not specified, the group defaults to the name of the attribute

    self.refinementListFilterDelegate = RefinementListFilterHandler(attribute: attribute, filterBuilder: filterBuilder, group: group)

    self.settings = refinementSettings ?? Settings()
    refinementListBuilder = RefinementListBuilder()
  }

  public init(attribute: Attribute, refinementListFilterDelegate: RefinementListFilterDelegate, refinementSettings: Settings? = nil) {
    self.attribute = attribute
    self.settings = refinementSettings ?? Settings()
    self.refinementListFilterDelegate = refinementListFilterDelegate
    refinementListBuilder = RefinementListBuilder()
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
    let selectedValues: [String] = refinementListFilterDelegate.selectedValues()

    self.facetResults = refinementListBuilder.getRefinementList(selectedValues: selectedValues,
                                                                resultValues: rawFacetResults,
                                                                sortBy: settings.sortBy,
                                                                keepSelectedValuesWithZeroCount: settings.keepSelectedValuesWithZeroCount)
  }

  // MARK: - Public API

  public func numberOfFacets() -> Int {
    guard let facetResults = facetResults else { return 0 }

    switch settings.limit {
    case .none:
      return facetResults.count
    case .count(let count):
      return min(facetResults.count, count)
    }
  }

  public func facet(atIndex index: Int) -> FacetValue? {
    guard let facetResults = facetResults else { return nil }

    return facetResults[index]
  }

  public func isFacetRefined(atIndex index: Int) -> Bool {
    guard let facetResults = facetResults else { return false }

    let value = facetResults[index].value

    return refinementListFilterDelegate.isRefined(value: value, operator: settings.operator)
  }

  public func didSelectFacet(atIndex index: Int) {
    guard let facetResults = facetResults else { return }

    let value = facetResults[index].value

    refinementListFilterDelegate.didSelect(value: value, operator: settings.operator)

    onParamChange.fire(())
  }

}

// MARK: - Helpers

extension RefinementListViewModel {
  public struct Settings {
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
