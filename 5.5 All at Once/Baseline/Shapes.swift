//
//  Shapes.swift
//  Baseline
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

enum Geometry {
    case rectangle
    case circle
    case triangle

    // For .rectangle: a = width, b = height  → returns w * h
    // For .circle:    a = radius, b = radius (only a is used)  → returns π * a²
    // For .triangle:  a = base, b = height  → returns 0.5 * a * b
    func area(_ a: CGFloat, _ b: CGFloat) -> CGFloat {
        switch self {
        case .rectangle:
            return a * b
        case .circle:
            return .pi * a * a
        case .triangle:
            return 0.5 * a * b
        }
    }

    // For .rectangle: a = width, b = height  → returns 2 * (a + b)
    // For .circle:    a = radius, b = 0 (b is ignored)  → returns 2 * π * a
    // For .triangle:  a = base, b = height (right triangle)  → returns a + b + hypotenuse
    func perimeter(_ a: CGFloat, _ b: CGFloat) -> CGFloat {
        switch self {
        case .rectangle:
            return 2 * (a + b)
        case .circle:
            return 2 * .pi * a
        case .triangle:
            return a + b + (a * a + b * b).squareRoot()
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

    func geometryKind() -> Geometry {
        if shapeData.kind == "rectangle" {
            return .rectangle
        }
        if shapeData.kind == "circle" {
            return .circle
        }
        if shapeData.kind == "triangle" {
            return .triangle
        }
        return .rectangle
    }

    func computedArea() -> CGFloat {
        let geom = geometryKind()
        if shapeData.kind == "rectangle" {
            return geom.area(shapeData.height, shapeData.width)
        }
        if shapeData.kind == "circle" {
            // radius is half of width; second arg is unused but must be passed
            return geom.area(shapeData.width / 2, shapeData.width / 2)
        }
        if shapeData.kind == "triangle" {
            return geom.area(shapeData.width, shapeData.height)
        }
        return 0
    }

    func computedPerimeter() -> CGFloat {
        let geom = geometryKind()
        if shapeData.kind == "rectangle" {
            return geom.perimeter(shapeData.width, shapeData.height)
        }
        if shapeData.kind == "circle" {
            // pass radius as first arg, 0 as placeholder second arg
            return geom.perimeter(shapeData.width / 2, 0)
        }
        if shapeData.kind == "triangle" {
            return geom.perimeter(shapeData.width, shapeData.height)
        }
        return 0
    }

    func displayLabel() -> String {
        if shapeData.showsLabel {
            if shapeData.width > 0 && shapeData.height > 0 {
                if isSelected {
                    if isHighlighted {
                        return "\(shapeData.kind) [selected, highlighted] area=\(String(format: "%.1f", computedArea()))"
                    } else {
                        return "\(shapeData.kind) [selected] area=\(String(format: "%.1f", computedArea()))"
                    }
                } else {
                    return "\(shapeData.kind) area=\(String(format: "%.1f", computedArea()))"
                }
            } else {
                return "\(shapeData.kind) (empty)"
            }
        } else {
            return ""
        }
    }

    func boundingInset() -> CGFloat {
        if shapeData.width > 0 && shapeData.height > 0 {
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
        } else {
            return 0.0
        }
    }
}
