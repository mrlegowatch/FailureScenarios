//
//  BaselineTests.swift
//  BaselineTests
//
//  Created by Brian Arnold on 6/20/26.
//

import Testing
import Foundation
@testable import Baseline

// MARK: - Geometry.area

struct GeometryAreaTests {
    @Test func rectangle() {
        #expect(Geometry.rectangle.area(10, 5) == 50)
    }

    @Test func circle() {
        // Only the first argument (radius) is used; second is ignored
        #expect(Geometry.circle.area(4, 4) == .pi * 16)
    }

    @Test func triangle() {
        #expect(Geometry.triangle.area(6, 4) == 12)
    }
}

// MARK: - Geometry.perimeter

struct GeometryPerimeterTests {
    @Test func rectangle() {
        #expect(Geometry.rectangle.perimeter(10, 5) == 30)
    }

    @Test func circle() {
        // Second argument is ignored; first is radius
        #expect(Geometry.circle.perimeter(4, 0) == 2 * .pi * 4)
    }

    @Test func triangle() {
        // Right triangle: perimeter = base + height + hypotenuse
        let a: CGFloat = 6, b: CGFloat = 4
        let expected = a + b + (a * a + b * b).squareRoot()
        #expect(Geometry.triangle.perimeter(6, 4) == expected)
    }
}

// MARK: - ShapeViewModel.computedArea

struct ViewModelComputedAreaTests {
    @Test func rectangle() {
        let data = ShapeData(x: 0, y: 0, width: 10, height: 5, isFilled: true, showsLabel: true, kind: "rectangle")
        #expect(ShapeViewModel(shapeData: data).computedArea() == 50)
    }

    @Test func circle() {
        // width=8, so radius=4; area = π * 4²
        let data = ShapeData(x: 0, y: 0, width: 8, height: 8, isFilled: false, showsLabel: true, kind: "circle")
        #expect(ShapeViewModel(shapeData: data).computedArea() == .pi * 16)
    }

    @Test func triangle() {
        let data = ShapeData(x: 0, y: 0, width: 6, height: 4, isFilled: true, showsLabel: true, kind: "triangle")
        #expect(ShapeViewModel(shapeData: data).computedArea() == 12)
    }
}

// MARK: - ShapeViewModel.computedPerimeter

struct ViewModelComputedPerimeterTests {
    @Test func rectangle() {
        let data = ShapeData(x: 0, y: 0, width: 10, height: 5, isFilled: true, showsLabel: true, kind: "rectangle")
        #expect(ShapeViewModel(shapeData: data).computedPerimeter() == 30)
    }

    @Test func circle() {
        // width=8, radius=4
        let data = ShapeData(x: 0, y: 0, width: 8, height: 8, isFilled: false, showsLabel: true, kind: "circle")
        #expect(ShapeViewModel(shapeData: data).computedPerimeter() == 2 * .pi * 4)
    }

    @Test func triangle() {
        let data = ShapeData(x: 0, y: 0, width: 6, height: 4, isFilled: true, showsLabel: true, kind: "triangle")
        let a: CGFloat = 6, b: CGFloat = 4
        let expected = a + b + (a * a + b * b).squareRoot()
        #expect(ShapeViewModel(shapeData: data).computedPerimeter() == expected)
    }
}

// MARK: - ShapeViewModel.displayLabel

struct DisplayLabelTests {
    // showsLabel = false always returns empty string, regardless of selection state
    @Test func emptyWhenShowsLabelFalse() {
        let data = ShapeData(x: 0, y: 0, width: 10, height: 5, isFilled: true, showsLabel: false, kind: "rectangle")
        let vm = ShapeViewModel(shapeData: data, isSelected: true, isHighlighted: true)
        #expect(vm.displayLabel() == "")
    }

    // Zero or negative dimensions trigger the "empty" path even when showsLabel is true
    @Test func emptyDimensionsWhenWidthIsZero() {
        let data = ShapeData(x: 0, y: 0, width: 0, height: 5, isFilled: true, showsLabel: true, kind: "rectangle")
        #expect(ShapeViewModel(shapeData: data).displayLabel() == "rectangle (empty)")
    }

    @Test func emptyDimensionsWhenHeightIsZero() {
        let data = ShapeData(x: 0, y: 0, width: 10, height: 0, isFilled: false, showsLabel: true, kind: "circle")
        #expect(ShapeViewModel(shapeData: data).displayLabel() == "circle (empty)")
    }

    @Test func normalRectangle() {
        let data = ShapeData(x: 0, y: 0, width: 10, height: 5, isFilled: true, showsLabel: true, kind: "rectangle")
        #expect(ShapeViewModel(shapeData: data).displayLabel() == "rectangle area=50.0")
    }

    @Test func normalCircle() {
        // π * 16 ≈ 50.265 → formatted as "50.3"
        let data = ShapeData(x: 0, y: 0, width: 8, height: 8, isFilled: false, showsLabel: true, kind: "circle")
        #expect(ShapeViewModel(shapeData: data).displayLabel() == "circle area=50.3")
    }

    @Test func normalTriangle() {
        let data = ShapeData(x: 0, y: 0, width: 6, height: 4, isFilled: true, showsLabel: true, kind: "triangle")
        #expect(ShapeViewModel(shapeData: data).displayLabel() == "triangle area=12.0")
    }

    @Test func selectedNotHighlighted() {
        let data = ShapeData(x: 0, y: 0, width: 10, height: 5, isFilled: true, showsLabel: true, kind: "rectangle")
        let vm = ShapeViewModel(shapeData: data, isSelected: true, isHighlighted: false)
        #expect(vm.displayLabel() == "rectangle [selected] area=50.0")
    }

    @Test func selectedAndHighlighted() {
        let data = ShapeData(x: 0, y: 0, width: 6, height: 4, isFilled: true, showsLabel: true, kind: "triangle")
        let vm = ShapeViewModel(shapeData: data, isSelected: true, isHighlighted: true)
        #expect(vm.displayLabel() == "triangle [selected, highlighted] area=12.0")
    }
}

// MARK: - ShapeViewModel.boundingInset

struct BoundingInsetTests {
    // Zero dimensions short-circuit all selection logic and return 0
    @Test func zeroWidthReturnsZero() {
        let data = ShapeData(x: 0, y: 0, width: 0, height: 5, isFilled: true, showsLabel: true, kind: "rectangle")
        let vm = ShapeViewModel(shapeData: data, isSelected: true, isHighlighted: true, zoomLevel: 2.0)
        #expect(vm.boundingInset() == 0.0)
    }

    @Test func zeroHeightReturnsZero() {
        let data = ShapeData(x: 0, y: 0, width: 10, height: 0, isFilled: true, showsLabel: true, kind: "rectangle")
        let vm = ShapeViewModel(shapeData: data, isSelected: true, zoomLevel: 2.0)
        #expect(vm.boundingInset() == 0.0)
    }

    // Not selected: inset depends on isFilled
    @Test func notSelectedFilled() {
        let data = ShapeData(x: 0, y: 0, width: 10, height: 5, isFilled: true, showsLabel: true, kind: "rectangle")
        let vm = ShapeViewModel(shapeData: data, zoomLevel: 1.5)
        #expect(vm.boundingInset() == 1.5)  // 1.0 * zoom
    }

    @Test func notSelectedNotFilled() {
        let data = ShapeData(x: 0, y: 0, width: 8, height: 8, isFilled: false, showsLabel: true, kind: "circle")
        let vm = ShapeViewModel(shapeData: data, zoomLevel: 1.0)
        #expect(vm.boundingInset() == 0.5)  // 0.5 * zoom
    }

    // Selected but not highlighted
    @Test func selectedNotHighlighted() {
        let data = ShapeData(x: 0, y: 0, width: 10, height: 5, isFilled: true, showsLabel: true, kind: "rectangle")
        let vm = ShapeViewModel(shapeData: data, isSelected: true, isHighlighted: false, zoomLevel: 1.5)
        #expect(vm.boundingInset() == 3.0)  // 2.0 * zoom
    }

    // Selected and highlighted
    @Test func selectedAndHighlighted() {
        let data = ShapeData(x: 0, y: 0, width: 6, height: 4, isFilled: true, showsLabel: true, kind: "triangle")
        let vm = ShapeViewModel(shapeData: data, isSelected: true, isHighlighted: true, zoomLevel: 2.0)
        #expect(vm.boundingInset() == 8.0)  // 4.0 * zoom
    }
}
