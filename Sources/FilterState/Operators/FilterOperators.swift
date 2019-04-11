//
//  FilterOperators.swift
//  AlgoliaSearch OSX
//
//  Created by Vladislav Fitc on 21/12/2018.
//  Copyright © 2018 Algolia. All rights reserved.
//

import Foundation

public typealias FacetTuple = (Attribute, Filter.Facet.ValueType)
public typealias ComparisonTuple = (Attribute, Filter.Numeric.NumericOperator, Float)
public typealias RangeTuple = (Attribute, ClosedRange<Float>)

precedencegroup FilterGroupPrecedence {
    associativity: left
    higherThan: AssignmentPrecedence
}

infix operator +++: FilterGroupPrecedence
infix operator ---: FilterGroupPrecedence
infix operator <>: FilterGroupPrecedence

@discardableResult public prefix func ! <T: FilterType>(f: T) -> T {
    var mutableFilterCopy = f
    mutableFilterCopy.not(value: !f.isNegated)
    return mutableFilterCopy
}
