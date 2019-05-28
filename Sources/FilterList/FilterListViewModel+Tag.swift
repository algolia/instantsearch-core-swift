//
//  FilterListViewModel+Tag.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 17/05/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public extension SelectableListViewModel where Key == Filter.Tag, Item == Filter.Tag {
  
  convenience init(items: [Item] = []) {
    self.init(items: items, selectionMode: .multiple)
  }
    
}
