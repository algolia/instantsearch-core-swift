//
//  SelectableMapController.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 13/05/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public protocol SelectableMapController: class {
  
  associatedtype Key: Hashable
  
  var onClick: ((Key) -> Void)? { get set }
  
  func setSelected(_ selected: Key?)
  func setItems(items: [Key: String])
  
}
