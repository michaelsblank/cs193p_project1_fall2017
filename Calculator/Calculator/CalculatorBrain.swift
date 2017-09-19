//
//  CalculatorBrain.swift
//  Calculator
//
//  Created by Michael Blankenship on 9/4/17.
//  Copyright © 2017 Michael Blankenship. All rights reserved.
//

import Foundation

private func factorial(_ op: Double) -> Double {
    if Double(Int(op)) == op {
        if op <= 1 {
            return 1.0
        } else {
            return op * factorial(op - 1)
        }
    }
    return 0 // doesn't work for decimal numbers
}

struct CalculatorBrain {
    
    @available(*, deprecated, message: "deprecated")
    var resultIsPending: Bool {
        return evaluate().isPending
    }
    
    @available(*, deprecated, message: "deprecated")
    var description: String? {
        return evaluate().description

    }
    
    private enum Operation {
        case constant(Double)
        case noOperation(() -> Double, String)
        case unaryOperation((Double) -> Double, (String) -> String)
        case binaryOperation((Double, Double) -> Double, (String, String) -> String)
        case equals
    }
    
    mutating func undo() {
        if !stack.isEmpty {
            stack.removeLast()
        }
    }
    
    private var operations: Dictionary<String, Operation> = [
            "π": Operation.constant(Double.pi),
            "e": Operation.constant(M_E),
            "Rand": Operation.noOperation({Double(arc4random()) / Double(UInt32.max)}, "Rand()"),
            "√": Operation.unaryOperation(sqrt, {"√(" + $0 + ")"}),
            "%": Operation.unaryOperation({ $0 / 100 }, {"(" + $0 + "/100)"}),
            "cos": Operation.unaryOperation(cos, {"cos(" + $0 + ")"}),
            "sin": Operation.unaryOperation(sin, {"sin(" + $0 + ")"}),
            "tan": Operation.unaryOperation(tan, {"tan(" + $0 + ")"}),
            "sinh": Operation.unaryOperation(sinh, {"sinh(" + $0 + ")"}),
            "cosh": Operation.unaryOperation(cosh, {"cosh(" + $0 + ")"}),
            "tanh": Operation.unaryOperation(tanh, {"tanh(" + $0 + ")"}),
            "±": Operation.unaryOperation({ -$0 }, {"-(" + $0 + ")"}),
            "x!": Operation.unaryOperation(factorial, {"(" + $0 + ")!"}),
            "^": Operation.binaryOperation({ pow($0, $1) }, {$0 + "^" + $1}),
            "×": Operation.binaryOperation({ $0 * $1 }, {$0 + "×" + $1}),
            "÷": Operation.binaryOperation({ $0 / $1 }, {$0 + "÷" + $1}),
            "-": Operation.binaryOperation({ $0 - $1 }, {$0 + "-" + $1}),
            "+": Operation.binaryOperation({ $0 + $1 }, {$0 + "+" + $1}),
            "=": Operation.equals
    ]
    
    
    private enum PartOfCalculation {
        case variable(String)
        case operation(String)
        case operand(Double)
    }
    private var stack = [PartOfCalculation]()
    
    mutating func setOperand(variable named: String) {
        stack.append(PartOfCalculation.variable(named))
    }
    
    mutating func setOperand(_ operation: String) {
        stack.append(PartOfCalculation.operation(operation))
    }
    
    mutating func setOperand(_ operand: Double) {
        stack.append(PartOfCalculation.operand(operand))
    }
    
    mutating func performOperation(_ symbol: String) {
        stack.append(PartOfCalculation.operation(symbol))
    }
    
    @available(*, deprecated, message: "deprecated")
    var result : Double? {
        return evaluate().result
    }

    
    
    func evaluate(using variables: Dictionary<String,Double>? = nil)
        -> (result: Double?, isPending: Bool, description: String)
    {
        var accumulator: (Double, String)?
        
        var pendingBinaryOperation: PendingBinaryOperation?
        
        struct PendingBinaryOperation {
            let function: (Double, Double) -> Double
            let description: (String, String) -> String
            let firstOperand: (Double, String)
            
            func perform(with secondOperand: (Double, String)) -> (Double, String) {
                return (function(firstOperand.0, secondOperand.0), description(firstOperand.1, secondOperand.1))
            }
        }
        
        func performPendingBinaryOperation() {
            if nil != pendingBinaryOperation && nil != accumulator {
                accumulator = pendingBinaryOperation!.perform(with: accumulator!)
                pendingBinaryOperation = nil
            }
        }
        
        var result: Double? {
            if nil != accumulator {
                return accumulator!.0
            }
            return nil
        }
        
        var description: String? {
            if nil != pendingBinaryOperation {
                return pendingBinaryOperation!.description(pendingBinaryOperation!.firstOperand.1, accumulator?.1 ?? "")
            } else {
                return accumulator?.1
            }
        }
        
        for partOfCalculation in stack {
            switch partOfCalculation {
            case .operand(let value):
                accumulator = (value, "\(value)")
            case .operation(let symbol):
                if let operation = operations[symbol] {
                    switch operation {
                    case .constant(let value):
                        accumulator = (value, symbol)
                    case .unaryOperation(let function, let description):
                        if nil != accumulator {
                            accumulator = (function(accumulator!.0), description(accumulator!.1))
                        }
                    case .binaryOperation(let function, let description):
                        performPendingBinaryOperation()
                        if nil != accumulator {
                            pendingBinaryOperation = PendingBinaryOperation(function: function, description: description, firstOperand: accumulator!)
                            accumulator = nil
                        }
                    case .equals:
                        performPendingBinaryOperation()
                    case .noOperation(let function, let description):
                        accumulator = (function(), description)
                    }
                }
            case .variable(let symbol):
                if let value = variables?[symbol] {
                    accumulator = (value, symbol)
                } else {
                    accumulator = (0, symbol)
                }
            }
        }
        
        return (result, nil != pendingBinaryOperation, description ?? "")
    }
    
    
    
    
    
}
