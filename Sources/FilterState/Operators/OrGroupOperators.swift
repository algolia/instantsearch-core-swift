//
//  OrGroupOperators.swift
//  AlgoliaSearch OSX
//
//  Created by Vladislav Fitc on 21/01/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

// MARK: Appending

@discardableResult public func +++ <T: FilterType>(left: OrGroupProxy<T>, right: T) -> OrGroupProxy<T> {
  left.add(right)
  return left
}

@discardableResult public func +++ <T: FilterType, S: Sequence>(left: OrGroupProxy<T>, right: S) -> OrGroupProxy<T> where S.Element == T {
  left.addAll(right)
  return left
}

@discardableResult public func +++ (left: OrGroupProxy<Filter.Facet>, right: FacetTuple) -> OrGroupProxy<Filter.Facet> {
  left.add(Filter.Facet(right))
  return left
}

@discardableResult public func +++ <S: Sequence>(left: OrGroupProxy<Filter.Facet>, right: S) -> OrGroupProxy<Filter.Facet> where S.Element == FacetTuple {
  let filters = right.map(Filter.Facet.init)
  left.addAll(filters)
  return left
}

@discardableResult public func +++ (left: OrGroupProxy<Filter.Numeric>, right: ComparisonTuple) -> OrGroupProxy<Filter.Numeric> {
  left.add(Filter.Numeric(right))
  return left
}

@discardableResult public func +++ <S: Sequence>(left: OrGroupProxy<Filter.Numeric>, right: S) -> OrGroupProxy<Filter.Numeric> where S.Element == ComparisonTuple {
  left.addAll(right.map(Filter.Numeric.init))
  return left
}

@discardableResult public func +++ (left: OrGroupProxy<Filter.Numeric>, right: RangeTuple) -> OrGroupProxy<Filter.Numeric> {
  left.add(Filter.Numeric(right))
  return left
}

@discardableResult public func +++ <S: Sequence>(left: OrGroupProxy<Filter.Numeric>, right: S) -> OrGroupProxy<Filter.Numeric> where S.Element == RangeTuple {
  left.addAll(right.map(Filter.Numeric.init))
  return left
}

@discardableResult public func +++ (left: OrGroupProxy<Filter.Tag>, right: String) -> OrGroupProxy<Filter.Tag> {
  left.add(Filter.Tag(value: right))
  return left
}

// MARK: Removal

@discardableResult public func --- <T: FilterType>(left: OrGroupProxy<T>, right: T) -> OrGroupProxy<T> {
  left.remove(right)
  return left
}

@discardableResult public func --- <T: FilterType, S: Sequence>(left: OrGroupProxy<T>, right: S) -> OrGroupProxy<T> where S.Element == T {
  left.removeAll(right)
  return left
}

@discardableResult public func --- (left: OrGroupProxy<Filter.Facet>, right: FacetTuple) -> OrGroupProxy<Filter.Facet> {
  left.remove(Filter.Facet(right))
  return left
}

@discardableResult public func --- <S: Sequence>(left: OrGroupProxy<Filter.Facet>, right: S) -> OrGroupProxy<Filter.Facet> where S.Element == FacetTuple {
  left.removeAll(right.map(Filter.Facet.init))
  return left
}

@discardableResult public func --- (left: OrGroupProxy<Filter.Numeric>, right: ComparisonTuple) -> OrGroupProxy<Filter.Numeric> {
  left.remove(Filter.Numeric(right))
  return left
}

@discardableResult public func --- <S: Sequence>(left: OrGroupProxy<Filter.Numeric>, right: S) -> OrGroupProxy<Filter.Numeric> where S.Element == ComparisonTuple {
  left.removeAll(right.map(Filter.Numeric.init))
  return left
}

@discardableResult public func --- (left: OrGroupProxy<Filter.Numeric>, right: RangeTuple) -> OrGroupProxy<Filter.Numeric> {
  left.remove(Filter.Numeric(right))
  return left
}

@discardableResult public func --- <S: Sequence>(left: OrGroupProxy<Filter.Numeric>, right: S) -> OrGroupProxy<Filter.Numeric> where S.Element == RangeTuple {
  left.removeAll(right.map(Filter.Numeric.init))
  return left
}

@discardableResult public func --- (left: OrGroupProxy<Filter.Tag>, right: String) -> OrGroupProxy<Filter.Tag> {
  left.remove(Filter.Tag(value: right))
  return left
}

// MARK: - Toggling

@discardableResult public func <> <T: FilterType>(left: OrGroupProxy<T>, right: T) -> OrGroupProxy<T> {
  left.toggle(right)
  return left
}

@discardableResult public func <> <T: FilterType, S: Sequence>(left: OrGroupProxy<T>, right: S) -> OrGroupProxy<T> where S.Element == T {
  right.forEach { left.toggle($0) }
  return left
}

@discardableResult public func <> (left: OrGroupProxy<Filter.Facet>, right: FacetTuple) -> OrGroupProxy<Filter.Facet> {
  left.toggle(Filter.Facet(right))
  return left
}

@discardableResult public func <> <S: Sequence>(left: OrGroupProxy<Filter.Facet>, right: S) -> OrGroupProxy<Filter.Facet> where S.Element == FacetTuple {
  right.map(Filter.Facet.init).forEach { left.toggle($0) }
  return left
}

@discardableResult public func <> (left: OrGroupProxy<Filter.Numeric>, right: ComparisonTuple) -> OrGroupProxy<Filter.Numeric> {
  left.toggle(Filter.Numeric(right))
  return left
}

@discardableResult public func <> <S: Sequence>(left: OrGroupProxy<Filter.Numeric>, right: S) -> OrGroupProxy<Filter.Numeric> where S.Element == ComparisonTuple {
  right.map(Filter.Numeric.init).forEach { left.toggle($0) }
  return left
}

@discardableResult public func <> (left: OrGroupProxy<Filter.Numeric>, right: RangeTuple) -> OrGroupProxy<Filter.Numeric> {
  left.toggle(Filter.Numeric(right))
  return left
}

@discardableResult public func <> <S: Sequence>(left: OrGroupProxy<Filter.Numeric>, right: S) -> OrGroupProxy<Filter.Numeric> where S.Element == RangeTuple {
  right.map(Filter.Numeric.init).forEach { left.toggle($0) }
  return left
}

@discardableResult public func <> (left: OrGroupProxy<Filter.Tag>, right: String) -> OrGroupProxy<Filter.Tag> {
  left.toggle(Filter.Tag.init(stringLiteral: right))
  return left
}
