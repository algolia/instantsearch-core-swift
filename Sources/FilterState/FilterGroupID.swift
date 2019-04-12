//
//  FilterGroupID.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 10/04/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public enum FilterGroupID: Hashable {
  
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
  
}
