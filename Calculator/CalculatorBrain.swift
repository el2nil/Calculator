//
//  CalculatorBrain.swift
//  Calculator
//
//  Created by Danil Denshin on 16.08.16.
//  Copyright © 2016 el2Nil. All rights reserved.
//

import Foundation

extension Double {
	func description() -> String {
		
		return deleteDecimalZeros(String(self))
		
	}
}

func deleteDecimalZeros(inputString: String) -> String {
	
	if let range = inputString.rangeOfString(".0") where inputString.hasSuffix(".0") {
		var newString = inputString
		newString.removeRange(range)
		return newString
	}
	
	return inputString
}

class CalculatorBrain {
	
	// MARK: Properties
	
	private var accumulator = 0.0
	
	private var internalProgram = [AnyObject]()
	
	private let parenthesisOperations = ["+", "−"]

	var description: String = ""
	
	var isPartialResult: Bool {
		get {
			return pending != nil
		}
	}
	
	var variableValues = [String: Double]() {
		didSet {
			program = internalProgram
		}
	}
	
	func setOperand(variableName: String) {
		
	}

	func setOperand(operand: Double) {
		accumulator = operand
		internalProgram.append(operand)
		
		// description
		if !isPartialResult {
			description = ""
		} else if isPartialResult && pending!.secondOperandDescripted {
			pending = nil
			description = ""
		}
	}
	
	private var operations: Dictionary<String, Operation> = [
		"rand" : Operation.NullaryOperation(drand48),
		"x²" : Operation.UnaryOperation({ $0 * $0 }),
		"x⁻¹" : Operation.UnaryOperation({ 1 / $0 }),
		"sin⁻¹" : Operation.UnaryOperation({ 1 / sin($0) }),
		"cos⁻¹" : Operation.UnaryOperation({ 1 / cos($0) }),
		"tan" : Operation.UnaryOperation(tan),
		"ln" : Operation.UnaryOperation(log),
		"sin" : Operation.UnaryOperation(sin),
		"cos" : Operation.UnaryOperation(cos),
		"π" : Operation.Constant(M_PI),
		"e" : Operation.Constant(M_E),
		"√" : Operation.UnaryOperation(sqrt),
		"±" : Operation.UnaryOperation({ -$0 }),
		"×"	: Operation.BinaryOperation({ $0 * $1 }),
		"÷"	: Operation.BinaryOperation({ $0 / $1 }),
		"+"	: Operation.BinaryOperation({ $0 + $1 }),
		"−"	: Operation.BinaryOperation({ $0 - $1 }),
		"=" : Operation.Equals
	]
	
	private enum Operation {
		case Constant(Double)
		case UnaryOperation((Double) -> Double)
		case BinaryOperation((Double, Double) -> Double)
		case Equals
		case NullaryOperation(() -> Double)
	}
	
	func performOperation(symbol: String) {
		internalProgram.append(symbol)
		if let operation = operations[symbol] {
			
			switch operation {
			case .NullaryOperation(let function):
				accumulator = function()
			case .Constant(let value):
				accumulator = value
				description += symbol
				if isPartialResult {
					pending!.secondOperandDescripted = true
				}
				
			case .UnaryOperation(let function):
				
				// description
				if isPartialResult {
					description += symbol + addParenthesis(accumulator.description())
					pending!.secondOperandDescripted = true
				} else if !isPartialResult && description.isEmpty {
					description = symbol + addParenthesis(accumulator.description())
				} else {
					description = symbol + addParenthesis(description)
				}
				
				accumulator = function(accumulator)
			case .BinaryOperation(let function):
				
				// description
				if !description.isEmpty && !isPartialResult && !parenthesisOperations.contains(symbol) {
					description = addParenthesis(description) + " \(symbol) "
				} else if !description.isEmpty && !isPartialResult {
					description += " \(symbol) "
				} else {
					if isPartialResult && pending!.needParenthesis && !parenthesisOperations.contains(symbol) {
						description = addParenthesis(description + accumulator.description()) + " \(symbol) "
					} else {
						description += accumulator.description() + " \(symbol) "
					}
				}
				
				executePendingBinaryOperation()
				pending = PerndingBinaryOperationInfo(binaryOperation: function, firstOperand: accumulator, secondOperandDescripted: false, needParenthesis: parenthesisOperations.contains(symbol))
			case .Equals:
				
				// description
				if isPartialResult && !pending!.secondOperandDescripted {
					description += accumulator.description()
				}
				
				executePendingBinaryOperation()
			}
		}
	}
	
	private func addParenthesis(string: String) -> String {
		return "(" + string + ")"
	}
	
	private func addToDescription(string: String) {
		description += string
	}
	
	private func executePendingBinaryOperation() {
		if let pending = pending {
			accumulator = pending.binaryOperation(pending.firstOperand, accumulator)
			self.pending = nil
		}
	}
	
	private var pending: PerndingBinaryOperationInfo?
	
	private struct PerndingBinaryOperationInfo {
		var binaryOperation: (Double, Double) -> Double
		var firstOperand: Double
		var secondOperandDescripted: Bool
		var needParenthesis: Bool
	}
	
	typealias PropertyList = AnyObject
	
	var program: PropertyList {
		get {
			return internalProgram
		}
		set {
			clear()
			if let arrayOfObjects = newValue as? [AnyObject] {
				for op in arrayOfObjects {
					if let operand = op as? Double {
						setOperand(operand)
					} else if let operation = op as? String {
						performOperation(operation)
					}
				}
			}
		}
	}
	
	func clear() {
		accumulator = 0
		pending = nil
		description = ""
		internalProgram.removeAll()
	}
	
	var result: Double {
		get {
			return accumulator
		}
	}
	
}

let formatter: NSNumberFormatter = {
	let formatter = NSNumberFormatter()
	formatter.locale = NSLocale.currentLocale()
	formatter.maximumFractionDigits = 6
	formatter.notANumberSymbol = "Error"
	formatter.groupingSeparator = " "
	formatter.numberStyle = .DecimalStyle
	return formatter
}()

class CalculatorFormatter: NSNumberFormatter {
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	override init() {
		super.init()
		self.locale = NSLocale.currentLocale()
		self.maximumFractionDigits = 6
		self.notANumberSymbol = "Error"
		self.groupingSeparator = " "
		self.numberStyle = .DecimalStyle
	}
	
	static let sharedInstance = CalculatorFormatter()
	
}
