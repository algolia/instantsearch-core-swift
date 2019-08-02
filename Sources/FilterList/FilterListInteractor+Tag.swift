//
//  FilterListInteractor+Tag.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 17/05/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public typealias TagFilterListInteractor = FilterListInteractor<Filter.Tag>

public extension TagFilterListInteractor {
  
  convenience init(items: [Item] = []) {
    self.init(items: items, selectionMode: .multiple)
  }
    
}
