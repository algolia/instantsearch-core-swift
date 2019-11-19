//
//  MultiIndexHitsController.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 23/05/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public protocol MultiIndexHitsController: class {
  
  var hitsSource: MultiIndexHitsSource? { get set }
  
  func reload()
  
  func scrollToTop()
  
}

extension MultiIndexHitsInteractor: MultiIndexHitsSource {}
