//
//  Searcher+LoadableController.swift
//  InstantSearchCore
//
//  Created by Guy Daher on 23/05/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public extension Searcher {
  func connectController(_ loadableController: LoadableController) {
    isLoading.subscribePast(with: self) { isLoading in
      if isLoading {
        loadableController.startAnimating()
      } else {
        loadableController.stopAnimating()
      }
      }.onQueue(.main)
  }
}
