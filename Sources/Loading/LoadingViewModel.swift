//
//  LoadingViewModel.swift
//  InstantSearchCore
//
//  Created by Guy Daher on 10/06/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public class LoadingViewModel: ItemViewModel<Bool> {
  public init() {
    super.init(item: false)
  }
}
