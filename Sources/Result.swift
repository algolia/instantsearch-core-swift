//
//  Result.swift
//  InstantSearchCore-iOS
//
//  Created by Guy Daher on 07/03/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public enum Result<T> {

  case success(T), fail(Error)

  public init(value: T) {
    self = .success(value)
  }

  public init(error: Error) {
    self = .fail(error)
  }

  public var value: T? {
    if case let .success(val) = self { return val } else { return nil }
  }

  public var error: Error? {
    if case let .fail(err) = self { return err } else { return nil }
  }

}

public extension Result {

  public init(value: T?, error: Error?) {
    switch (value, error) {
    case (_, .some(let error)):
      self = .fail(error)
    case (.some(let value), _):
      self = .success(value)
    default:
      self = .fail(ResultError.invalidResultInput)
    }
  }
}

public enum ResultError: Error {
  case invalidResultInput
}

// TODO: Move back to correct place
//
//  Constants.swift
//  InstantSearch
//
//  Created by Guy Daher on 15/05/2017.
//
//

import Foundation

public struct Constants {
  public struct Defaults {

    // Multi Index
    public static let index: String = ""
    public static let variant: String = ""

    // Hits
    public static let hitsPerPage: UInt = 20
    public static let infiniteScrolling: Bool = true
    public static let remainingItemsBeforeLoading: UInt = 5
    public static let showItemsOnEmptyQuery: Bool = true

    // Refinement, Numeric Control, Facet Control
    public static let attribute = ""

    // Numeric Control, Facet Control
    public static let inclusive = true

    // Refinement
    public static let operatorRefinement = "or"
    public static let refinementOperator: RefinementListViewModel.Settings.RefinementOperator = .or
    public static let refinedFirst = true
    public static let sortBy = "count:desc"
    public static let limit = 10
    public static let areMultipleSelectionsAllowed = false

    // Numeric Control
    public static let operatorNumericControl = ">="

    // Facet Control
    public static let valueOn = "true"
    public static let valueOff = "false"

    // Stats

    public static let resultTemplate = "{nbHits} results"
    public static let errorText = "Error in fetching results"
    public static let clearText = ""
  }
}
