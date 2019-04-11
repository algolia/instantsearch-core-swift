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
  left.filterState.add(right, to: left.groupID)
  return left
}

@discardableResult public func +++ <T: FilterType, S: Sequence>(left: AndGroupProxy, right: S) -> AndGroupProxy where S.Element == T {
  left.filterState.addAll(filters: right, to: left.groupID)
  return left
}

@discardableResult public func +++ (left: AndGroupProxy, right: FacetTuple) -> AndGroupProxy {
  left.filterState.add(Filter.Facet(right), to: left.groupID)
  return left
}

@discardableResult public func +++ <S: Sequence>(left: AndGroupProxy, right: S) -> AndGroupProxy where S.Element == FacetTuple {
  left.filterState.addAll(filters: right.map(Filter.Facet.init), to: left.groupID)
  return left
}

@discardableResult public func +++ (left: AndGroupProxy, right: ComparisonTuple) -> AndGroupProxy {
  left.filterState.add(Filter.Numeric(right), to: left.groupID)
  return left
}

@discardableResult public func +++ <S: Sequence>(left: AndGroupProxy, right: S) -> AndGroupProxy where S.Element == ComparisonTuple {
  left.filterState.addAll(filters: right.map(Filter.Numeric.init), to: left.groupID)
  return left
}

@discardableResult public func +++ (left: AndGroupProxy, right: RangeTuple) -> AndGroupProxy {
  left.filterState.add(Filter.Numeric(right), to: left.groupID)
  return left
}

@discardableResult public func +++ <S: Sequence>(left: AndGroupProxy, right: S) -> AndGroupProxy where S.Element == RangeTuple {
  left.filterState.addAll(filters: right.map(Filter.Numeric.init), to: left.groupID)
  return left
}

@discardableResult public func +++ (left: AndGroupProxy, right: String) -> AndGroupProxy {
  left.filterState.add(Filter.Tag(value: right), to: left.groupID)
  return left
}

// MARK: Removal

@discardableResult public func --- <T: FilterType>(left: AndGroupProxy, right: T) -> AndGroupProxy {
  left.filterState.remove(right, from: left.groupID)
  return left
}

@discardableResult public func --- <T: FilterType, S: Sequence>(left: AndGroupProxy, right: S) -> AndGroupProxy where S.Element == T {
  left.filterState.removeAll(right, from: left.groupID)
  return left
}

@discardableResult public func --- (left: AndGroupProxy, right: FacetTuple) -> AndGroupProxy {
  left.filterState.remove(Filter.Facet(right), from: left.groupID)
  return left
}

@discardableResult public func --- <S: Sequence>(left: AndGroupProxy, right: S) -> AndGroupProxy where S.Element == FacetTuple {
  left.filterState.removeAll(right.map(Filter.Facet.init), from: left.groupID)
  return left
}

@discardableResult public func --- (left: AndGroupProxy, right: ComparisonTuple) -> AndGroupProxy {
  left.filterState.remove(Filter.Numeric(right), from: left.groupID)
  return left
}

@discardableResult public func --- <S: Sequence>(left: AndGroupProxy, right: S) -> AndGroupProxy where S.Element == ComparisonTuple {
  left.filterState.removeAll(right.map(Filter.Numeric.init), from: left.groupID)
  return left
}

@discardableResult public func --- (left: AndGroupProxy, right: RangeTuple) -> AndGroupProxy {
  left.filterState.remove(Filter.Numeric(right), from: left.groupID)
  return left
}

@discardableResult public func --- <S: Sequence>(left: AndGroupProxy, right: S) -> AndGroupProxy where S.Element == RangeTuple {
  left.filterState.removeAll(right.map(Filter.Numeric.init), from: left.groupID)
  return left
}

@discardableResult public func --- (left: AndGroupProxy, right: String) -> AndGroupProxy {
  left.filterState.remove(Filter.Tag(value: right), from: left.groupID)
  return left
}

// MARK: - Toggling

@discardableResult public func <> <T: FilterType>(left: AndGroupProxy, right: T) -> AndGroupProxy {
  left.toggle(right)
  return left
}

@discardableResult public func <> <T: FilterType, S: Sequence>(left: AndGroupProxy, right: S) -> AndGroupProxy where S.Element == T {
  right.forEach(left.toggle)
  return left
}

@discardableResult public func <> (left: AndGroupProxy, right: FacetTuple) -> AndGroupProxy {
  left.toggle(Filter.Facet(right))
  return left
}

@discardableResult public func <> <S: Sequence>(left: AndGroupProxy, right: S) -> AndGroupProxy where S.Element == FacetTuple {
  right.map(Filter.Facet.init).forEach(left.toggle)
  return left
}

@discardableResult public func <> (left: AndGroupProxy, right: ComparisonTuple) -> AndGroupProxy {
  left.toggle(Filter.Numeric(right))
  return left
}

@discardableResult public func <> <S: Sequence>(left: AndGroupProxy, right: S) -> AndGroupProxy where S.Element == ComparisonTuple {
  right.map(Filter.Numeric.init).forEach(left.toggle)
  return left
}

@discardableResult public func <> (left: AndGroupProxy, right: RangeTuple) -> AndGroupProxy {
  left.toggle(Filter.Numeric(right))
  return left
}

@discardableResult public func <> <S: Sequence>(left: AndGroupProxy, right: S) -> AndGroupProxy where S.Element == RangeTuple {
  right.map(Filter.Numeric.init).forEach(left.toggle)
  return left
}

@discardableResult public func <> (left: AndGroupProxy, right: String) -> AndGroupProxy {
  left.toggle(Filter.Tag.init(stringLiteral: right))
  return left
}
