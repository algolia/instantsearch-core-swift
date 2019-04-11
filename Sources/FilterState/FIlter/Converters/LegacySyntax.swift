//
//  LegacySyntax.swift
//  AlgoliaSearch
//
//  Created by Vladislav Fitc on 05/04/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

protocol LegacySyntaxConvertible {
  var legacyForm: [[String]] { get }
}

class LegacyFilterConverter: FilterConverter {
  
  typealias Output = [[String]]
  
  func convert(_ input: Filter) -> Output {
    switch input {
    case .facet(let facetFilter):
      return facetFilter.legacyForm
    case .numeric(let numericFilter):
      return numericFilter.legacyForm
    case .tag(let tagFilter):
      return tagFilter.legacyForm
    }
  }
  
}

extension Filter.Numeric: LegacySyntaxConvertible {
  
  public var legacyForm: [[String]] {
    
    switch value {
    case .comparison(let `operator`, let value):
      let `operator` = isNegated ? `operator`.inversion : `operator`
      let expression = """
      "\(attribute)" \(`operator`.rawValue) \(value)
      """
      return [[expression]]
      
    case .range(let range):
      return [
        Filter.Numeric(attribute: attribute, operator: isNegated ? .lessThan : .greaterThanOrEqual, value: range.lowerBound),
        Filter.Numeric(attribute: attribute, operator: isNegated ? .greaterThan : .lessThanOrEqual, value: range.upperBound)
      ].flatMap { $0.legacyForm }
    }
    
  }
  
}

extension Filter.Facet: LegacySyntaxConvertible {
  
  public var legacyForm: [[String]] {
    let scoreExpression = score.flatMap { "<score=\(String($0))>" } ?? ""
    let valuePrefix = isNegated ? "-" : ""
    let expression = """
    "\(attribute)":\(valuePrefix)"\(value)\(scoreExpression)"
    """
    return [[expression]]
  }
  
}

extension Filter.Tag: LegacySyntaxConvertible {
  
  public var legacyForm: [[String]] {
    let valuePrefix = isNegated ? "-" : ""
    let expression = """
    "\(attribute)":\(valuePrefix)"\(value)"
    """
    return [[expression]]
  }
  
}

extension FilterGroup.And: LegacySyntaxConvertible {
  
  var legacyForm: [[String]] {
    return filters.compactMap { $0 as? LegacySyntaxConvertible }.flatMap { $0.legacyForm }
  }
  
}

extension FilterGroup.Or: LegacySyntaxConvertible {
  
  var legacyForm: [[String]] {
    return filters.compactMap { $0 as? LegacySyntaxConvertible }.flatMap { $0.legacyForm }
  }
  
}

extension Collection where Element: FilterGroupType {
  
  var legacyForm: [[String]] {
    var output: [[String]] = []
    for group in self {
      switch group {
      case let andGroup as FilterGroup.And:
        output.append(contentsOf: andGroup.legacyForm)
      case let orGroup as FilterGroup.Or<Filter.Facet>:
        output.append(contentsOf: orGroup.legacyForm)
      case let orGroup as FilterGroup.Or<Filter.Tag>:
        output.append(contentsOf: orGroup.legacyForm)
      case let orGroup as FilterGroup.Or<Filter.Numeric>:
        output.append(contentsOf: orGroup.legacyForm)
      default:
        break
      }
    }
    return output
  }
  
}

extension Collection where Element: FilterGroupType & LegacySyntaxConvertible {
  
  var legacyForm: [[String]] {
    return flatMap { $0.legacyForm }
  }
  
}
