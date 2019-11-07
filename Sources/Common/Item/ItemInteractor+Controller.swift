//
//  ItemInteractor+Controller.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 02/08/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public extension ItemInteractor {
  
  func connectController<Controller: ItemController, Output>(_ controller: Controller,
                                                             presenter: @escaping Presenter<Item, Output>) where Controller.Item == Output {
    onItemChanged.subscribePast(with: controller) { controller, item in
      controller.setItem(presenter(item))
    }.onQueue(.main)
  }
  
}
