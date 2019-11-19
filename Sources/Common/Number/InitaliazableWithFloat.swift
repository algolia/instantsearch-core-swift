//
//  InitaliazableWithFloat.swift
//  InstantSearchCore
//
//  Created by Guy Daher on 14/06/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public protocol InitaliazableWithFloat {

  init(_ float: Float)
  func toFloat() -> Float
}

extension Int: InitaliazableWithFloat {
  public func toFloat() -> Float {
    return Float(self)
  }
}

extension Double: InitaliazableWithFloat {
  public func toFloat() -> Float {
    return Float(self)
  }
}

extension Float: InitaliazableWithFloat {
  public func toFloat() -> Float {
    return Float(self)
  }
}
