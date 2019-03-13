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
  var facetResults: [FacetValue]?
  var query: Query
  var group: Group


  private var orGroup: OrFilterGroup<FilterFacet> {
    return OrFilterGroup(name: group.name)
  }

  private var andGroup: AndFilterGroup {
    return AndFilterGroup(name: group.name)
  }

  public init(attribute: Attribute, query: Query, hitsSettings: Settings? = nil, group: Group? = nil) {
    self.attribute = attribute
    self.query = query
    self.settings = hitsSettings ?? Settings()
    self.group = group ?? Group(attribute.description) // the group defaults to the name of the attribute
  }

  public func update(with facetResults: FacetResults) {
    let rawFacetResults = facetResults.facetHits
    updateFacetResults(with: rawFacetResults)
  }

  public func update<T>(with searchResults: SearchResults<T>) {
    let rawFacetResults: [FacetValue]?
    if query.filterBuilder.getDisjunctiveFacetsAttributes().contains(attribute) {
      rawFacetResults = searchResults.disjunctiveFacets?[attribute]
    } else {
      rawFacetResults = searchResults.facets?[attribute]
    }

    updateFacetResults(with: rawFacetResults)
  }

  private func updateFacetResults(with rawFacetResults: [FacetValue]?) {
    self.facetResults = getRefinementList(query: query,
                                     facetValues: rawFacetResults,
                                     andAttribute: attribute,
                                     transformRefinementList: settings.sorting,
                                     areRefinedValuesFirst: settings.areRefinedValuesShownFirst)
  }

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

    switch settings.operator {
    case .and:
      return query.filterBuilder.contains(filterFacet, in: andGroup)
    case .or:
      return query.filterBuilder.contains(filterFacet, in: orGroup)
    }

  }

  /// This simulated selecting a facet
  /// it will tggle the facet refinement, deselect the row and then execute a search
  public func didSelectRow(_ row: Int) {
    guard let facetResults = facetResults else { return }

    let value = facetResults[row].value
    let filterFacet = FilterFacet(attribute: attribute, stringValue: value)

    if settings.operator == .or { // Normal disjunctive case
      query.filterBuilder.toggle(filterFacet, in: orGroup)
    } else if settings.operator == .and && settings.areMultipleSelectionsAllowed { // Conjunctive case with multiple selection
      query.filterBuilder.toggle(filterFacet, in: andGroup)
    } else {
      // when conjunctive and one single value can be selected,
      // we need to keep the other values visible, so we still have to do a disjunctive facet
      // at the end, we only want to show up to 1 facet filter depending on the click that is made

      if query.filterBuilder.contains(filterFacet, in: orGroup) {
        query.filterBuilder.remove(filterFacet, from: orGroup)
      } else { // select new one only
        query.filterBuilder.removeAll(from: orGroup)
        query.filterBuilder.add(filterFacet, to: orGroup)
      }
    }

    onParamChange.fire(())

  }
}

extension RefinementListViewModel {

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

  func getRefinementList(query: Query,
                         facetValues: [FacetValue]?,
                         andAttribute attribute: Attribute,
                         transformRefinementList: TransformRefinementList,
                         areRefinedValuesFirst: Bool) -> [FacetValue] {

    let refinementsForAttribute: Set<FilterFacet> = query.filterBuilder.getFilters(for: attribute)

    let facetList = listFrom(facetValues: facetValues, refinements: refinementsForAttribute)

    let sortedFacetList = facetList.sorted { (lhs, rhs) in
      let lhsFilterFacet = FilterFacet(attribute: attribute, stringValue: lhs.value)
      let rhsFilterFacet = FilterFacet(attribute: attribute, stringValue: rhs.value)

      let lhsChecked: Bool
      let rhsChecked: Bool
      switch settings.operator {
      case .and:
        lhsChecked = query.filterBuilder.contains(lhsFilterFacet, in: andGroup)
        rhsChecked = query.filterBuilder.contains(rhsFilterFacet, in: andGroup)
      case .or:
        lhsChecked = query.filterBuilder.contains(lhsFilterFacet, in: orGroup)
        rhsChecked = query.filterBuilder.contains(rhsFilterFacet, in: orGroup)
      }

      if areRefinedValuesFirst && lhsChecked != rhsChecked { // Refined wins
        return lhsChecked
      }

      let leftCount = lhs.count
      let rightCount = rhs.count
      let leftValueLowercased = lhs.value.lowercased()
      let rightValueLowercased = rhs.value.lowercased()

      switch transformRefinementList {
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
    public var areMultipleSelectionsAllowed = Constants.Defaults.areMultipleSelectionsAllowed
    public var maximumNumberOfRows = Constants.Defaults.limit
    public var sorting: TransformRefinementList = .countDesc

    public enum RefinementOperator {
      case and
      case or
    }
  }

  public enum TransformRefinementList {
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
