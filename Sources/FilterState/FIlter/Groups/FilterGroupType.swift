//
//  FilterGroup.swift
//  AlgoliaSearch
//
//  Created by Guy Daher on 14/12/2018.
//  Copyright © 2018 Algolia. All rights reserved.
//

import Foundation

public enum FilterGroup {}

public protocol FilterGroupType {
  
  var filters: [FilterType] { get }
  
}
