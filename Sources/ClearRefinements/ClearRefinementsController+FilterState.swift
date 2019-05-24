//
//  ClearRefinementsController+FilterState.swift
//  InstantSearchCore
//
//  Created by Guy Daher on 24/05/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public extension ClearRefinementsController {

  func connectTo(_ filterState: FilterState) {
    clearRefinements = { [weak filterState] in filterState?.notify(.removeAll) }
  }

}
