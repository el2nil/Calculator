//
//  SplitViewController.swift
//  Calculator
//
//  Created by Danil Denshin on 25.08.16.
//  Copyright © 2016 el2Nil. All rights reserved.
//

import UIKit

class SplitViewController: UISplitViewController, UISplitViewControllerDelegate {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.delegate = self
		
		updateButtons()
		
	}
	
	func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
		return true
	}
	
	fileprivate func updateButtons() {
		if let nc = viewControllers[viewControllers.count-1] as? UINavigationController {
			let GraphCalcButton = displayModeButtonItem
			nc.topViewController?.navigationItem.setLeftBarButton(GraphCalcButton, animated: false)
		}
	}
	
	func splitViewController(_ svc: UISplitViewController, willChangeTo displayMode: UISplitViewControllerDisplayMode) {
		switch displayMode {
		case .primaryHidden:
			updateButtons()
		default: break
		}
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
	}
	
}
