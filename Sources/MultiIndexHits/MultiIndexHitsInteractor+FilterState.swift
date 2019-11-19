//
//  MultiIndexHitsInteractor+FilterState.swift
//  InstantSearchCore
//
//  Created by Guy Daher on 18/09/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public extension MultiIndexHitsInteractor {
  func connectFilterState(_ filterState: FilterState) {
    filterState.onChange.subscribePast(with: self) { interactor, _ in
      interactor.notifyQueryChanged()
    }
  }
}
