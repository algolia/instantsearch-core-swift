//
//  LoadingInteractor+Controller.swift
//  InstantSearchCore
//
//  Created by Guy Daher on 12/06/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public extension LoadingInteractor {
  
  func connectController<Controller: LoadingController>(_ controller: Controller) {
    connectController(controller, dispatchOnMainThread: true) { $0 }
  }
  
}
