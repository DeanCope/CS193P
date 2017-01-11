//
//  GraphController.swift
//  GraphingCalculator
//
//  Created by Dean Copeland on 1/4/17.
//  Copyright © 2017 Dean Copeland. All rights reserved.
//

import UIKit

class GraphController: UIViewController {
    
    var functionToGraph: ((Double) -> Double)? {
        didSet {
            updateUI()
        }
    }
    
    @IBOutlet weak var graphView: GraphView! {
        didSet {
            graphView.addGestureRecognizer(UIPinchGestureRecognizer(target: graphView, action: #selector(graphView.changeScale(recognizer:))))
            graphView.addGestureRecognizer(UIPanGestureRecognizer(target: graphView, action: #selector(graphView.moveGraphOrigin(recognizer:))))
            let tapRecognizer = UITapGestureRecognizer(target: graphView, action: #selector(graphView.moveGraphOrigin(recognizer:)))
            tapRecognizer.numberOfTapsRequired = 2
            graphView.addGestureRecognizer(tapRecognizer)
            updateUI()
        }
    }
    
    private func updateUI() {
        if graphView != nil {
            graphView.functionToGraph = functionToGraph
        }
    }
    
}
