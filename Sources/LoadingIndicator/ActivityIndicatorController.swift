//
//  ActivityIndicatorController.swift
//  InstantSearchCore
//
//  Created by Guy Daher on 23/05/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation
import UIKit

public class ActivityIndicatorController: LoadableController {

  let activityIndicator: UIActivityIndicatorView

  public init (activityIndicator: UIActivityIndicatorView) {
    self.activityIndicator = activityIndicator
  }

  public func startAnimating() {
    activityIndicator.startAnimating()
  }

  public func stopAnimating() {
    activityIndicator.stopAnimating()
  }

}
