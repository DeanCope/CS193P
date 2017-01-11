//
//  CalculatorBrain.swift
//  Calculator
//
//  Created by Dean Copeland on 11/22/16.
//  Copyright © 2016 Dean Copeland. All rights reserved.
//

import Foundation

class CalculatorBrain {
    
    // An optional NumberFormatter can be used for format numbers in the description
    var numberFormatter: NumberFormatter? = nil
    private var accumulator = 0.0
    private var internalProgram = [AnyObject]()
    
    var description: String {
        get {
            if isPartialResult {
                if pending!.firstOperandDescription == accumulatorDescription {
                    return pending!.descriptionFunction(pending!.firstOperandDescription, "")
                } else {
                    return pending!.descriptionFunction(pending!.firstOperandDescription, accumulatorDescription)
                }
            } else {
                return accumulatorDescription
            }
        }
    }
    private var currentPrecedence = Int.max
    private var accumulatorDescription = "" {
        didSet {
            if pending == nil {
                currentPrecedence = Int.max
            }
        }
    }
    var isPartialResult: Bool {
        get {
            return pending != nil
        }
    }

    private func random() -> Double {
        // Returns a random number between 0 and 1
        return Double(arc4random() / UINT32_MAX)
    }
    
    func setOperand(_ operand: Double) {
        accumulator = operand
        if let formatter = numberFormatter {
            accumulatorDescription = formatter.string(for: operand)!
        } else {
            accumulatorDescription = String(operand)
        }
        internalProgram.append(operand as AnyObject)
    }
    
    func setOperand(_ variableName: String) {
        // This function tells the brain to use a particular, previously set variable as an operand
        
        if let val = variableValues[variableName] {
            accumulator = val
        }
        else {
            accumulator = 0.0
        }
        accumulatorDescription = variableName
        internalProgram.append(variableName as AnyObject)
    }
    
    // Dictionary of variables names and values
    private var variableValues = [String: Double]()
    
    func setVariable(varName: String, value: Double?) {
        
        variableValues[varName] = value
        // whenever a varible is set, we need to re-run the program
        runProgram()
    }
    
    func removeVariable(varName: String) {
        variableValues.removeValue(forKey: "M")
        // Rerun the program after removing a variable value
        runProgram()
    }
    
    func undo() {
        if internalProgram.count > 0 {
            internalProgram.remove(at: internalProgram.count - 1)
        }
        runProgram()
    }
    
    private var operations: Dictionary<String,Operation> = [
        "π" : Operation.constant(M_PI),
        "e" : Operation.constant(M_E),
        "rand": Operation.nullaryOperation({Double(arc4random() / UINT32_MAX)}, "Random"),
        "√" : Operation.unaryOperation(sqrt,  {"√(\($0))"}),
        "sin": Operation.unaryOperation(sin,  {"sin(\($0))"}),
        "cos": Operation.unaryOperation(cos, {"cos(\($0))"}),
        "tan": Operation.unaryOperation(tan, {"tan(\($0))"}),
        "%": Operation.unaryOperation({$0 / 100}, {"%(\($0))"}),
        "pow": Operation.binaryOperation(pow, {"\($0) ^ \($1)"}, 160),
        "×": Operation.binaryOperation({$0 * $1}, {"\($0) × \($1)"},150),
        "÷": Operation.binaryOperation({$0 / $1}, {"\($0) ÷ \($1)"}, 150),
        "+": Operation.binaryOperation({$0 + $1}, {"\($0) + \($1)"}, 140),
        "−": Operation.binaryOperation({$0 - $1}, {"\($0) - \($1)"}, 140),
        "=": Operation.equals
    ]
    
    private enum Operation {
        case constant(Double)
        // A Nullary operation is one that takes no arguments
        // Associated vale is a tuple containing a Function and Description String
        case nullaryOperation(() -> Double, String)
        // Associated value is a tuple containing Function and Description Function
        case unaryOperation((Double) -> Double, (String) -> String)
        // Associated value is a tuple containing Function, Description Function and Operator Precedence
        case binaryOperation((Double,Double) -> Double, (String, String) -> String, Int)
        case equals
    }
    
    func performOperation(_ symbol: String) {
        internalProgram.append(symbol as AnyObject)
        if let operation = operations[symbol] {
            switch operation {
            case .constant(let value):
                accumulator = value
                accumulatorDescription = symbol
            case let .nullaryOperation(function, description):
                accumulator = function()
                accumulatorDescription = description
            case let .unaryOperation(function, descriptionFunction):
                accumulator = function(accumulator)
                accumulatorDescription = descriptionFunction(accumulatorDescription)
    
            case let .binaryOperation(function, descriptionFunction, precedence):
                executePendingBinaryOperation()
                if currentPrecedence < precedence {
                    accumulatorDescription = "(\(accumulatorDescription))"
                }
                currentPrecedence = precedence
                pending = PendingBinaryOperationInfo(binaryFunction: function, firstOperand: accumulator, firstOperandDescription: accumulatorDescription, descriptionFunction: descriptionFunction)
            case .equals:
                executePendingBinaryOperation()
            }
        } else {
            // Not in the dictionary of "known" operations, so assume it's a variable
            // If nil, default to 0.0 using Nil-Coalescing Operator
            accumulator = variableValues[symbol] ?? 0.0
            accumulatorDescription = symbol
        }
    }
    
    private func executePendingBinaryOperation() {
        // if there is a pending binary operation, then execute the function 
        // and also keep the corresponding description in synch
        if pending != nil {
            accumulator = pending!.binaryFunction(pending!.firstOperand, accumulator)
            accumulatorDescription = pending!.descriptionFunction(pending!.firstOperandDescription, accumulatorDescription)
            pending = nil
        }
    }
    
    private var pending: PendingBinaryOperationInfo?
    
    private struct PendingBinaryOperationInfo {
        // binary function is the mathematical function
        var binaryFunction: (Double, Double) -> Double
        var firstOperand: Double
        var firstOperandDescription: String
        // description function is the user presentable description of the mathematical function
        var descriptionFunction: (String, String) -> String
    }
    
    typealias PropertyList = AnyObject
    
    var program: PropertyList {
        get {
            return internalProgram as CalculatorBrain.PropertyList
        }
        set {
            clear()
            if let arrayOfOps = newValue as? [AnyObject] {
                for op in arrayOfOps {
                    if let operand = op as? Double {
                        setOperand(operand)
                    }
                    else if let symbol = op as? String {
                        performOperation(symbol)
                    }
                }
            }
        }
    }
    
    func runProgram() {
        let theProgram = internalProgram
        clear()
        for op in theProgram {
            if let operand = op as? Double {
                setOperand(operand)
            }
            else if let symbol = op as? String {
                performOperation(symbol)
            }
        }
    }

    
    func clear() {
        accumulator = 0.0
        accumulatorDescription = ""
        pending = nil
        internalProgram.removeAll()
    }
    
    // Read-Only property because Set is not implemented
    var result: Double {
        get {
            return accumulator
        }
    }
}




