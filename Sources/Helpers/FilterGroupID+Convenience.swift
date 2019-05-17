//
//  FilterGroupID+Convenience.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 17/05/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

extension FilterGroup.ID {
  
  init(groupName: String? = nil, attribute: Attribute, operator: RefinementOperator) {
    
    let name = groupName ?? attribute.name
    
    switch `operator` {
    case .and:
      self = .and(name: name)
    case .or:
      self = .or(name: name)
    }
    
  }
  
}
