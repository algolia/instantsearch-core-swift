//
//  OrFilterGroup.swift
//  AlgoliaSearch OSX
//
//  Created by Vladislav Fitc on 14/01/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

/// Representation of disjunctive group of filters

extension FilterGroup {
  
  public struct Or<T: FilterType>: FilterGroupType {
    
    public var filters: [FilterType] {
      return typedFilters
    }

    public let name: String?
    internal var typedFilters: [T]
    
    public init(filters: [T] = [], name: String? = nil) {
      self.typedFilters = filters
      self.name = name
    }
    
    public static func or<T: FilterType>(_ filters: [T]) -> FilterGroup.Or<T> {
      return FilterGroup.Or<T>(filters: filters)
    }
    
  }
  
}
