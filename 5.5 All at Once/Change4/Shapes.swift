//
//  Shapes.swift
//  Change4
//
//  Created by Brian Arnold on 6/20/26.
//

import Foundation

struct ShapeData {
    var x: CGFloat
    var y: CGFloat
    var width: CGFloat
    var height: CGFloat
    var isFilled: Bool
    var showsLabel: Bool
    var kind: String  // "rectangle", "circle", "triangle"
}

enum Geometry: String {
    case rectangle
    case circle
    case triangle
    case ellipse
    
    init(kind: String) {
        self = Geometry(rawValue: kind) ?? .rectangle
    }
    
    func area(width: CGFloat, height: CGFloat) -> CGFloat {
        switch self {
        case .rectangle:
            return width * height
        case .circle:
            let radius = width / 2
            return .pi * radius * radius
        case .triangle:
            return 0.5 * width * height
        case .ellipse:
            let semiMajorAxis = width / 2
            let semiMinorAxis = height / 2
            return .pi * semiMajorAxis * semiMinorAxis
        }
    }

    func perimeter(width: CGFloat, height: CGFloat) -> CGFloat {
        switch self {
        case .rectangle:
            return 2 * (width + height)
        case .circle:
            return .pi * width
        case .triangle:
            return width + height + (width * width + height * height).squareRoot()
        case .ellipse:
            let semiMajorAxis = width / 2
            let semiMinorAxis = height / 2
            let sum = semiMajorAxis + semiMinorAxis
            let product = (3 * semiMajorAxis + semiMinorAxis) * (semiMajorAxis + 3 * semiMinorAxis)
            return .pi * (3 * sum - product.squareRoot())
        }
    }
}

extension ShapeData {
    var geometry: Geometry { .init(kind: kind) }
    var isEmpty: Bool { width <= 0 || height <= 0 }
    var computedArea: CGFloat { geometry.area(width: width, height: height) }
    var computedPerimeter: CGFloat { geometry.perimeter(width: width, height: height) }
}

class ShapeViewModel {
    var shapeData: ShapeData
    var isSelected: Bool
    var isHighlighted: Bool
    var zoomLevel: CGFloat

    init(shapeData: ShapeData, isSelected: Bool = false, isHighlighted: Bool = false, zoomLevel: CGFloat = 1.0) {
        self.shapeData = shapeData
        self.isSelected = isSelected
        self.isHighlighted = isHighlighted
        self.zoomLevel = zoomLevel
    }

    var computedArea: CGFloat { shapeData.computedArea }
    var computedPerimeter: CGFloat { shapeData.computedPerimeter }
    
    func displayLabel() -> String {
        guard shapeData.showsLabel else { return "" }
        guard !shapeData.isEmpty else { return "\(shapeData.kind) (empty)" }
        if isSelected {
            if isHighlighted {
                return "\(shapeData.kind) [selected, highlighted] area=\(String(format: "%.1f", shapeData.computedArea))"
            } else {
                return "\(shapeData.kind) [selected] area=\(String(format: "%.1f", shapeData.computedArea))"
            }
        } else {
            return "\(shapeData.kind) area=\(String(format: "%.1f", shapeData.computedArea))"
        }
    }

    func boundingInset() -> CGFloat {
        guard !shapeData.isEmpty else { return 0.0 }
        if isSelected {
            return isHighlighted ? 4.0 * zoomLevel : 2.0 * zoomLevel
        } else {
            return shapeData.isFilled ? 1.0 * zoomLevel : 0.5 * zoomLevel
        }
    }
}
