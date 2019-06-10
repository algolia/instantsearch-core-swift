//
//  Result.swift
//  InstantSearchCore-iOS
//
//  Created by Guy Daher on 07/03/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public extension Result where Failure == Error {

  init(value: Success?, error: Failure?) {
    switch (value, error) {
    case (_, .some(let error)):
      self = .failure(error)
    case (.some(let value), _):
      self = .success(value)
    default:
      self = .failure(ResultError.invalidResultInput)
    }
  }
}

public enum ResultError: Error {
  case invalidResultInput
}

public struct Constants {
  public struct Defaults {

    // Hits
    public static let hitsPerPage: UInt = 20
    public static let infiniteScrolling: InfiniteScrolling = .on(withOffset: 5)
    public static let showItemsOnEmptyQuery: Bool = true

    // Refinement
    public static let operatorRefinement = "or"
    public static let refinementOperator: RefinementOperator = .or
    public static let refinedFirst = true
    
    public static let limit = 10
    public static let areMultipleSelectionsAllowed = false
  }
}