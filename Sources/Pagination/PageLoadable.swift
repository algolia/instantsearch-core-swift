//
//  PageLoadable.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 04/06/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public protocol PageLoadable: class {
  
  func loadPage(atIndex pageIndex: Int)
  
}

extension SingleIndexSearcher: PageLoadable {
  
  public func loadPage(atIndex pageIndex: Int) {
    indexQueryState.query.page = UInt(pageIndex)
    search()
  }
  
}

extension FacetSearcher: PageLoadable {
  
  public func loadPage(atIndex pageIndex: Int) {
    indexQueryState.query.page = UInt(pageIndex)
    search()
  }
  
}
