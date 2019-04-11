//
//  SQLSyntax.swift
//  AlgoliaSearch
//
//  Created by Vladislav Fitc on 05/04/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

protocol SQLSyntaxConvertible {
  var sqlForm: String { get }
}

class SQLFilterGroupConverter {
  
  func convert(_ filterGroups: [FilterGroupType]) -> String {
    return ""
  }
  
}

class SQLFilterConverter: FilterConverter {
  
  typealias Output = String
  
  func convert(_ input: Filter) -> String {
    switch input {
    case .facet(let facetFilter):
      return facetFilter.sqlForm
    case .numeric(let numericFilter):
      return numericFilter.sqlForm
    case .tag(let tagFilter):
      return tagFilter.sqlForm
    }
  }
  
}

extension Filter.Numeric: SQLSyntaxConvertible {
  
  public var sqlForm: String {
    let expression: String
    switch value {
    case .comparison(let `operator`, let value):
      expression = """
      "\(attribute)" \(`operator`.rawValue) \(value)
      """
      
    case .range(let range):
      expression = """
      "\(attribute)":\(range.lowerBound) TO \(range.upperBound)
      """
    }
    let prefix = isNegated ? "NOT " : ""
    return prefix + expression
  }
  
}

extension Filter.Facet: SQLSyntaxConvertible {
  
  public var sqlForm: String {
    let scoreExpression = score.flatMap { "<score=\(String($0))>" } ?? ""
    let expression = """
    "\(attribute)":"\(value)\(scoreExpression)"
    """
    let prefix = isNegated ? "NOT " : ""
    return prefix + expression
  }
  
}

extension Filter.Tag: SQLSyntaxConvertible {
  
  public var sqlForm: String {
    let expression = """
    "\(attribute)":"\(value)"
    """
    let prefix = isNegated ? "NOT " : ""
    return prefix + expression
  }
  
}

extension SQLSyntaxConvertible where Self: FilterGroupType {
  
  func groupSQLForm(for filters: [FilterType], withSeparator separator: String) -> String {
    
    let compatibleFilters = filters.compactMap { $0 as? SQLSyntaxConvertible }
    
    if compatibleFilters.isEmpty {
      return ""
    } else if let singleFilter = compatibleFilters.first, compatibleFilters.count == 1 {
      return singleFilter.sqlForm
    } else {
      return "( \(compatibleFilters.map { $0.sqlForm }.joined(separator: separator)) )"
    }

  }
  
}

extension FilterGroup.And: SQLSyntaxConvertible {
  
  public var sqlForm: String {
    return groupSQLForm(for: filters, withSeparator: " AND ")
  }
  
}

extension FilterGroup.Or: SQLSyntaxConvertible {
  
  public var sqlForm: String {
    return groupSQLForm(for: filters, withSeparator: " OR ")
  }
  
}

extension Collection where Element == FilterGroupType & SQLSyntaxConvertible {
  
  var sqlForm: String {
    return map { $0.sqlForm }.joined(separator: " AND ")
  }
  
}
