//
//  ViewController.swift
//  Calculator
//
//  Created by Danil Denshin on 15.08.16.
//  Copyright © 2016 el2Nil. All rights reserved.
//

import UIKit
import Foundation

class CalculatorViewController: UIViewController {
	
	// MARK: Properties
	@IBOutlet weak var graphButton: UIButton! {
		didSet {
			setupGraphButton()
		}
	}
	
	private func setupGraphButton() {
		if let graphButton = graphButton {
			if brain.description.isEmpty || brain.isPartialResult {
				graphButton.highlighted = true
				graphButton.enabled = false
			} else {
				graphButton.highlighted = false
				graphButton.enabled = true
			}
		}
		
	}
	
	@IBOutlet private weak var display: UILabel!
	@IBOutlet private weak var actionsDisplay: UILabel!
	@IBOutlet weak var dotButton: UIButton! {
		didSet {
			dotButton.setTitle(decimalSeparator, forState: .Normal)
		}
	}
	
	private var actionsDescription: String {
		set {
			actionsDisplay.text = newValue + (brain.isPartialResult ? "..." : " =")
			setupGraphButton()
		}
		get {
			return actionsDisplay.text != nil ? actionsDisplay.text! : ""
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
	
	private let decimalSeparator = formatter.decimalSeparator ?? "."
	
	private var brain = CalculatorBrain()
	
	private var displayValue: Double? {
		get {
			if let text = display.text, number = formatter.numberFromString(text) {
				return number.doubleValue
			}
			return nil
		}
		set {
			if let error = brain.error {
				display.text = error
			} else {
				
				if newValue != nil {
					display.text = formatter.stringFromNumber(newValue!) ?? "0"
				} else {
					display.text = "0"
				}
			}
			actionsDescription = brain.description
		}
	}
	
	private var savedProgram: CalculatorBrain.PropertyList?
	
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
	
	private struct StoryBoard {
		static let ShowGraph = "Show Graph"
	}
	
	private let defaults = NSUserDefaults.standardUserDefaults()
	private struct defaultsKeys {
		static let graphProgram = "CalculatorViewController.graphProgram"
		static let brainBrogram = "CalculatorViewController.brainProgram"
	}
	
	private var graphProgram: CalculatorBrain.PropertyList? {
		get { return defaults.objectForKey(defaultsKeys.graphProgram) as? [AnyObject] }
		set { defaults.setObject(newValue, forKey: defaultsKeys.graphProgram) }
	}
	private var brainProgram: CalculatorBrain.PropertyList? {
		get { return defaults.objectForKey(defaultsKeys.brainBrogram) as? [AnyObject] }
		set { defaults.setObject(newValue, forKey: defaultsKeys.brainBrogram) }
	}
	
	@IBAction func showGraph(sender: UIButton) {
		graphProgram = brain.program
		if let graphNC = splitViewController?.viewControllers.last as? UINavigationController {
			if let graphVC = graphNC.topViewController as? GraphViewController {
				prepareGraphVC(graphVC)
			} else {
				performSegueWithIdentifier(StoryBoard.ShowGraph, sender: nil)
			}
		}
		
		
	}
	
	
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
			if display.text!.isEmpty {
				userIsInTheMiddleOfTyping = false
				displayValue = brain.result
			}
		} else {
			brain.undoLast()
			displayValue = brain.result
		}
		
	}
	
	@IBAction func clear() {
		brain.clear()
		brain.clearVariables()
		actionsDescription = " "
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
		}
	}
	
	@IBAction func pushVariable(sender: UIButton) {
		if let variableName = sender.currentTitle {
			brain.setOperand(variableName)
		}
		displayValue = brain.result
	}
	
	@IBAction func setVariable(sender: UIButton) {
		if var variable = sender.currentTitle {
			variable.removeAtIndex(sender.currentTitle!.startIndex)
			if let value = displayValue {
				userIsInTheMiddleOfTyping = false
				brain.setVariable(variable, value: value)
			}
			displayValue = brain.result
		}
	}
	
	@IBAction private func performOperation(sender: UIButton) {
		if let _ = brain.error {
			brain.clear()
		}
		if let displayOp = displayValue {
			if userIsInTheMiddleOfTyping {
				brain.setOperand(displayOp)
				userIsInTheMiddleOfTyping = false
			}
			if let mathematicalSymblol = sender.currentTitle {
				brain.performOperation(mathematicalSymblol)
			}
			displayValue = brain.result
		}
	}
	
	// MARK: Lifecycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		if let gProgram = graphProgram {
			brain.program = gProgram
			displayValue = brain.result
			actionsDescription = brain.description
		}
		if let graphNC = splitViewController?.viewControllers.last as? UINavigationController {
			if let graphVC = graphNC.topViewController as? GraphViewController {
				prepareGraphVC(graphVC)
				
			}
			//			if let bProgram = brainProgram {
			//				brain.program = bProgram
			//				displayValue = brain.result
			//				actionsDescription = brain.description
			//			}
		}
	}
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		self.navigationController?.setNavigationBarHidden(true, animated: false)
	}
	
	override func viewWillDisappear(animated: Bool) {
		super.viewWillDisappear(animated)
		self.navigationController?.setNavigationBarHidden(false, animated: false)
	}
	
	
	
	override func willTransitionToTraitCollection(newCollection: UITraitCollection, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
		super.willTransitionToTraitCollection(newCollection, withTransitionCoordinator: coordinator)
		configureView(newCollection.verticalSizeClass, buttonBlank: buttonBlank)
	}
	
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if let graphNC = segue.destinationViewController as? UINavigationController, identifer = segue.identifier where identifer == StoryBoard.ShowGraph {
			if let graphVC = graphNC.topViewController as? GraphViewController {
				
				graphVC.title = brain.description
				graphVC.functionForDraw = { [weak weakSelf = self] in
					weakSelf?.brain.setVariable("M", value: $0)
					return weakSelf?.brain.result}
				
			}
		}
	}
	
	private func prepareGraphVC(graphVC: GraphViewController) {
		graphVC.title = brain.description
		graphVC.functionForDraw = { [weak weakSelf = self] in
			weakSelf?.brain.setVariable("M", value: $0)
			return weakSelf?.brain.result}
	}
	
	override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
		return !brain.isPartialResult
	}
	
}

