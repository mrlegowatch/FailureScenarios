//
//  Shapes.swift
//  Change2
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
    
    func area(width: CGFloat, height: CGFloat) -> CGFloat {
        switch self {
        case .rectangle:
            return width * height
        case .circle:
            let radius = width / 2
            return .pi * radius * radius
        case .triangle:
            return 0.5 * width * height
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
        }
    }
}

extension ShapeData {
    var geometry: Geometry { .init(kind: kind) }
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
        if shapeData.showsLabel {
            if shapeData.width > 0 && shapeData.height > 0 {
                if isSelected {
                    if isHighlighted {
                        return "\(shapeData.kind) [selected, highlighted] area=\(String(format: "%.1f", shapeData.computedArea))"
                    } else {
                        return "\(shapeData.kind) [selected] area=\(String(format: "%.1f", shapeData.computedArea))"
                    }
                } else {
                    return "\(shapeData.kind) area=\(String(format: "%.1f", shapeData.computedArea))"
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
