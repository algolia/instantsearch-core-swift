//
//  Group.swift
//  InstantSearchCore
//
//  Created by Guy Daher on 18/03/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public struct Group: CustomStringConvertible, Hashable {

  public typealias RawValue = String

  var name: String

  public init(_ string: String) {
    self.name = string
  }

  public init(rawValue: String) {
    self.name = rawValue
  }

  public var description: String {
    return name
  }

}
