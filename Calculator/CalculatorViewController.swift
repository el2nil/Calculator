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
	
	fileprivate func setupGraphButton() {
		if let graphButton = graphButton {
			if brain.description.isEmpty || brain.isPartialResult {
				graphButton.isHighlighted = true
				graphButton.isEnabled = false
			} else {
				graphButton.isHighlighted = false
				graphButton.isEnabled = true
			}
		}
		
	}
	
	@IBOutlet fileprivate weak var display: UILabel!
	@IBOutlet fileprivate weak var actionsDisplay: UILabel!
	@IBOutlet weak var dotButton: UIButton! {
		didSet {
			dotButton.setTitle(decimalSeparator, for: UIControlState())
		}
	}
	
	fileprivate var actionsDescription: String {
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
	
	fileprivate lazy var buttonBlank: UIButton = {
		let button = UIButton(frame: CGRect(x: 100,y: 400,width: 100,height: 50))
		button.backgroundColor = UIColor.black
		button.setTitle("", for: UIControlState())
		return button
	}()
	
	
	fileprivate var userIsInTheMiddleOfTyping = false
	
	fileprivate let decimalSeparator = formatter.decimalSeparator ?? "."
	
	fileprivate var brain = CalculatorBrain()
	
	fileprivate var displayValue: Double? {
		get {
			if let text = display.text, let number = formatter.number(from: text) {
				return number.doubleValue
			}
			return nil
		}
		set {
			if let error = brain.error {
				display.text = error
			} else {
				
				if newValue != nil {
					display.text = formatter.string(from: NSNumber(value: newValue!)) ?? "0"
				} else {
					display.text = "0"
				}
			}
			actionsDescription = brain.description
		}
	}
	
	fileprivate var savedProgram: CalculatorBrain.PropertyList?
	
	fileprivate func configureView(_ verticalSizeClass: UIUserInterfaceSizeClass, buttonBlank: UIButton) {
		if (verticalSizeClass == .compact) {
			stack1.addArrangedSubview(buttonBlank)
			stack3.addArrangedSubview(x_2)
			stack4.addArrangedSubview(x_1)
			stack5.addArrangedSubview(sin_1)
			stack6.addArrangedSubview(cos_1)
			stack7.addArrangedSubview(rand)
			stack2.isHidden = true
		} else {
			stack2.isHidden = false
			stack2.addArrangedSubview(x_2)
			stack2.addArrangedSubview(x_1)
			stack2.addArrangedSubview(sin_1)
			stack2.addArrangedSubview(cos_1)
			stack2.addArrangedSubview(rand)
			stack1.removeArrangedSubview(buttonBlank)
		}
	}
	
	// MARK: Actions
	
	fileprivate struct StoryBoard {
		static let ShowGraph = "Show Graph"
	}
	
	fileprivate let defaults = UserDefaults.standard
	fileprivate struct defaultsKeys {
		static let graphProgram = "CalculatorViewController.graphProgram"
		static let brainBrogram = "CalculatorViewController.brainProgram"
	}
	
	fileprivate var graphProgram: CalculatorBrain.PropertyList? {
		get { return defaults.object(forKey: defaultsKeys.graphProgram) as? CalculatorBrain.PropertyList }
		set { defaults.set(newValue, forKey: defaultsKeys.graphProgram) }
	}
	fileprivate var brainProgram: CalculatorBrain.PropertyList? {
		get { return defaults.object(forKey: defaultsKeys.brainBrogram) as? CalculatorBrain.PropertyList }
		set { defaults.set(newValue, forKey: defaultsKeys.brainBrogram) }
	}
	
	@IBAction func showGraph(_ sender: UIButton) {
		graphProgram = brain.program
		if let graphNC = splitViewController?.viewControllers.last as? UINavigationController {
			if let graphVC = graphNC.topViewController as? GraphViewController {
				prepareGraphVC(graphVC)
			} else {
				performSegue(withIdentifier: StoryBoard.ShowGraph, sender: nil)
			}
		}
		
		
	}
	
	
	@IBAction fileprivate func touchDigit(_ sender: UIButton) {
		let digit = sender.currentTitle!
		if userIsInTheMiddleOfTyping {
			if digit != decimalSeparator || display.text!.range(of: decimalSeparator) == nil {
				display.text = display.text! + digit
			}
		} else {
			display.text = digit
		}
		userIsInTheMiddleOfTyping = true
	}
	
	@IBAction func plusMinus(_ sender: UIButton) {
		if userIsInTheMiddleOfTyping {
			if display.text!.range(of: "-") == nil {
				display.text = "-" + display.text!
			} else {
				display.text!.remove(at: display.text!.startIndex)
			}
		} else {
			performOperation(sender)
		}
	}
	
	@IBAction func undo(_ sender: UIButton) {
		if userIsInTheMiddleOfTyping {
			display.text!.remove(at: display.text!.characters.index(before: display.text!.endIndex))
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
	
	@IBAction func pushVariable(_ sender: UIButton) {
		if let variableName = sender.currentTitle {
			brain.setOperand(variableName)
		}
		displayValue = brain.result
	}
	
	@IBAction func setVariable(_ sender: UIButton) {
		if var variable = sender.currentTitle {
			variable.remove(at: sender.currentTitle!.startIndex)
			if let value = displayValue {
				userIsInTheMiddleOfTyping = false
				brain.setVariable(variable, value: value)
			}
			displayValue = brain.result
		}
	}
	
	@IBAction fileprivate func performOperation(_ sender: UIButton) {
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
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		self.navigationController?.setNavigationBarHidden(true, animated: false)
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		self.navigationController?.setNavigationBarHidden(false, animated: false)
	}
	
	
	
	override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
		super.willTransition(to: newCollection, with: coordinator)
		configureView(newCollection.verticalSizeClass, buttonBlank: buttonBlank)
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if let graphNC = segue.destination as? UINavigationController, let identifer = segue.identifier, identifer == StoryBoard.ShowGraph {
			if let graphVC = graphNC.topViewController as? GraphViewController {
				
				graphVC.title = brain.description
				graphVC.functionForDraw = { [weak weakSelf = self] in
					weakSelf?.brain.setVariable("M", value: $0)
					return weakSelf?.brain.result}
				
			}
		}
	}
	
	fileprivate func prepareGraphVC(_ graphVC: GraphViewController) {
		graphVC.title = brain.description
		graphVC.functionForDraw = { [weak weakSelf = self] in
			weakSelf?.brain.setVariable("M", value: $0)
			return weakSelf?.brain.result}
	}
	
	override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
		return !brain.isPartialResult
	}
	
}

