//
//  AndGroupOperators.swift
//  AlgoliaSearch OSX
//
//  Created by Vladislav Fitc on 21/01/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

// MARK: Appending

@discardableResult public func +++ <T: FilterType>(left: AndGroupProxy, right: T) -> AndGroupProxy {
  left.add(right)
  return left
}

@discardableResult public func +++ <T: FilterType, S: Sequence>(left: AndGroupProxy, right: S) -> AndGroupProxy where S.Element == T {
  left.addAll(right)
  return left
}

@discardableResult public func +++ (left: AndGroupProxy, right: FacetTuple) -> AndGroupProxy {
  left.add(Filter.Facet(right))
  return left
}

@discardableResult public func +++ <S: Sequence>(left: AndGroupProxy, right: S) -> AndGroupProxy where S.Element == FacetTuple {
  left.addAll(right.map(Filter.Facet.init))
  return left
}

@discardableResult public func +++ (left: AndGroupProxy, right: ComparisonTuple) -> AndGroupProxy {
  left.add(Filter.Numeric(right))
  return left
}

@discardableResult public func +++ <S: Sequence>(left: AndGroupProxy, right: S) -> AndGroupProxy where S.Element == ComparisonTuple {
  left.addAll(right.map(Filter.Numeric.init))
  return left
}

@discardableResult public func +++ (left: AndGroupProxy, right: RangeTuple) -> AndGroupProxy {
  left.add(Filter.Numeric(right))
  return left
}

@discardableResult public func +++ <S: Sequence>(left: AndGroupProxy, right: S) -> AndGroupProxy where S.Element == RangeTuple {
  left.addAll(right.map(Filter.Numeric.init))
  return left
}

@discardableResult public func +++ (left: AndGroupProxy, right: String) -> AndGroupProxy {
  left.add(Filter.Tag(value: right))
  return left
}

// MARK: Removal

@discardableResult public func --- <T: FilterType>(left: AndGroupProxy, right: T) -> AndGroupProxy {
  left.remove(right)
  return left
}

@discardableResult public func --- <T: FilterType, S: Sequence>(left: AndGroupProxy, right: S) -> AndGroupProxy where S.Element == T {
  left.removeAll(right)
  return left
}

@discardableResult public func --- (left: AndGroupProxy, right: FacetTuple) -> AndGroupProxy {
  left.remove(Filter.Facet(right))
  return left
}

@discardableResult public func --- <S: Sequence>(left: AndGroupProxy, right: S) -> AndGroupProxy where S.Element == FacetTuple {
  left.removeAll(right.map(Filter.Facet.init))
  return left
}

@discardableResult public func --- (left: AndGroupProxy, right: ComparisonTuple) -> AndGroupProxy {
  left.remove(Filter.Numeric(right))
  return left
}

@discardableResult public func --- <S: Sequence>(left: AndGroupProxy, right: S) -> AndGroupProxy where S.Element == ComparisonTuple {
  left.removeAll(right.map(Filter.Numeric.init))
  return left
}

@discardableResult public func --- (left: AndGroupProxy, right: RangeTuple) -> AndGroupProxy {
  left.remove(Filter.Numeric(right))
  return left
}

@discardableResult public func --- <S: Sequence>(left: AndGroupProxy, right: S) -> AndGroupProxy where S.Element == RangeTuple {
  left.removeAll(right.map(Filter.Numeric.init))
  return left
}

@discardableResult public func --- (left: AndGroupProxy, right: String) -> AndGroupProxy {
  left.remove(Filter.Tag(value: right))
  return left
}

// MARK: - Toggling

@discardableResult public func <> <T: FilterType>(left: AndGroupProxy, right: T) -> AndGroupProxy {
  left.toggle(right)
  return left
}

@discardableResult public func <> <T: FilterType, S: Sequence>(left: AndGroupProxy, right: S) -> AndGroupProxy where S.Element == T {
  right.forEach { left.toggle($0) }
  return left
}

@discardableResult public func <> (left: AndGroupProxy, right: FacetTuple) -> AndGroupProxy {
  left.toggle(Filter.Facet(right))
  return left
}

@discardableResult public func <> <S: Sequence>(left: AndGroupProxy, right: S) -> AndGroupProxy where S.Element == FacetTuple {
  right.map(Filter.Facet.init).forEach { left.toggle($0) }
  return left
}

@discardableResult public func <> (left: AndGroupProxy, right: ComparisonTuple) -> AndGroupProxy {
  left.toggle(Filter.Numeric(right))
  return left
}

@discardableResult public func <> <S: Sequence>(left: AndGroupProxy, right: S) -> AndGroupProxy where S.Element == ComparisonTuple {
  right.map(Filter.Numeric.init).forEach { left.toggle($0) }
  return left
}

@discardableResult public func <> (left: AndGroupProxy, right: RangeTuple) -> AndGroupProxy {
  left.toggle(Filter.Numeric(right))
  return left
}

@discardableResult public func <> <S: Sequence>(left: AndGroupProxy, right: S) -> AndGroupProxy where S.Element == RangeTuple {
  right.map(Filter.Numeric.init).forEach { left.toggle($0) }
  return left
}

@discardableResult public func <> (left: AndGroupProxy, right: String) -> AndGroupProxy {
  left.toggle(Filter.Tag.init(stringLiteral: right))
  return left
}
