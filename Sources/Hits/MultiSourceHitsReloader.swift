//
//  MultiSearchConnection.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 10/12/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

private class ResultsUpdatableNotificationWrapper: Connection {
  
  public var onResultsUpdated: Observer<Void>
  
  private var subscribe: () -> Void
  private var unsubscribe: () -> Void
  
  public init<Updatable: ResultUpdatable>(updatable: Updatable) {
    onResultsUpdated = .init()
    subscribe = {}
    unsubscribe = {}
    subscribe = { [weak self] in
      guard let wrapper = self else { return }
      updatable.onResultsUpdated.subscribe(with: wrapper) { (wrapper, _) in
        wrapper.onResultsUpdated.fire(())
      }
    }
    unsubscribe = { [weak self] in
      guard let wrapper = self else { return }
      updatable.onResultsUpdated.cancelSubscription(for: wrapper)
    }
    connect()
  }
  
  public func connect() {
    subscribe()
  }
  
  public func disconnect() {
    unsubscribe()
  }
  
}

public class MultiSourceHitsReloader<Controller: HitsController> {
  
  public let controller: Controller
  
  private var resultsUpdatableWrappers: [ResultsUpdatableNotificationWrapper] = []
  
  public init(controller: Controller) {
    self.controller = controller
    self.resultsUpdatableWrappers = []
  }
    
  func subscribe<Updatable: ResultUpdatable>(_ updatable: Updatable) {
    resultsUpdatableWrappers.append(.init(updatable: updatable))
  }
  
  func notifyReload() {
    let group = DispatchGroup()
    for interactor in resultsUpdatableWrappers {
      group.enter()
      interactor.onResultsUpdated.subscribeOnce(with: self) { (_, _) in
        group.leave()
      }
    }
    
    group.notify(queue: .main) { [weak self] in
      self?.controller.reload()
    }
    
  }
  
}
