//
//  Shapes.swift
//  Change1
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
    
    init(kind: String) {
        self = Geometry(rawValue: kind) ?? .rectangle
    }
    
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

extension ShapeData {
    var geometry: Geometry { .init(kind: kind) }
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
        let geometry = shapeData.geometry
        switch geometry {
        case .rectangle:
            return geometry.area(shapeData.width, shapeData.height)
        case .circle:
            // radius is half of width; second arg is unused but must be passed
            return geometry.area(shapeData.width / 2, shapeData.width / 2)
        case .triangle:
            return geometry.area(shapeData.width, shapeData.height)
        }
    }

    func computedPerimeter() -> CGFloat {
        let geometry = shapeData.geometry
        switch geometry {
        case .rectangle:
            return geometry.perimeter(shapeData.width, shapeData.height)
        case .circle:
            // pass radius as first arg, 0 as placeholder second arg
            return geometry.perimeter(shapeData.width / 2, 0)
        case .triangle:
            return geometry.perimeter(shapeData.width, shapeData.height)
        }
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
