//
//  TextfieldController.swift
//  InstantSearchCore
//
//  Created by Guy Daher on 22/05/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation
import UIKit

public class TextFieldController: SearchableController {

  public var onSearch: ((String) -> Void)?

  public init (textField: UITextField) {
    textField.addTarget(self, action: #selector(textFieldTextChanged), for: .editingChanged)
  }

  @objc func textFieldTextChanged(textField: UITextField) {
    guard let searchText = textField.text else { return }
    onSearch?(searchText)
  }
}
