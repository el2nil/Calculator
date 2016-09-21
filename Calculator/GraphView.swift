//
//  Graph.swift
//  Calculator
//
//  Created by Danil Denshin on 25.08.16.
//  Copyright © 2016 el2Nil. All rights reserved.
//

import UIKit

//@IBDesignable
class GraphView: UIView {
	
	// MARK: Variables
	
	var functionForDraw: ((_ x: Double) -> Double?)? { didSet { setNeedsDisplay() } }
	var lineWidth: CGFloat = 1
	fileprivate var drawOnlyAxes = false
	
	fileprivate let axesDrawer = AxesDrawer(color: UIColor.black)
	
	fileprivate var origin: CGPoint! {
		get {
			var origin = graphCentre
			origin.x += originOffset.x
			origin.y += originOffset.y
			return origin
		}
		set {
			if var origin = newValue {
				origin.x -= graphCentre.x
				origin.y -= graphCentre.y
				originOffset = origin
			} else {
				originOffset = CGPoint(x: 0, y: 0)
			}
		}
	}
	var originOffset = CGPoint.zero { didSet { setNeedsDisplay() } }
	fileprivate var graphCentre: CGPoint { return convert(center, from: superview) }
	
	@IBInspectable var scale: CGFloat = 1.0 { didSet {	setNeedsDisplay() }	}
	
	// MARK: Draw
	
	override func draw(_ rect: CGRect) {
		
		if origin == nil {
			origin = CGPoint(x: bounds.midX, y: bounds.midY)
		}
		
		axesDrawer.contentScaleFactor = contentScaleFactor
		axesDrawer.drawAxesInRect(bounds, origin: origin, pointsPerUnit: scale)
		
		//		functionForDraw = { return sin($0) / cos($0) }
		
		if !drawOnlyAxes {
			drawFunctionInRect(bounds, origin: origin, scale: scale)
		}
		
		
	}
	
	func drawFunctionInRect(_ bounds: CGRect, origin: CGPoint, scale: CGFloat)
	{
		UIColor.blue.set()
		
		if functionForDraw == nil {
			return
		}
		
		var xGraph: CGFloat = 0
		var yGraph: CGFloat = 0
		
		struct GraphPoint {
			var yGraph: CGFloat
			var isNormal: Bool
		}
		
		var lastPoint = GraphPoint(yGraph: 0.0, isNormal: false)
		var isJumpOfFunction: Bool {
			return abs(yGraph - lastPoint.yGraph) > max(bounds.height, bounds.width) * 2
		}
		
		var x: Double {
			return Double((xGraph - origin.x) / scale)
		}
		
		let path = UIBezierPath()
		path.lineWidth = lineWidth
		
		
		for i in 0...Int(bounds.size.width * contentScaleFactor) {
			
			xGraph = CGFloat(i) / contentScaleFactor
			
			guard let y = functionForDraw?(x) , y.isFinite else { lastPoint.isNormal = false; continue  }
			
			yGraph = origin.y - CGFloat(y) * scale
			
			let newPoint = CGPoint(x: xGraph, y: yGraph)
			
			if !lastPoint.isNormal {
				path.move(to: newPoint)
			} else {
				guard !isJumpOfFunction else {
					lastPoint = GraphPoint(yGraph: yGraph, isNormal: false)
					continue
				}
				path.addLine(to: newPoint)
			}
			
			lastPoint = GraphPoint(yGraph: yGraph, isNormal: true)
		}
		path.stroke()
	}
	
	// MARK: Inits
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		addGuestures()
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		addGuestures()
	}
	
	// MARK: Guestures
	fileprivate func addGuestures() {
		self.addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: #selector(GraphView.changeScale(_:))))
		
		let tapForSetOriginRecognizer = UITapGestureRecognizer(target: self, action: #selector(GraphView.tapForSetOrigin(_:)))
		tapForSetOriginRecognizer.numberOfTapsRequired = 2
		self.addGestureRecognizer(tapForSetOriginRecognizer)
		
		self.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(GraphView.panForSetOrigin(_:))))
	}
	
	fileprivate var snapshot: UIView!
	
	func changeScale(_ recognizer: UIPinchGestureRecognizer) {
		switch recognizer.state {
		case .began:
			snapshot = self.snapshotView(afterScreenUpdates: false)
			snapshot.alpha = 0.8
			self.addSubview(snapshot)
		case .changed:
			let touch = recognizer.location(in: self)
			snapshot.frame.size.height *= recognizer.scale
			snapshot.frame.size.width *= recognizer.scale
			snapshot.frame.origin.x = snapshot.frame.origin.x * recognizer.scale + (1 - recognizer.scale) * touch.x
			snapshot.frame.origin.y = snapshot.frame.origin.y * recognizer.scale + (1 - recognizer.scale) * touch.y
			recognizer.scale = 1.0
		case .ended:
			let changedScale = snapshot.frame.height / self.bounds.height
			scale *= changedScale
			origin.x = origin.x * changedScale + snapshot.frame.origin.x
			origin.y = origin.y * changedScale + snapshot.frame.origin.y
			snapshot.removeFromSuperview()
			snapshot = nil
			setNeedsDisplay()
		default: break
		}
	}
	
	func tapForSetOrigin(_ recognizer: UITapGestureRecognizer) {
		if recognizer.state == .ended {
			origin = recognizer.location(in: self)
		}
	}
	
	func panForSetOrigin(_ recognizer: UIPanGestureRecognizer) {
		switch recognizer.state {
		case .began:
			drawOnlyAxes = true
			snapshot = self.snapshotView(afterScreenUpdates: false)
			snapshot!.alpha = 0.4
			self.addSubview(snapshot!)
		case .changed:
			let translation = recognizer.translation(in: self)
			snapshot!.center.x += translation.x
			snapshot!.center.y += translation.y
			recognizer.setTranslation(CGPoint(x: 0.0, y: 0.0), in: self)
		case .ended:
			origin.x += snapshot!.frame.origin.x
			origin.y += snapshot!.frame.origin.y
			drawOnlyAxes = false
			snapshot!.removeFromSuperview()
			snapshot = nil
			setNeedsDisplay()
		default: break
		}
	}
	
	// MARK: Other
	
	override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		super.traitCollectionDidChange(previousTraitCollection)
		origin = nil
	}
	
	
	
	
}
