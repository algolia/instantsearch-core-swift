//
//  AndFilterGroup.swift
//  AlgoliaSearch OSX
//
//  Created by Vladislav Fitc on 14/01/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

/// Representation of conjunctive group of filters

extension FilterGroup {
  
  public struct And: FilterGroupType {
    
    public var filters: [FilterType]
    public let name: String?
    
    public var isEmpty: Bool {
      return filters.isEmpty
    }
    
    public init<S: Sequence>(filters: S, name: String? = nil) where S.Element == FilterType {
      self.filters = Array(filters)
      self.name = name
    }
    
    public static func and(_ filters: [FilterType]) -> FilterGroup.And {
      return FilterGroup.And(filters: filters)
    }
    
  }
  
}
