//
//  CalculatorBrain.swift
//  Calculator
//
//  Created by Danil Denshin on 16.08.16.
//  Copyright © 2016 el2Nil. All rights reserved.
//

import Foundation

class CalculatorBrain {
	
	// MARK: Properties
	
	fileprivate var accumulator = 0.0
	fileprivate var descriptionAccumulator = ""
	fileprivate var currentPrecedence = Int.max
	
	fileprivate var internalProgram = [AnyObject]()
	
	fileprivate let parenthesisOperations = ["+", "−"]
	
	var description: String {
		get {
			if pending == nil {
				return descriptionAccumulator
			} else {
//				return pending!.descriptionFunction(pending!.descriptionOperand, pending!.descriptionOperand != descriptionAccumulator ? descriptionAccumulator : "")
				return pending!.descriptionFunction(pending!.descriptionOperand, pending!.secodndOperandSetted ? descriptionAccumulator : "")
			}
		}
	}
	var error: String?
	
	var isPartialResult: Bool {
		get {
			return pending != nil
		}
	}
	
	fileprivate var variableValues = [String: Double]() {
		didSet {
			program = internalProgram as CalculatorBrain.PropertyList
		}
	}
	
	// MARK: Methods
	
	func setOperand(_ variableName: String) {
		if pending != nil && !pending!.secodndOperandSetted {
			pending!.secodndOperandSetted = true
		}
		operations[variableName] = Operation.variable
		performOperation(variableName)
	}
	
	func setVariable(_ variableName: String, value: Double) {
		operations[variableName] = Operation.variable
		variableValues[variableName] = value
	}
	
	func setOperand(_ operand: Double) {
		if pending != nil && !pending!.secodndOperandSetted {
			pending!.secodndOperandSetted = true
		}
		accumulator = operand
		internalProgram.append(operand as AnyObject)
		descriptionAccumulator = String(format: "%g", accumulator)
	}
	
	fileprivate var operations: Dictionary<String, Operation> = [
		"x²"	: Operation.unaryOperation({ $0 * $0 }, { "(\($0))²" }, nil),
		"x⁻¹"	: Operation.unaryOperation({ 1 / $0 }, { "(\($0))¹" }, { $0 == 0.0 ? "Деление на ноль" : nil }),
		"sin⁻¹" : Operation.unaryOperation({ 1 / sin($0) }, { "sin(\($0))⁻¹" }, { sin($0) == 0.0 ? "Деление на ноль" : nil  }),
		"cos⁻¹" : Operation.unaryOperation({ 1 / cos($0) }, { "cos(\($0))⁻¹" }, { cos($0) == 0.0 ? "Деление на ноль" : nil }),
		"tan"	: Operation.unaryOperation(tan, { "tan(\($0))" }, nil),
		"ln"	: Operation.unaryOperation(log, { "ln(\($0))" }, { $0 < 0.0 ? "ln отриц. числа" : nil }),
		"sin"	: Operation.unaryOperation(sin, { "sin(\($0))" }, nil),
		"cos"	: Operation.unaryOperation(cos, { "cos(\($0))" }, nil),
		"√"		: Operation.unaryOperation(sqrt, { "√(\($0))" }, { $0 < 0.0 ? "Корень отриц. числа" : nil }),
		"±"		: Operation.unaryOperation({ -$0 }, { "-(\($0))" }, nil),
		"×"		: Operation.binaryOperation({ $0 * $1 }, { "\($0) × \($1)" }, 1, nil),
		"÷"		: Operation.binaryOperation({ $0 / $1 }, { "\($0) ÷ \($1)" }, 1, { $1 == 0.0 ? "Деление на ноль" : nil }),
		"+"		: Operation.binaryOperation({ $0 + $1 }, { "\($0) + \($1)" }, 0, nil),
		"−"		: Operation.binaryOperation({ $0 - $1 }, { "\($0) − \($1)" }, 0, nil),
		"rand"	: Operation.nullaryOperation(drand48, "rand()"),
		"π"		: Operation.constant(M_PI),
		"e"		: Operation.constant(M_E),
		"="		: Operation.equals
	]
	
	fileprivate enum Operation {
		case constant(Double)
		case unaryOperation((Double) -> Double, (String) -> String, ((Double) -> String?)?)
		case binaryOperation((Double, Double) -> Double, (String, String) -> String, Int, ((Double, Double) -> String?)?)
		case equals
		case nullaryOperation(() -> Double, String)
		case variable
	}
	
	func performOperation(_ symbol: String) {
		internalProgram.append(symbol as AnyObject)
		if let operation = operations[symbol] {
			
			switch operation {
			case .variable:
				accumulator = variableValues[symbol] != nil ? variableValues[symbol]! : 0.0
				descriptionAccumulator = symbol
			case .nullaryOperation(let function, let descriptionValue):
				accumulator = function()
				descriptionAccumulator = descriptionValue
			case .constant(let value):
				accumulator = value
				descriptionAccumulator = symbol
			case .unaryOperation(let function, let descriptionFunction, let validatingFunction):
				error = validatingFunction?(accumulator)
				accumulator = function(accumulator)
				descriptionAccumulator = descriptionFunction(descriptionAccumulator)
			case .binaryOperation(let function, let descriptionFunction, let precedence, let validatingFunction):
				if currentPrecedence < precedence {
					descriptionAccumulator = addParenthesis(descriptionAccumulator)
				}
				currentPrecedence = precedence
				
				executePendingBinaryOperation()
				pending = PerndingBinaryOperationInfo(binaryOperation: function, firstOperand: accumulator, descriptionFunction: descriptionFunction, descriptionOperand: descriptionAccumulator, validatingFunction: validatingFunction, secodndOperandSetted: false)
			case .equals:
				executePendingBinaryOperation()
			}
		}
	}
	
	fileprivate func addParenthesis(_ string: String) -> String {
		return "(" + string + ")"
	}
	
	fileprivate func executePendingBinaryOperation() {
		if var pending = pending {
			pending.secodndOperandSetted = false
			error = pending.validatingFunction?(pending.firstOperand, accumulator)
			descriptionAccumulator = pending.descriptionFunction(pending.descriptionOperand, descriptionAccumulator)
			accumulator = pending.binaryOperation(pending.firstOperand, accumulator)
			self.pending = nil
		}
	}
	
	fileprivate var pending: PerndingBinaryOperationInfo?
	
	fileprivate struct PerndingBinaryOperationInfo {
		var binaryOperation: (Double, Double) -> Double
		var firstOperand: Double
		var descriptionFunction: (String, String) -> String
		var descriptionOperand: String
		var validatingFunction: ((Double, Double) -> String?)?
		var secodndOperandSetted: Bool
	}
	
	typealias PropertyList = [AnyObject]
	
	var program: PropertyList {
		get {
			return internalProgram as CalculatorBrain.PropertyList
		}
		set {
			clear()
//			if let arrayOfObjects = newValue as? CalculatorBrain.PropertyList {
				for op in newValue {
					if let operand = op as? Double {
						setOperand(operand)
					} else if let operation = op as? String {
						if operations[operation] == nil { operations[operation] = Operation.variable }
						performOperation(operation)
					}
				}
//			}
		}
	}
	
	func clear() {
		accumulator = 0
		pending = nil
		error = nil
		currentPrecedence = Int.max
		descriptionAccumulator = ""
		internalProgram.removeAll()
	}
	
	func clearVariables() {
		variableValues = [:]
	}
	
	func undoLast() {
		if internalProgram.isEmpty { clear(); return }
		internalProgram.removeLast()
		program = internalProgram as CalculatorBrain.PropertyList
	}
	
	var result: Double {
		get {
			return accumulator
		}
	}
	
}

// MARK: Formatter

let formatter: NumberFormatter = {
	let formatter = NumberFormatter()
	formatter.locale = Locale.current
	formatter.maximumFractionDigits = 6
	formatter.notANumberSymbol = "Error"
	formatter.groupingSeparator = " "
	formatter.numberStyle = .decimal
	return formatter
}()

class CalculatorFormatter: NumberFormatter {
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	override init() {
		super.init()
		self.locale = Locale.current
		self.maximumFractionDigits = 6
		self.notANumberSymbol = "Error"
		self.groupingSeparator = " "
		self.numberStyle = .decimal
	}
	
	static let sharedInstance = CalculatorFormatter()
	
}
