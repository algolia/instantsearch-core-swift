//
//  LoadingInteractor+Searcher.swift
//  InstantSearchCore
//
//  Created by Guy Daher on 10/06/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public extension LoadingInteractor {

  func connectSearcher<S: Searcher>(_ searcher: S) {
    searcher.isLoading.subscribePast(with: self) { interactor, isLoading in
      interactor.item = isLoading
    }
  }
}
