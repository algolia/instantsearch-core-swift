//
//  FilterListViewModel+Numeric.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 17/05/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public extension FilterListViewModel.Numeric {
  
  convenience init(items: [Item] = []) {
    self.init(items: items, selectionMode: .single)
  }
  
}
