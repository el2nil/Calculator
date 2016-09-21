//
//  Graph.swift
//  Calculator
//
//  Created by Danil Denshin on 25.08.16.
//  Copyright © 2016 el2Nil. All rights reserved.
//

import UIKit

@IBDesignable
class GraphView: UIView {
	
	// MARK: Variables
	
	var functionForDraw: ((x: Double) -> Double?)? { didSet { setNeedsDisplay() } }
	var lineWidth: CGFloat = 1
	private var drawOnlyAxes = false
	
	private let axesDrawer = AxesDrawer(color: UIColor.blackColor())
	
	private var origin: CGPoint! {
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
	var originOffset = CGPointZero { didSet { setNeedsDisplay() } }
	private var graphCentre: CGPoint { return convertPoint(center, fromView: superview) }
	
	@IBInspectable var scale: CGFloat = 1.0 { didSet {	setNeedsDisplay() }	}
	
	// MARK: Draw
	
	override func drawRect(rect: CGRect) {
		
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
	
	func drawFunctionInRect(bounds: CGRect, origin: CGPoint, scale: CGFloat)
	{
		UIColor.blueColor().set()
		
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
			
			guard let y = functionForDraw?(x: x) where y.isFinite else { lastPoint.isNormal = false; continue  }
			
			yGraph = origin.y - CGFloat(y) * scale
			
			let newPoint = CGPoint(x: xGraph, y: yGraph)
			
			if !lastPoint.isNormal {
				path.moveToPoint(newPoint)
			} else {
				guard !isJumpOfFunction else {
					lastPoint = GraphPoint(yGraph: yGraph, isNormal: false)
					continue
				}
				path.addLineToPoint(newPoint)
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
	private func addGuestures() {
		self.addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: #selector(GraphView.changeScale(_:))))
		
		let tapForSetOriginRecognizer = UITapGestureRecognizer(target: self, action: #selector(GraphView.tapForSetOrigin(_:)))
		tapForSetOriginRecognizer.numberOfTapsRequired = 2
		self.addGestureRecognizer(tapForSetOriginRecognizer)
		
		self.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(GraphView.panForSetOrigin(_:))))
	}
	
	private var snapshot: UIView!
	
	func changeScale(recognizer: UIPinchGestureRecognizer) {
		switch recognizer.state {
		case .Began:
			snapshot = self.snapshotViewAfterScreenUpdates(false)
			snapshot.alpha = 0.8
			self.addSubview(snapshot)
		case .Changed:
			let touch = recognizer.locationInView(self)
			snapshot.frame.size.height *= recognizer.scale
			snapshot.frame.size.width *= recognizer.scale
			snapshot.frame.origin.x = snapshot.frame.origin.x * recognizer.scale + (1 - recognizer.scale) * touch.x
			snapshot.frame.origin.y = snapshot.frame.origin.y * recognizer.scale + (1 - recognizer.scale) * touch.y
			recognizer.scale = 1.0
		case .Ended:
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
	
	func tapForSetOrigin(recognizer: UITapGestureRecognizer) {
		if recognizer.state == .Ended {
			origin = recognizer.locationInView(self)
		}
	}
	
	func panForSetOrigin(recognizer: UIPanGestureRecognizer) {
		switch recognizer.state {
		case .Began:
			drawOnlyAxes = true
			snapshot = self.snapshotViewAfterScreenUpdates(false)
			snapshot!.alpha = 0.4
			self.addSubview(snapshot!)
		case .Changed:
			let translation = recognizer.translationInView(self)
			snapshot!.center.x += translation.x
			snapshot!.center.y += translation.y
			recognizer.setTranslation(CGPoint(x: 0.0, y: 0.0), inView: self)
		case .Ended:
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
	
	override func traitCollectionDidChange(previousTraitCollection: UITraitCollection?) {
		super.traitCollectionDidChange(previousTraitCollection)
		origin = nil
	}
	
	
	
	
}
