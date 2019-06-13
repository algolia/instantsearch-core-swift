//
//  ClearRefinementsController+FilterState.swift
//  InstantSearchCore
//
//  Created by Guy Daher on 24/05/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public extension FilterClearViewModel {

  func connectFilterState(_ filterState: FilterState, filterGroupIDs: [FilterGroup.ID]? = nil, clearMode: ClearMode = .specified) {
    onTriggered.subscribe(with: self) {
      if let filterGroupIDs = filterGroupIDs {
        switch clearMode {
        case .specified:
          filterState.removeAll(fromGroupWithIDs: filterGroupIDs)
        case .except:
          filterState.removeAllExcept(fromGroupWithIDs: filterGroupIDs)
        }

        filterState.notifyChange()
      } else {
        filterState.notify(.removeAll)
      }
    }
  }

}

public enum ClearMode {
  case specified
  case except
}
