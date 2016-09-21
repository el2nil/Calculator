//
//  GraphViewController.swift
//  Calculator
//
//  Created by Danil Denshin on 25.08.16.
//  Copyright © 2016 el2Nil. All rights reserved.
//

import UIKit

class GraphViewController: UIViewController {
	
	@IBOutlet weak var graphView: GraphView! {
		didSet {
			graphView.originOffset = originOffset
			graphView.scale = scale
		}
	}
	
	
	var functionForDraw: ((_ x: Double) -> Double?)? {
		didSet {
			if let graphView = graphView {
				graphView.functionForDraw = functionForDraw
			}
		}
	}
	
	let defaults = UserDefaults.standard
	fileprivate struct Keys {
		static let Origin = "GraphViewControler.Origin"
		static let Scale = "GraphviewController.Scale"
	}
	
	fileprivate var scale: CGFloat {
		get { return defaults.object(forKey: Keys.Scale) as? CGFloat ?? CGFloat(1.0) }
		set { defaults.set(newValue, forKey: Keys.Scale) }
	}
	
	fileprivate var originOffset: CGPoint {
		get {
			let originArray = defaults.object(forKey: Keys.Origin) as? [CGFloat]
			let factor = CGPoint(x: originArray?.first ?? CGFloat(0.0), y: originArray?.last ?? CGFloat(0.0))
			return CGPoint(x: graphView.bounds.size.width * factor.x, y: graphView.bounds.size.height * factor.y)
		}
		set {
			let factor = CGPoint(x: newValue.x / graphView.bounds.size.width,
			                     y: newValue.y / graphView.bounds.size.height)
			defaults.set([factor.x, factor.y], forKey: Keys.Origin)
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		graphView.functionForDraw = functionForDraw
		
	}
	
	fileprivate var oldWidth: CGFloat = 0
	
	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		oldWidth = graphView.bounds.size.width
		originOffset = graphView.originOffset
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		if oldWidth != graphView.bounds.size.width {
			graphView.originOffset = originOffset
		}
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		originOffset = graphView.originOffset
		scale = graphView.scale
	}
	
}
