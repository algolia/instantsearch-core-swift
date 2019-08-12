//
//  EitherSingleOrList.swift
//  InstantSearchCore-iOS
//
//  Created by Vladislav Fitc on 04/03/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public enum EitherSingleOrList<T> {
  
    case single(T)
    case list([T])
    
    init(_ v: T) {
        self = .single(v)
    }
    
    init<S: Sequence>(_ v: S) where S.Element == T {
        self = .list(Array(v))
    }
    
}

extension EitherSingleOrList: Equatable where T: Equatable {}
extension EitherSingleOrList: Hashable where T: Hashable {}

extension EitherSingleOrList: CustomStringConvertible {
    
    public var description: String {
        switch self {
        case .single(let value):
            return (value as? CustomStringConvertible)?.description ?? "\(value)"
            
        case .list(let list):
            return list.description
        }
    }
    
}

public extension Array {
  init(_ singleOrList: EitherSingleOrList<Element>) {
    switch singleOrList {
    case .single(let element):
      self = [element]
    case .list(let list):
      self = list
    }
  }
}

extension EitherSingleOrList: Codable where T: Codable {
    
    public init(from decoder: Decoder) throws {
        
        if var listContainer = try? decoder.unkeyedContainer() {
            var list = [T]()
            while !listContainer.isAtEnd {
                let element = try listContainer.decode(T.self)
                list.append(element)
            }
            self = .list(list)
        } else if let singleValueContainer = try? decoder.singleValueContainer() {
            let value = try singleValueContainer.decode(T.self)
            self = .single(value)
        } else {
            throw DecodingError.typeMismatch(EitherSingleOrList.self, .init(codingPath: [], debugDescription: "Value doesn't contain a single value nor a list"))
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        switch self {
        case .single(let value):
            var container = encoder.singleValueContainer()
            try container.encode(value)
            
        case .list(let list):
            var container = encoder.unkeyedContainer()
            try container.encode(contentsOf: list)
        }
    }
    
}
