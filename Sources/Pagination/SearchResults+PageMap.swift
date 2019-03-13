//
//  SearchResults+PageMap.swift
//  InstantSearchCore-iOS
//
//  Created by Vladislav Fitc on 13/03/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

extension SearchResults: PageMapConvertible {
  
  typealias PageItem = T
  
  var totalItemsCount: Int {
    return totalHitsCount
  }
  
  var pageItems: [T] {
    return hits
  }
  
}
