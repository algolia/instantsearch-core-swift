//
//  FacetName.swift
//  InstantSearchCore-iOS
//
//  Created by Vladislav Fitc on 05/03/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

/// Strongly typed facet name wrapper
public struct FacetName: RawRepresentable, ExpressibleByStringLiteral, Codable, Hashable {
    
    public typealias StringLiteralType = String
    public typealias RawValue = String
    
    public var rawValue: String
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
    
    public init(stringLiteral value: String) {
        self.rawValue = value
    }
    
}
