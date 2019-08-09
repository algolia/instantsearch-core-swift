//
//  CallbackTester.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 20/05/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

class CallbackTester<Item> {
  
  let callback: (Item) -> Void
  
  init(callback: @escaping (Item) -> Void) {
    self.callback = callback
  }
  
}
