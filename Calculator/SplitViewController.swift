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
	
	func splitViewController(splitViewController: UISplitViewController, collapseSecondaryViewController secondaryViewController: UIViewController, ontoPrimaryViewController primaryViewController: UIViewController) -> Bool {
		return true
	}
	
	private func updateButtons() {
		if let nc = viewControllers[viewControllers.count-1] as? UINavigationController {
			let GraphCalcButton = displayModeButtonItem()
			nc.topViewController?.navigationItem.setLeftBarButtonItem(GraphCalcButton, animated: false)
		}
	}
	
	func splitViewController(svc: UISplitViewController, willChangeToDisplayMode displayMode: UISplitViewControllerDisplayMode) {
		switch displayMode {
		case .PrimaryHidden:
			updateButtons()
		default: break
		}
	}
	
	override func viewWillDisappear(animated: Bool) {
		super.viewWillDisappear(animated)
	}
	
}
