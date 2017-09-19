//
//  ViewController.swift
//  Calculator
//
//  Created by Michael Blankenship on 8/28/17.
//  Copyright © 2017 Michael Blankenship. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var memoryOnDisplay: UILabel!
    @IBOutlet weak var display: UILabel!
    @IBOutlet weak var descriptionBeingShown: UILabel!
    @IBAction func clearAll(_ sender: UIButton) {
        brain = CalculatorBrain()
        descriptionBeingShown.text = " "
        displayValue = 0
        userIsTyping = false
        variables = Dictionary<String,Double>()
    }
    
    @IBAction func undo(_ sender: UIButton) {
        if userIsTyping, var text = display.text {
            text.remove(at: text.index(before: text.endIndex))
            if text.isEmpty {
                text = "0"
                userIsTyping = false
            }
            display.text = text
        } else {
            brain.undo()
            displayResult()
        }
    }
    
    private var variables = Dictionary<String,Double>() {
        didSet {
            memoryOnDisplay.text = variables.flatMap{$0+":\($1)"}.joined(separator: ", ").formatZeroes()
        }
    }
    
    @IBAction func getFromMemory(_ sender: UIButton) {
        brain.setOperand(variable: "M")
        userIsTyping = false
        displayResult()
    }
   
    @IBAction func storeInMemory(_ sender: UIButton) {
        variables["M"] = displayValue
        userIsTyping = false
        displayResult()
    }
    
    
    var userIsTyping = false
    var displayValue: Double {
        get {
            return Double(display.text!)!
        }
        set {
            display.text = String(newValue).formatZeroes()
        }
    }
    
    @IBAction func touchDigit(_ sender: UIButton) {
        let digit = sender.currentTitle!
        if userIsTyping {
            let textInDisplay = display.text!
            if !textInDisplay.contains(".") || digit != "." {
                display.text = textInDisplay + digit
                
            }
        } else {
            if digit == "." {
                display.text = "0."
            } else {
                display.text = digit
            }
            userIsTyping = true
        }
        
        //print("\(digit) was touched")
    }
    
    private var brain = CalculatorBrain()
    
    private func displayResult() {
        let evaluated = brain.evaluate(using: variables)
        if let result = evaluated.result {
            displayValue = result
        }
        if "" != evaluated.description {
            descriptionBeingShown.text = evaluated.description.formatZeroes() + (evaluated.isPending ? "…" : "=")
        } else {
            descriptionBeingShown.text = " "
        }
    }
    
    @IBAction func performOperation(_ sender: UIButton) {
        if userIsTyping {
            brain.setOperand(displayValue)
        }
        userIsTyping = false
        if let mathSymbol = sender.currentTitle {
            brain.performOperation(mathSymbol)
        }
        let evaluatedResult = brain.evaluate()
        if let result = evaluatedResult.result {
            displayValue = result
        }
        if evaluatedResult.description != "" {
            descriptionBeingShown.text = evaluatedResult.description.formatZeroes() + (evaluatedResult.isPending ? "…" : "=")
        } else {
            descriptionBeingShown.text = " "
        }
        displayResult()
    }
    
}

extension String {
    func formatZeroes() -> String {
        return self.replace(pattern: "\\.0+([^0-9]|$)", with: "$1")
    }
    
    func replace(pattern: String, with replacement: String) -> String {
        let regex = try! NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let range = NSMakeRange(0, self.characters.count)
        return regex.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: replacement)
    }
}

