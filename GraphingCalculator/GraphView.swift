//
//  GraphView.swift
//  GraphingCalculator
//
//  Created by Dean Copeland on 1/6/17.
//  Copyright © 2017 Dean Copeland. All rights reserved.
//

import UIKit

@IBDesignable
class GraphView: UIView {
    
    // - MARK: Public, inspectable attributes
    // Note: IBInspectables must be explicitly typed (not inferred)

    @IBInspectable
    var pointsPerUnit: CGFloat = 50.0 {didSet{setNeedsDisplay()}}
    
    @IBInspectable
    var color: UIColor = UIColor.black {didSet {setNeedsDisplay()}}
    
    @IBInspectable
    var lineWidth: CGFloat = 1.0 {didSet {setNeedsDisplay()}}
    
    
    // - MARK: Gesture handlers
    func changeScale(recognizer: UIPinchGestureRecognizer) {
        switch recognizer.state {
        case .changed, .ended:
            pointsPerUnit *= recognizer.scale
            recognizer.scale = 1.0
            setNeedsDisplay()
        default: break
        }
    }
    
    func panGraphOrigin(recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        case .changed, .ended:
            let translation = recognizer.translation(in: self)
            graphOrigin.x += translation.x
            graphOrigin.y += translation.y
            recognizer.setTranslation(CGPoint.zero, in: self)
            setNeedsDisplay()
        default: break
        }
    }
    
    func moveGraphOrigin(recognizer: UITapGestureRecognizer) {
        switch recognizer.state {
        case .changed, .ended:
            let point = recognizer.location(in: self)
            graphOrigin.x = point.x
            graphOrigin.y = point.y
            setNeedsDisplay()
        default: break
        }
    }

    
    // Function that takes the X value and returns the Y value
    var functionToGraph: ((Double) -> Double?)? = {
        // Default function "just for fun" to show in the Storyboard
        return sin($0)
    }
    
    private var graphOriginOverride: CGPoint?
    
    private var graphOrigin: CGPoint {
        get{
            // If there's no override, then use the center of the view
            return graphOriginOverride ?? CGPoint(x: bounds.midX, y: bounds.midY)
            
        }
        set {
            graphOriginOverride = newValue
            setNeedsDisplay()
        }
        
    }
    
    override func draw(_ rect: CGRect) {
        
        let axesDrawer = AxesDrawer(contentScaleFactor: contentScaleFactor) //UIScreen.main.scale)
        
        axesDrawer.drawAxesInRect(bounds: bounds, origin: graphOrigin, pointsPerUnit: pointsPerUnit)
        
        if let function = functionToGraph {
            let graphLine = UIBezierPath()
            
            var previousPointWasNotNormal = true
            
            //    var xValueToPlot = bounds.minX - abs(graphOrigin.x) / pointsPerUnit
            // e.g. (0 - 351.75) / 50 = -2.36
            
            let totalXPixels = (bounds.maxX - bounds.minX) * UIScreen.main.scale
            
            // xValue to CGPoint: (xValue * pointsPerUnit) + graphOrigin.x
            // CGPoint to pixels:  xCG * UIScreen.main.scale
            // pixels to CGPoint: pixels / UIScreen.main.scale
            for xPixel in 1...Int(totalXPixels) {
                let xDouble = Double(((CGFloat(xPixel) / contentScaleFactor) - graphOrigin.x) / pointsPerUnit)
                if let yDouble = function(xDouble) {
                    if yDouble.isNormal || yDouble.isZero {
                        // Since we're looping pixel-by-pixel, the x value is already pixel-aligned.
                        // Only the y value needs to be pixel aligned
                        let newPoint = CGPoint(
                            x: (CGFloat(xDouble) * pointsPerUnit) + graphOrigin.x,
                            y: align(coordinate: graphOrigin.y - (CGFloat(yDouble) * pointsPerUnit))
                        )
                        if previousPointWasNotNormal {
                            graphLine.move(to: newPoint)
                            previousPointWasNotNormal = false
                        } else {
                            graphLine.addLine(to: newPoint)
                        }
                        
                    } else {
                        previousPointWasNotNormal = true
                    }
                }
            }

            graphLine.lineWidth = lineWidth
            color.setStroke()
            graphLine.stroke()
        }
    }
    
    private func align(coordinate: CGFloat) -> CGFloat {
        return round(coordinate * contentScaleFactor) / contentScaleFactor
    }
}
