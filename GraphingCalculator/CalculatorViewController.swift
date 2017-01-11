//
//  ViewController.swift
//  Calculator
//
//  Created by Dean Copeland on 11/21/16.
//  Copyright © 2016 Dean Copeland. All rights reserved.
//

import UIKit

class CalculatorViewController: UIViewController {
    
    override func viewDidLoad() {
        // Share the number formetter with the brain so that the number formatting used in the description from the brain
        // is the same as the number formatting used in display.
        brain.numberFormatter = numberFormatter
    }
    
    private let numberFormatter: NumberFormatter = {
            let nf = NumberFormatter()
            nf.numberStyle = .decimal
            nf.minimumFractionDigits = 0
            nf.maximumFractionDigits = 6
            nf.minimumIntegerDigits = 1
            return nf
        }()

    @IBOutlet private weak var display: UILabel!
    @IBOutlet private weak var sequence: UILabel!
    
    private var brain = CalculatorBrain()
    
    private var userIsInTheMiddleOfTyping = false
    
    @IBAction private func clear(_ sender: UIButton) {
        userIsInTheMiddleOfTyping = false
        display.text = "0"
        sequence.text = " "
        brain.removeVariable(varName: "M")
        brain.clear()
    }
    
    @IBOutlet weak var graphButton: UIButton!
    
    @IBAction func undo() {
        if userIsInTheMiddleOfTyping {
            if let textCurrentlyInDisplay = display.text {
            // remove the last character (digit or ".")
                if !textCurrentlyInDisplay.isEmpty {
                    display.text = String(textCurrentlyInDisplay.characters.dropLast(1))
                    if textCurrentlyInDisplay.characters.count == 1 {
                        userIsInTheMiddleOfTyping = false
                        display.text = "0"
                    }
                }
            }
        } else {
            brain.undo()
            displayBrainResult()
        }
    }
    
    @IBAction private func touchDigit(_ sender: UIButton) {
        let digit = sender.currentTitle!
        if userIsInTheMiddleOfTyping {
            let textCurrentlyInDisplay = display.text!
            // Only accept a maximum of one decimal separator (period)
            if digit == "." {
                if textCurrentlyInDisplay.range(of: ".") == nil {
                    display.text = textCurrentlyInDisplay + digit
                }
            } else {
                display.text = textCurrentlyInDisplay + digit
            }
        } else {
            display.text = digit
        }
        userIsInTheMiddleOfTyping = true
    }
   
    
    @IBAction func setVariable() {
        // Set the "M" variable in the brain
        brain.setVariable(varName: "M", value: displayValue)
        
        displayBrainResult()
    }
    
    @IBAction func getVariable() {
        // Get the "M" varable from the brain
        
        brain.setOperand("M")
        
        displayBrainResult()
    }
    
    // Computed property is used to interface with the brain.
    private var displayValue: Double? {
        get {
            // Used to pass the (String) value being displayed to the brain as a Double
            return Double(display.text!)
        }
        set {
            // Used when we get the numeric value (if any) from the brain and display it 
            // as a String in the display
            if let value = newValue {
                display.text = numberFormatter.string(for: value)
            } else {
                // If the brain returns nil, display "0"
                display.text = "0"
            }
        }
    }
    
    var savedProgram: CalculatorBrain.PropertyList?
    
    @IBAction private func save() {
        savedProgram = brain.program
    }
    
    @IBAction private func restore() {
        if savedProgram != nil {
            brain.program = savedProgram!
            displayBrainResult()
        }
    }
    
    @IBAction private func performOperation(_ sender: UIButton) {
        if userIsInTheMiddleOfTyping {
            // Force unwrapping the displayValue is OK because the user is in the middle of typing
            // (assuming the display string can make a valid Double)
            brain.setOperand(Double(displayValue!))
            userIsInTheMiddleOfTyping = false
        }
        if let mathematicalSymbol = sender.currentTitle {
            brain.performOperation(mathematicalSymbol)
        }
        displayBrainResult()
    }
    
    private func displayBrainResult() {
        displayValue = brain.result
        if displayValue == nil {
            sequence.text = " "
            graphButton.isEnabled = true
        }
        else if brain.isPartialResult {
            sequence.text = "\(brain.description) ..."
            // Disable Graph button
            graphButton.isEnabled = false
        } else {
            sequence.text = "\(brain.description) ="
            // Enable Graph button
            graphButton.isEnabled = true
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier {
            switch identifier {
                case "Show Graph":
                    var destinationVC = segue.destination
                    // If the destination is in a UINavigationController, then 
                    // get the view controller that's inside of it
                    if let navCon = destinationVC as? UINavigationController {
                        destinationVC = navCon.visibleViewController ?? destinationVC
                    }
                    if let vc = destinationVC as? GraphController {
                        // set properties
                        vc.functionToGraph = {
                            self.brain.setVariable(varName: "M", value: $0)
                            return self.brain.result
                        }
                        vc.navigationItem.title = brain.description
                        // Set the scale and origin?
                        // vc.callMethodToSetItUp?
                }
                default: break
            }
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        
         switch identifier {
            // Requirement #3 "Ignore user attempts to graph if isPartialResult is true at the time."
            case "Show Graph":
                return !self.brain.isPartialResult
            default:
                return true
        }
    }
    
}

