//
//  LoadableController+Searcher.swift
//  InstantSearchCore
//
//  Created by Guy Daher on 23/05/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public extension LoadableController {
  func connectTo(_ searcher: Searcher) {
    searcher.isLoading.subscribePast(with: self) { [weak self] isLoading in
      if isLoading {
        self?.startAnimating()
      } else {
        self?.stopAnimating()
      }
      }.onQueue(.main)
  }
}
