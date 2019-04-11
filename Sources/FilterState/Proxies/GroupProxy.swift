//
//  GroupProxy.swift
//  AlgoliaSearch OSX
//
//  Created by Vladislav Fitc on 24/12/2018.
//  Copyright © 2018 Algolia. All rights reserved.
//

import Foundation

/// Group proxy provides a specific type-safe interface for FilterState specialized for a concrete group
internal protocol GroupProxy {
    var filterState: FilterState { get }
    var group: AnyFilterGroup { get }
}
