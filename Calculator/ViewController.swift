//
//  ViewController.swift
//  Calculator
//
//  Created by Danil Denshin on 15.08.16.
//  Copyright © 2016 el2Nil. All rights reserved.
//

import UIKit
import Foundation

class ViewController: UIViewController {
	
	// MARK: Properties
	@IBOutlet private weak var display: UILabel!
	@IBOutlet weak var actionsDisplay: UILabel!
	@IBOutlet weak var dotButton: UIButton! {
		didSet {
			dotButton.setTitle(decimalSeparator, forState: .Normal)
		}
	}
	
	@IBOutlet weak var stack1: UIStackView!
	@IBOutlet weak var stack2: UIStackView!
	@IBOutlet weak var stack3: UIStackView!
	@IBOutlet weak var stack4: UIStackView!
	@IBOutlet weak var stack5: UIStackView!
	@IBOutlet weak var stack6: UIStackView!
	@IBOutlet weak var stack7: UIStackView!
	
	@IBOutlet weak var x_2: UIButton!
	@IBOutlet weak var x_1: UIButton!
	@IBOutlet weak var sin_1: UIButton!
	@IBOutlet weak var cos_1: UIButton!
	@IBOutlet weak var rand: UIButton!
	
	private lazy var buttonBlank: UIButton = {
		let button = UIButton(frame: CGRectMake(100,400,100,50))
		button.backgroundColor = UIColor.blackColor()
		button.setTitle("", forState: .Normal)
		return button
	}()
	
	
	private var userIsInTheMiddleOfTyping = false
	
	let decimalSeparator = formatter.decimalSeparator ?? "."
	
	private var brain = CalculatorBrain()
	
	private var displayValue: Double? {
		get {
			if let text = display.text, value = Double(text) {
				return value
			}
			return nil
		}
		set {
			if newValue != nil {
				display.text = formatter.stringFromNumber(newValue!) ?? " "
			} else {
				display.text = " "
			}
		}
	}
	
	var savedProgram: CalculatorBrain.PropertyList?
	
	override func willTransitionToTraitCollection(newCollection: UITraitCollection, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
		super.willTransitionToTraitCollection(newCollection, withTransitionCoordinator: coordinator)
		configureView(newCollection.verticalSizeClass, buttonBlank: buttonBlank)
	}
	
	private func configureView(verticalSizeClass: UIUserInterfaceSizeClass, buttonBlank: UIButton) {
		if (verticalSizeClass == .Compact) {
			stack1.addArrangedSubview(buttonBlank)
			stack3.addArrangedSubview(x_2)
			stack4.addArrangedSubview(x_1)
			stack5.addArrangedSubview(sin_1)
			stack6.addArrangedSubview(cos_1)
			stack7.addArrangedSubview(rand)
			stack2.hidden = true
		} else {
			stack2.hidden = false
			stack2.addArrangedSubview(x_2)
			stack2.addArrangedSubview(x_1)
			stack2.addArrangedSubview(sin_1)
			stack2.addArrangedSubview(cos_1)
			stack2.addArrangedSubview(rand)
			stack1.removeArrangedSubview(buttonBlank)
		}
	}
	
	// MARK: Actions
	@IBAction private func touchDigit(sender: UIButton) {
		let digit = sender.currentTitle!
		if userIsInTheMiddleOfTyping {
			if digit != decimalSeparator || display.text!.rangeOfString(decimalSeparator) == nil {
				display.text = display.text! + digit
			}
		} else {
			display.text = digit
		}
		userIsInTheMiddleOfTyping = true
	}
	
	@IBAction func plusMinus(sender: UIButton) {
		if userIsInTheMiddleOfTyping {
			if display.text!.rangeOfString("-") == nil {
				display.text = "-" + display.text!
			} else {
				display.text!.removeAtIndex(display.text!.startIndex)
			}
		} else {
			performOperation(sender)
		}
	}
	
	@IBAction func undo(sender: UIButton) {
		if userIsInTheMiddleOfTyping {
			display.text!.removeAtIndex(display.text!.endIndex.predecessor())
		}
		if display.text!.isEmpty {
			userIsInTheMiddleOfTyping = false
			displayValue = brain.result
		}
	}
	
	@IBAction func clear() {
		brain.clear()
		actionsDisplay.text = ""
//		display.text = "0"
		displayValue = nil
		userIsInTheMiddleOfTyping = false
	}
	
	@IBAction func save() {
		savedProgram = brain.program
	}
	
	@IBAction func restore() {
		if savedProgram != nil {
			brain.program = savedProgram!
			displayValue = brain.result
			actionsDisplay.text = brain.description
		}
	}
	
	@IBAction private func performOperation(sender: UIButton) {
		if let displayOp = displayValue {
			if userIsInTheMiddleOfTyping {
//				if display.text!.hasSuffix(".") { display.text! += "0" }
				brain.setOperand(displayOp)
				userIsInTheMiddleOfTyping = false
			}
			if let mathematicalSymblol = sender.currentTitle {
				brain.performOperation(mathematicalSymblol)
			}
			displayValue = brain.result
			
			if brain.isPartialResult {
				actionsDisplay.text = brain.description + " ..."
			} else {
				actionsDisplay.text = brain.description + " = "
			}
		}
	}
	
	// MARK: Other
	
}

