//
//  FilterGroupID.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 10/04/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

extension FilterGroup {
  
  public enum ID: Hashable {
    
    case or(name: String)
    case and(name: String)
    
    var name: String {
      switch self {
      case .or(name: let name):
        return name
      case .and(name: let name):
        return name
      }
    }
    
    var isConjunctive: Bool {
      if case .and = self {
        return true
      } else {
        return false
      }
    }
    
    var isDisjunctive: Bool {
      return !isConjunctive
    }
    
  }
  
}

extension FilterGroup.ID: CustomStringConvertible {
  
  public var description: String {
    switch self {
    case .and(name: let name):
      return "and<\(name)>"
    case .or(name: let name):
      return "or<\(name)>"
    }
  }
  
}
