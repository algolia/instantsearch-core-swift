//
//  Filter.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 10/04/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public enum Filter: Hashable {
  
  case facet(Facet)
  case numeric(Numeric)
  case tag(Tag)
  
  init<F: FilterType>(_ filter: F) {
    switch filter {
    case let facetFilter as Filter.Facet:
      self = .facet(facetFilter)
    case let numericFilter as Filter.Numeric:
      self = .numeric(numericFilter)
    case let tagFilter as Filter.Tag:
      self = .tag(tagFilter)
    default:
      fatalError("Filter of type \(F.self) is not supported")
    }
  }
  
  var filter: FilterType {
    switch self {
    case .facet(let facetFilter):
      return facetFilter
      
    case .numeric(let numericFilter):
      return numericFilter
      
    case .tag(let tagFilter):
      return tagFilter
    }
  }
  
}

/// Abstract filter protocol
public protocol FilterType {
  
  /// Identifier of field affected by filter
  var attribute: Attribute { get }
  
  /// A Boolean value indicating whether filter is inverted
  var isNegated: Bool { get set }
  
  /// Replaces isNegated property by a new value
  /// parameter value: new value of isNegated
  mutating func not(value: Bool)
  
}

extension FilterType {
  
  public mutating func not(value: Bool = true) {
    isNegated = value
  }
  
}
