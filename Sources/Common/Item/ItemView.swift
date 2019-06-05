//
//  ItemView.swift
//  InstantSearchCore
//
//  Created by Guy Daher on 04/06/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public protocol ItemView {

  associatedtype Item

  func setItem(item: Item)
}
