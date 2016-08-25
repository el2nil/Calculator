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
	private var descriptionAccumulator = ""
	private var currentPrecedence = Int.max
	
	private var internalProgram = [AnyObject]()
	
	private let parenthesisOperations = ["+", "−"]
	
	var description: String {
		get {
			if pending == nil {
				return descriptionAccumulator
			} else {
				return pending!.descriptionFunction(pending!.descriptionOperand, pending!.descriptionOperand != descriptionAccumulator ? descriptionAccumulator : "")
			}
		}
	}
	var error: String?
	
	var isPartialResult: Bool {
		get {
			return pending != nil
		}
	}
	
	private var variableValues = [String: Double]() {
		didSet {
			program = internalProgram
		}
	}
	
	func setOperand(variableName: String) {
		operations[variableName] = Operation.Variable
		performOperation(variableName)
	}
	
	func setVariable(variableName: String, value: Double) {
		operations[variableName] = Operation.Variable
		variableValues[variableName] = value
	}
	
	func setOperand(operand: Double) {
		accumulator = operand
		internalProgram.append(operand)
		descriptionAccumulator = String(format: "%g", accumulator)
	}
	
	private var operations: Dictionary<String, Operation> = [
		"x²"	: Operation.UnaryOperation({ $0 * $0 }, { "(\($0))²" }, nil),
		"x⁻¹"	: Operation.UnaryOperation({ 1 / $0 }, { "(\($0))¹" }, { $0 == 0.0 ? "Деление на ноль" : nil }),
		"sin⁻¹" : Operation.UnaryOperation({ 1 / sin($0) }, { "sin(\($0))⁻¹" }, { sin($0) == 0.0 ? "Деление на ноль" : nil  }),
		"cos⁻¹" : Operation.UnaryOperation({ 1 / cos($0) }, { "cos(\($0))⁻¹" }, { cos($0) == 0.0 ? "Деление на ноль" : nil }),
		"tan"	: Operation.UnaryOperation(tan, { "tan(\($0))" }, nil),
		"ln"	: Operation.UnaryOperation(log, { "ln(\($0))" }, { $0 < 0.0 ? "ln отриц. числа" : nil }),
		"sin"	: Operation.UnaryOperation(sin, { "sin(\($0))" }, nil),
		"cos"	: Operation.UnaryOperation(cos, { "cos(\($0))" }, nil),
		"√"		: Operation.UnaryOperation(sqrt, { "√(\($0))" }, { $0 < 0.0 ? "Корень отриц. числа" : nil }),
		"±"		: Operation.UnaryOperation({ -$0 }, { "-(\($0))" }, nil),
		"×"		: Operation.BinaryOperation({ $0 * $1 }, { "\($0) × \($1)" }, 1, nil),
		"÷"		: Operation.BinaryOperation({ $0 / $1 }, { "\($0) ÷ \($1)" }, 1, { $1 == 0.0 ? "Деление на ноль" : nil }),
		"+"		: Operation.BinaryOperation({ $0 + $1 }, { "\($0) + \($1)" }, 0, nil),
		"−"		: Operation.BinaryOperation({ $0 - $1 }, { "\($0) − \($1)" }, 0, nil),
		"rand"	: Operation.NullaryOperation(drand48, "rand()"),
		"π"		: Operation.Constant(M_PI),
		"e"		: Operation.Constant(M_E),
		"="		: Operation.Equals
	]
	
	private enum Operation {
		case Constant(Double)
		case UnaryOperation((Double) -> Double, (String) -> String, ((Double) -> String?)?)
		case BinaryOperation((Double, Double) -> Double, (String, String) -> String, Int, ((Double, Double) -> String?)?)
		case Equals
		case NullaryOperation(() -> Double, String)
		case Variable
	}
	
	func performOperation(symbol: String) {
		internalProgram.append(symbol)
		if let operation = operations[symbol] {
			
			switch operation {
			case .Variable:
				accumulator = variableValues[symbol] != nil ? variableValues[symbol]! : 0.0
				descriptionAccumulator = symbol
			case .NullaryOperation(let function, let descriptionValue):
				accumulator = function()
				descriptionAccumulator = descriptionValue
			case .Constant(let value):
				accumulator = value
				descriptionAccumulator = symbol
			case .UnaryOperation(let function, let descriptionFunction, let validatingFunction):
				error = validatingFunction?(accumulator)
				accumulator = function(accumulator)
				descriptionAccumulator = descriptionFunction(descriptionAccumulator)
			case .BinaryOperation(let function, let descriptionFunction, let precedence, let validatingFunction):
				if currentPrecedence < precedence {
					descriptionAccumulator = addParenthesis(descriptionAccumulator)
				}
				currentPrecedence = precedence
				
				executePendingBinaryOperation()
				pending = PerndingBinaryOperationInfo(binaryOperation: function, firstOperand: accumulator, descriptionFunction: descriptionFunction, descriptionOperand: descriptionAccumulator, validatingFunction: validatingFunction)
			case .Equals:
				executePendingBinaryOperation()
			}
		}
	}
	
	private func addParenthesis(string: String) -> String {
		return "(" + string + ")"
	}
	
	private func executePendingBinaryOperation() {
		if let pending = pending {
			error = pending.validatingFunction?(pending.firstOperand, accumulator)
			descriptionAccumulator = pending.descriptionFunction(pending.descriptionOperand, descriptionAccumulator)
			accumulator = pending.binaryOperation(pending.firstOperand, accumulator)
			self.pending = nil
		}
	}
	
	private var pending: PerndingBinaryOperationInfo?
	
	private struct PerndingBinaryOperationInfo {
		var binaryOperation: (Double, Double) -> Double
		var firstOperand: Double
		var descriptionFunction: (String, String) -> String
		var descriptionOperand: String
		var validatingFunction: ((Double, Double) -> String?)?
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
						if operations[operation] == nil { operations[operation] = Operation.Variable }
						performOperation(operation)
					}
				}
			}
		}
	}
	
	func clear() {
		accumulator = 0
		pending = nil
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
		program = internalProgram
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
