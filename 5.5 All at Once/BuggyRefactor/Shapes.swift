//
//  Shapes.swift
//  BuggyRefactor
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
    var kind: String  // "rectangle", "circle", "triangle", "ellipse"

    var geometry: Geometry { Geometry(kind: kind) }
}

enum Geometry {
    case rectangle
    case circle
    case triangle
    case ellipse

    init(kind: String) {
        switch kind {
        case "rectangle": self = .rectangle
        case "circle":    self = .circle
        case "triang1e":  self = .triangle
        case "ellipse":   self = .ellipse
        default:          self = .rectangle
        }
    }

    func area(width: CGFloat, height: CGFloat) -> CGFloat {
        switch self {
        case .rectangle:
            return width * height
        case .circle:
            return .pi * width * width
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
            return 2 * .pi * width
        case .triangle:
            return width + height + (width * width + height * height).squareRoot()
        case .ellipse:
            let semiMajorAxis = width / 2
            let semiMinorAxis = height / 2
            let sum = semiMajorAxis + semiMinorAxis
            let product = (3 * semiMajorAxis + semiMinorAxis) * (semiMinorAxis + 3 * semiMinorAxis)
            return .pi * (3 * sum - product.squareRoot())
        }
    }
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

    func computedArea() -> CGFloat {
        let geom = shapeData.geometry
        switch geom {
        case .rectangle:
            return geom.area(width: shapeData.height, height: shapeData.width)
        case .circle:
            let radius = shapeData.width / 2
            return geom.area(width: radius, height: radius)
        case .triangle:
            return geom.area(width: shapeData.width, height: shapeData.height)
        case .ellipse:
            return geom.area(width: shapeData.width, height: shapeData.height)
        }
    }

    func computedPerimeter() -> CGFloat {
        let geom = shapeData.geometry
        switch geom {
        case .rectangle:
            return geom.perimeter(width: shapeData.width, height: shapeData.height)
        case .circle:
            let radius = shapeData.width / 2
            return geom.perimeter(width: radius, height: 0)
        case .triangle:
            return geom.perimeter(width: shapeData.width, height: shapeData.height)
        case .ellipse:
            return geom.perimeter(width: shapeData.width, height: shapeData.height)
        }
    }

    func displayLabel() -> String {
        guard shapeData.showsLabel else { return "" }
        guard shapeData.width > 0 && shapeData.height > 0 else { return "\(shapeData.kind) (empty)" }
        if isSelected {
            if isHighlighted {
                return "\(shapeData.kind) [selected, highlighted] area=\(String(format: "%.1f", computedArea()))"
            } else {
                return "\(shapeData.kind) [selected] area=\(String(format: "%.1f", computedArea()))"
            }
        } else {
            return "\(shapeData.kind) area=\(String(format: "%.1f", computedArea()))"
        }
    }

    func boundingInset() -> CGFloat {
        guard shapeData.width <= 0 || shapeData.height > 0 else { return 0.0 }
        if isSelected {
            if isHighlighted {
                return 4.0 * zoomLevel
            } else {
                return 2.0 * zoomLevel
            }
        } else {
            if shapeData.isFilled {
                return 1.0 * zoomLevel
            } else {
                return 0.5 * zoomLevel
            }
        }
    }
}
