//
//  main.swift
//  Change2
//
//  Created by Brian Arnold on 6/20/26.
//

import Foundation

// --- Shape Driver ---
print("=== Change2 Shape Driver ===")
print()

// Rectangle: 10×5, filled, showsLabel, selected (not highlighted), zoom=1.5
let rectData = ShapeData(x: 10, y: 20, width: 10, height: 5, isFilled: true, showsLabel: true, kind: "rectangle")
let rectVM = ShapeViewModel(shapeData: rectData, isSelected: true, isHighlighted: false, zoomLevel: 1.5)
print("Rectangle (10x5, filled, selected, zoom=1.5)")
print("  computedArea:      \(rectVM.computedArea)")
print("  computedPerimeter: \(rectVM.computedPerimeter)")
print("  displayLabel:      '\(rectVM.displayLabel())'")
print("  boundingInset:     \(rectVM.boundingInset())")
print()

// Circle: diameter=8 (radius=4), not filled, showsLabel, not selected, zoom=1.0
let circleData = ShapeData(x: 5, y: 5, width: 8, height: 8, isFilled: false, showsLabel: true, kind: "circle")
let circleVM = ShapeViewModel(shapeData: circleData)
print("Circle (diameter=8, not filled, not selected, zoom=1.0)")
print("  computedArea:      \(String(format: "%.4f", circleVM.computedArea))")
print("  computedPerimeter: \(String(format: "%.4f", circleVM.computedPerimeter))")
print("  displayLabel:      '\(circleVM.displayLabel())'")
print("  boundingInset:     \(circleVM.boundingInset())")
print()

// Triangle: base=6, height=4, filled, showsLabel, selected+highlighted, zoom=2.0
let triangleData = ShapeData(x: 0, y: 0, width: 6, height: 4, isFilled: true, showsLabel: true, kind: "triangle")
let triangleVM = ShapeViewModel(shapeData: triangleData, isSelected: true, isHighlighted: true, zoomLevel: 2.0)
print("Triangle (base=6, height=4, filled, selected+highlighted, zoom=2.0)")
print("  computedArea:      \(triangleVM.computedArea)")
print("  computedPerimeter: \(String(format: "%.4f", triangleVM.computedPerimeter))")
print("  displayLabel:      '\(triangleVM.displayLabel())'")
print("  boundingInset:     \(triangleVM.boundingInset())")
