//
//  FilterGroupID.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 10/04/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

protocol FilterGroupID: Hashable {
  var name: String { get }
}

public struct AndFilterGroupID: FilterGroupID {
  
  let name: String
  
}

public struct OrFilterGroupID<F: FilterType>: FilterGroupID {
  
  let name: String
  
}

/**
 As FilterGroup protocol inherits Hashable protocol, it cannot be used as a type, but only as a type constraint.
 For the purpose of workaround it, a type-erased wrapper AnyFilterGroup is introduced.
 You can find more information about type erasure here:
 https://www.bignerdranch.com/blog/breaking-down-type-erasures-in-swift/
 */

private class _AnyFilterGroupIDBase: AbstractClass, FilterGroupID {
  
  var name: String {
    callMustOverrideError()
  }
  
  func hash(into hasher: inout Hasher) {
    callMustOverrideError()
  }
  
  init() {
    guard type(of: self) != _AnyFilterGroupIDBase.self else {
      impossibleInitError()
    }
  }
  
  static func == (lhs: _AnyFilterGroupIDBase, rhs: _AnyFilterGroupIDBase) -> Bool {
    callMustOverrideError()
  }
  
}

private final class _AnyFilterGroupIDBox<Concrete: FilterGroupID>: _AnyFilterGroupIDBase {
  
  var concrete: Concrete
  
  init(_ concrete: Concrete) {
    self.concrete = concrete
  }
  
  override var name: String {
    return concrete.name
  }
  
  override func hash(into hasher: inout Hasher) {
    hasher.combine(concrete)
  }
  
  static func == (lhs: _AnyFilterGroupIDBox, rhs: _AnyFilterGroupIDBox) -> Bool {
    return lhs.concrete == rhs.concrete
  }
  
}

final class AnyFilterGroupID: FilterGroupID {
  
  private let box: _AnyFilterGroupIDBase
  private let describingString: String
  
  var isConjunctive: Bool {
    return (extractAs() as AndFilterGroupID?) != nil
  }
  
  var isDisjunctive: Bool {
    return !isConjunctive
  }
  
  init<Concrete: FilterGroupID>(_ concrete: Concrete) {
    box = _AnyFilterGroupIDBox(concrete)
    describingString = String(describing: concrete)
  }
  
  var name: String {
    return box.name
  }
  
  func extractAs<T: FilterGroupID>() -> T? {
    return (box as? _AnyFilterGroupIDBox<T>)?.concrete
  }
  
  func hash(into hasher: inout Hasher) {
    hasher.combine(box)
  }
  
  static func == (lhs: AnyFilterGroupID, rhs: AnyFilterGroupID) -> Bool {
    return lhs.describingString == rhs.describingString && lhs.name == rhs.name
  }
  
}
