//
//  RefinementListViewModel.swift
//  InstantSearch
//
//  Created by Guy Daher on 04/03/2019.
//

import Foundation
import InstantSearchClient
import Signals

public class RefinementListViewModel {

  // MARK: - Properties

  public var settings: Settings
  public let onParamChange = Signal<Void>()

  var attribute: Attribute
  var filterBuilder: FilterBuilder
  var group: Group

  var facetResults: [FacetValue]?

  let refinementListBuilder: RefinementListBuilder

  private var orGroup: OrFilterGroup<FilterFacet> {
    return OrFilterGroup(name: group.name)
  }

  private var andGroup: AndFilterGroup {
    return AndFilterGroup(name: group.name)
  }

  // MARK: - Init

  public init(attribute: Attribute, filterBuilder: FilterBuilder, refinementSettings: Settings? = nil, group: Group? = nil) {
    self.attribute = attribute
    self.filterBuilder = filterBuilder
    self.settings = refinementSettings ?? Settings()
    self.group = group ?? Group(attribute.description) // if not specified, the group defaults to the name of the attribute
    refinementListBuilder = RefinementListBuilder()
  }

  // MARK: - Update with new results

  public func update(with facetResults: FacetResults) {
    let rawFacetResults = facetResults.facetHits
    updateFacetResults(with: rawFacetResults)
  }

  public func update<T>(with searchResults: SearchResults<T>) {
    let rawFacetResults: [FacetValue]?
    if filterBuilder.getDisjunctiveFacetsAttributes().contains(attribute) {
      rawFacetResults = searchResults.disjunctiveFacets?[attribute]
    } else {
      rawFacetResults = searchResults.facets?[attribute]
    }

    updateFacetResults(with: rawFacetResults)
  }

  private func updateFacetResults(with rawFacetResults: [FacetValue]?) {
    let refinedFilterFacets: Set<FilterFacet> = filterBuilder.getFilters(for: attribute)

    self.facetResults =
      refinementListBuilder.getRefinementList(on: attribute,
                                              refinedFilterFacets: refinedFilterFacets,
                                              facetValues: rawFacetResults,
                                              sorting: settings.sorting,
                                              areRefinedValuesFirst: settings.areRefinedValuesShownFirst,
                                              isRefinedHandler: isRefined)
  }

  // MARK: - Public API

  public func numberOfRows() -> Int {
    guard let facetResults = facetResults else { return 0 }

    return min(facetResults.count, settings.maximumNumberOfRows)
  }

  public func facetForRow(_ row: Int) -> FacetValue? {
    guard let facetResults = facetResults else { return nil }

    return facetResults[row]
  }

  public func isRefined(_ row: Int) -> Bool {
    guard let facetResults = facetResults else { return false }

    let value = facetResults[row].value
    let filterFacet = FilterFacet(attribute: attribute, stringValue: value)

    return isRefined(filterFacet)
  }

  public func didSelectRow(_ row: Int) {
    guard let facetResults = facetResults else { return }

    let value = facetResults[row].value
    let filterFacet = FilterFacet(attribute: attribute, stringValue: value)

    didSelect(filterFacet)

    onParamChange.fire(())
  }

}

// MARK: - Filtering Business Logic

extension RefinementListViewModel {

  fileprivate func didSelect(_ filterFacet: FilterFacet) {
    switch settings.operator {
    case .or:
      filterBuilder.toggle(filterFacet, in: orGroup)
    case .and(let areMultipleSelectionsAllowed):
      if areMultipleSelectionsAllowed {
        filterBuilder.toggle(filterFacet, in: andGroup)
      } else {
        if filterBuilder.contains(filterFacet, in: orGroup) {
          filterBuilder.remove(filterFacet, from: orGroup)
        } else {
          filterBuilder.removeAll(from: orGroup)
          filterBuilder.add(filterFacet, to: orGroup)
        }
      }
    }
  }

  fileprivate func isRefined(_ filterFacet: FilterFacet) -> Bool {
    switch settings.operator {
    case .or:
      return filterBuilder.contains(filterFacet, in: orGroup)
    case .and(let areMultipleSelectionsAllowed):
      if areMultipleSelectionsAllowed {
        return filterBuilder.contains(filterFacet, in: andGroup)
      } else {
        return filterBuilder.contains(filterFacet, in: orGroup)
      }
    }
  }
}

// MARK: - Helpers

protocol RefinementListBuilding {

}

class RefinementListBuilder: RefinementListBuilding {

  /// Add missing refinements with a count of 0 to all returned facetValues
  /// Example: if in result we have color: [(red, 10), (green, 5)] and that in the refinements
  /// we have "color: red" and "color: yellow", the final output would be [(red, 10), (green, 5), (yellow, 0)]
  func listFrom(facetValues: [FacetValue]?, refinements: Set<FilterFacet>) -> [FacetValue] {
    var values = [FacetValue]()
    if let facetValues = facetValues {
      facetValues.forEach { (facetValue) in
        values.append(facetValue)
      }
    }
    // Make sure there is a value at least for the refined values.
    refinements.forEach { (filterFacet) in
      let refinementValue = filterFacet.value.description
      if facetValues == nil || !facetValues!.contains { $0.value == refinementValue } {
        values.append(FacetValue(value: refinementValue, count: 0, highlighted: .none))
      }
    }

    return values
  }

  typealias IsRefinedHandler = (_ filterFacet: FilterFacet) -> Bool

  func getRefinementList(on attribute: Attribute,
                         refinedFilterFacets: Set<FilterFacet>,
                         facetValues: [FacetValue]?,
                         sorting: RefinementListViewModel.Sorting,
                         areRefinedValuesFirst: Bool = false,
                         isRefinedHandler: IsRefinedHandler? = nil) -> [FacetValue] {

    let facetList = listFrom(facetValues: facetValues, refinements: refinedFilterFacets)

    let sortedFacetList = facetList.sorted { (lhs, rhs) in
      let lhsFilterFacet = FilterFacet(attribute: attribute, stringValue: lhs.value)
      let rhsFilterFacet = FilterFacet(attribute: attribute, stringValue: rhs.value)

      let lhsChecked: Bool = isRefinedHandler?(lhsFilterFacet) ?? false
      let rhsChecked: Bool = isRefinedHandler?(rhsFilterFacet) ?? false

      if areRefinedValuesFirst && lhsChecked != rhsChecked { // Refined wins
        return lhsChecked
      }

      let leftCount = lhs.count
      let rightCount = rhs.count
      let leftValueLowercased = lhs.value.lowercased()
      let rightValueLowercased = rhs.value.lowercased()

      switch sorting {
      case .countDesc:
        if leftCount != rightCount { // Biggest Count wins
          return leftCount > rightCount
        } else {
          return leftValueLowercased < rightValueLowercased // Name ascending wins by default
        }

      case .countAsc:
        if leftCount != rightCount { // Smallest Count wins
          return leftCount < rightCount
        } else {
          return leftValueLowercased < rightValueLowercased // Name ascending wins by default
        }

      case .nameAsc:
        if leftValueLowercased != rightValueLowercased {
          return leftValueLowercased < rightValueLowercased // Name ascending
        } else {
          return leftCount > rightCount // Biggest Count wins by default
        }

      case .nameDsc:
        if leftValueLowercased != rightValueLowercased {
          return leftValueLowercased > rightValueLowercased // Name descending
        } else {
          return leftCount > rightCount // Biggest Count wins by default
        }
      }
    }

    return sortedFacetList
  }
}

extension RefinementListViewModel {
  // TODO: Rename all constants and internal classes to be consistent with names here.
  public struct Settings {
    public var areRefinedValuesShownFirst = Constants.Defaults.refinedFirst
    public var `operator` = Constants.Defaults.refinementOperator
    public var maximumNumberOfRows = Constants.Defaults.limit
    public var sorting: Sorting = .countDesc

    public enum RefinementOperator {
      // when operator is 'and' + one single value can be selected,
      // we want to keep the other values visible, so we have to do a disjunctive facet
      // In the case of multi value that can be selected in conjunctive case,
      // then we avoid doing a disjunctive facet and just do normal conjusctive facet
      // and only the remaining possible facets will appear
      case and(areMultipleSelectionsAllowed: Bool)
      case or
    }
  }

  public enum Sorting {
    case countAsc
    case countDesc
    case nameAsc
    case nameDsc
  }
}


public struct Group: CustomStringConvertible, Hashable {

  public typealias RawValue = String

  var name: String

  public init(_ string: String) {
    self.name = string
  }

  public init(rawValue: String) {
    self.name = rawValue
  }

  public var description: String {
    return name
  }

}
