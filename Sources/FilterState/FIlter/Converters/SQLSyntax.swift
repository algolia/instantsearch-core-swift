//
//  SQLSyntax.swift
//  AlgoliaSearch
//
//  Created by Vladislav Fitc on 05/04/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public protocol SQLSyntaxConvertible {
  var sqlForm: String { get }
}

public class SQLSyntaxConverter {
  
  public func convert(_ input: Filter) -> String {
    switch input {
    case .facet(let facetFilter):
      return facetFilter.sqlForm
    case .numeric(let numericFilter):
      return numericFilter.sqlForm
    case .tag(let tagFilter):
      return tagFilter.sqlForm
    }
  }
  
  func groupSQLForm(for filters: [FilterType], withSeparator separator: String) -> String {
    
    let compatibleFilters = filters.compactMap { $0 as? SQLSyntaxConvertible }
    
    if compatibleFilters.isEmpty {
      return ""
    } else {
      return "(\(compatibleFilters.map { $0.sqlForm }.joined(separator: separator)))"
    }
    
  }
  
  public func convert(_ group: FilterGroupType & SQLSyntaxConvertible) -> String {
    return group.sqlForm
  }
  
  public func convert(_ andGroup: FilterGroup.And) -> String {
    return groupSQLForm(for: andGroup.filters, withSeparator: " AND ")
  }
  
  public func convert<T: FilterType>(_ orGroup: FilterGroup.Or<T>) -> String {
    return groupSQLForm(for: orGroup.filters, withSeparator: " OR ")
  }
  
  public func convert<C: Collection>(_ groupList: C) -> String where C.Element: FilterGroupType {
    return groupList.compactMap { (filterGroup) -> String? in
      switch filterGroup {
      case let andGroup as FilterGroup.And:
        return convert(andGroup)
      case let orGroup as FilterGroup.Or<Filter.Facet>:
        return convert(orGroup)
      case let orGroup as FilterGroup.Or<Filter.Tag>:
        return convert(orGroup)
      case let orGroup as FilterGroup.Or<Filter.Numeric>:
        return convert(orGroup)
      default:
        return nil
      }
    }.joined(separator: " AND ")
  }
  
}

public class SQLFilterGroupConverter {
  
  func convert(_ filterGroups: [FilterGroupType]) -> String {
    return ""
  }
  
}

public class SQLFilterConverter: FilterConverter {
  
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
    } else {
      return "(\(compatibleFilters.map { $0.sqlForm }.joined(separator: separator)))"
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
  
  public var sqlForm: String {
    return map { $0.sqlForm }.joined(separator: " AND ")
  }
  
}
