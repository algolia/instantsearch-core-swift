//
//  SelectableSegmentInteractor+Filter.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 13/05/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public extension SelectableSegmentInteractor where SegmentKey == Int, Segment: FilterType {

  func connectSearcher(_ searcher: SingleIndexSearcher, attribute: Attribute) {
    searcher.indexQueryState.query.updateQueryFacets(with: attribute)
  }
  
}
