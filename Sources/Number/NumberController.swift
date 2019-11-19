//
//  NumberView.swift
//  InstantSearchCore
//
//  Created by Guy Daher on 04/06/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public protocol NumberController: ItemController where Item: Numeric {

  func setComputation(computation: Computation<Item>)
  
}
