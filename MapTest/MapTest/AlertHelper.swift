//
//  AlertHelper.swift
//  MapTest
//
//  Created by Echo on 10/25/19.
//  Copyright © 2019 Echo. All rights reserved.
//

import UIKit

struct AlertHelper {
    static func showAlert(title: String = "Warning", message: String, presentViewController: UIViewController) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default)
        alert.addAction(okAction)
        
        presentViewController.present(alert, animated: true)
    }
}
