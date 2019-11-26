//
//  HitsInteractor+Controller.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 25/07/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public extension HitsInteractor {
  
  struct ControllerConnection<Controller: HitsController>: Connection where Controller.DataSource == HitsInteractor<Record> {
    
    public let interactor: HitsInteractor
    public let controller: Controller
    
    public func connect() {
      controller.hitsSource = interactor
      
      interactor.onRequestChanged.subscribe(with: controller) { controller, _ in
        controller.scrollToTop()
      }.onQueue(.main)
      
      interactor.onResultsUpdated.subscribePast(with: controller) { controller, _ in
        controller.reload()
      }.onQueue(.main)
    }
    
    public func disconnect() {
      if controller.hitsSource === interactor {
        controller.hitsSource = nil
      }
      interactor.onRequestChanged.cancelSubscription(for: controller)
      interactor.onResultsUpdated.cancelSubscription(for: controller)
    }
    
  }
  
}

public extension HitsInteractor {
  
  @discardableResult func connectController<Controller: HitsController>(_ controller: Controller) -> ControllerConnection<Controller> where Controller.DataSource == HitsInteractor<Record> {
    let connection = ControllerConnection(interactor: self, controller: controller)
    connection.connect()
    return connection
  }
  
}
