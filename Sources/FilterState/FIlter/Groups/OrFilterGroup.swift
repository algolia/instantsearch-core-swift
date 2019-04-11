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
    
    private var typedFilters: [T]
    
    public var isEmpty: Bool {
      return filters.isEmpty
    }
    
    public init(filters: [T] = []) {
      self.typedFilters = filters
    }
    
    public static func or<T: FilterType>(_ filters: [T]) -> FilterGroup.Or<T> {
      return FilterGroup.Or<T>(filters: filters)
    }
    
  }
  
}

public extension FilterGroup.Or {
  
  struct ID: FilterGroupID {
    
    public let name: String
    
  }
  
}
