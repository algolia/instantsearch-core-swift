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
    left.filterState.add(right, to: left.group)
    return left
}

@discardableResult public func +++ <T: FilterType, S: Sequence>(left: OrGroupProxy<T>, right: S) -> OrGroupProxy<T> where S.Element == T {
    left.filterState.addAll(filters: right, to: left.group)
    return left
}

@discardableResult public func +++ (left: OrGroupProxy<Filter.Facet>, right: FacetTuple) -> OrGroupProxy<Filter.Facet> {
    left.filterState.add(Filter.Facet(right), to: left.group)
    return left
}

@discardableResult public func +++ <T: FilterType, S: Sequence>(left: OrGroupProxy<T>, right: S) -> OrGroupProxy<T> where S.Element == FacetTuple {
    left.filterState.addAll(filters: right.map(Filter.Facet.init), to: left.group)
    return left
}

@discardableResult public func +++ (left: OrGroupProxy<Filter.Numeric>, right: ComparisonTuple) -> OrGroupProxy<Filter.Numeric> {
    left.filterState.add(Filter.Numeric(right), to: left.group)
    return left
}

@discardableResult public func +++ <T: FilterType, S: Sequence>(left: OrGroupProxy<T>, right: S) -> OrGroupProxy<T> where S.Element == ComparisonTuple {
    left.filterState.addAll(filters: right.map(Filter.Numeric.init), to: left.group)
    return left
}

@discardableResult public func +++ (left: OrGroupProxy<Filter.Numeric>, right: RangeTuple) -> OrGroupProxy<Filter.Numeric> {
    left.filterState.add(Filter.Numeric(right), to: left.group)
    return left
}

@discardableResult public func +++ <T: FilterType, S: Sequence>(left: OrGroupProxy<T>, right: S) -> OrGroupProxy<T> where S.Element == RangeTuple {
    left.filterState.addAll(filters: right.map(Filter.Numeric.init), to: left.group)
    return left
}

@discardableResult public func +++ (left: OrGroupProxy<Filter.Tag>, right: String) -> OrGroupProxy<Filter.Tag> {
    left.filterState.add(Filter.Tag(value: right), to: left.group)
    return left
}

// MARK: Removal

@discardableResult public func --- <T: FilterType>(left: OrGroupProxy<T>, right: T) -> OrGroupProxy<T> {
    left.filterState.remove(right, from: left.group)
    return left
}

@discardableResult public func --- <T: FilterType, S: Sequence>(left: OrGroupProxy<T>, right: S) -> OrGroupProxy<T> where S.Element == T {
    left.filterState.removeAll(right, from: left.group)
    return left
}

@discardableResult public func --- (left: OrGroupProxy<Filter.Facet>, right: FacetTuple) -> OrGroupProxy<Filter.Facet> {
    left.filterState.remove(Filter.Facet(right), from: left.group)
    return left
}

@discardableResult public func --- <T: FilterType, S: Sequence>(left: OrGroupProxy<T>, right: S) -> OrGroupProxy<T> where S.Element == FacetTuple {
    left.filterState.removeAll(right.map(Filter.Facet.init), from: left.group)
    return left
}

@discardableResult public func --- (left: OrGroupProxy<Filter.Numeric>, right: ComparisonTuple) -> OrGroupProxy<Filter.Numeric> {
    left.filterState.remove(Filter.Numeric(right), from: left.group)
    return left
}

@discardableResult public func --- <T: FilterType, S: Sequence>(left: OrGroupProxy<T>, right: S) -> OrGroupProxy<T> where S.Element == ComparisonTuple {
    left.filterState.removeAll(right.map(Filter.Numeric.init), from: left.group)
    return left
}

@discardableResult public func --- (left: OrGroupProxy<Filter.Numeric>, right: RangeTuple) -> OrGroupProxy<Filter.Numeric> {
    left.filterState.remove(Filter.Numeric(right), from: left.group)
    return left
}

@discardableResult public func --- <T: FilterType, S: Sequence>(left: OrGroupProxy<T>, right: S) -> OrGroupProxy<T> where S.Element == RangeTuple {
    left.filterState.removeAll(right.map(Filter.Numeric.init), from: left.group)
    return left
}

@discardableResult public func --- (left: OrGroupProxy<Filter.Tag>, right: String) -> OrGroupProxy<Filter.Tag> {
    left.filterState.remove(Filter.Tag(value: right), from: left.group)
    return left
}

// MARK: - Toggling

@discardableResult public func <> <T: FilterType>(left: OrGroupProxy<T>, right: T) -> OrGroupProxy<T> {
    left.toggle(right)
    return left
}

@discardableResult public func <> <T: FilterType, S: Sequence>(left: OrGroupProxy<T>, right: S) -> OrGroupProxy<T> where S.Element == T {
    right.forEach(left.toggle)
    return left
}

@discardableResult public func <> (left: OrGroupProxy<Filter.Facet>, right: FacetTuple) -> OrGroupProxy<Filter.Facet> {
    left.toggle(Filter.Facet(right))
    return left
}

@discardableResult public func <> <S: Sequence>(left: OrGroupProxy<Filter.Facet>, right: S) -> OrGroupProxy<Filter.Facet> where S.Element == FacetTuple {
    right.map(Filter.Facet.init).forEach(left.toggle)
    return left
}

@discardableResult public func <> (left: OrGroupProxy<Filter.Numeric>, right: ComparisonTuple) -> OrGroupProxy<Filter.Numeric> {
    left.toggle(Filter.Numeric(right))
    return left
}

@discardableResult public func <> <S: Sequence>(left: OrGroupProxy<Filter.Numeric>, right: S) -> OrGroupProxy<Filter.Numeric> where S.Element == ComparisonTuple {
    right.map(Filter.Numeric.init).forEach(left.toggle)
    return left
}

@discardableResult public func <> (left: OrGroupProxy<Filter.Numeric>, right: RangeTuple) -> OrGroupProxy<Filter.Numeric> {
    left.toggle(Filter.Numeric(right))
    return left
}

@discardableResult public func <> <S: Sequence>(left: OrGroupProxy<Filter.Numeric>, right: S) -> OrGroupProxy<Filter.Numeric> where S.Element == RangeTuple {
    right.map(Filter.Numeric.init).forEach(left.toggle)
    return left
}

@discardableResult public func <> (left: OrGroupProxy<Filter.Tag>, right: String) -> OrGroupProxy<Filter.Tag> {
    left.toggle(Filter.Tag.init(stringLiteral: right))
    return left
}
