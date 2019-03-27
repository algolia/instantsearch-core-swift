//
//  Signals+Observable.swift
//  InstantSearchCore
//
//  Created by Guy Daher on 21/03/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation
import Signals

extension Signal: Observable {
  public typealias Obs = SignalSubscription
}

extension SignalSubscription: Observation {
  public typealias ParameterType = T
}
