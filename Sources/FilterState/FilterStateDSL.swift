//
//  FilterStateDSL.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 15/04/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public class FilterStateDSL {
  
  public var filterState: FilterState
  
  init() {
    self.filterState = FilterState()
  }
  
  func and(_ groupName: String) -> AndGroupProxy {
    return AndGroupProxy(filterStateDSL: self, groupName: groupName)
  }
  
  func or <F: FilterType>(_ groupName: String, type: F.Type) -> OrGroupProxy<F> {
    return OrGroupProxy(filterStateDSL: self, groupName: groupName)
  }
  
}
