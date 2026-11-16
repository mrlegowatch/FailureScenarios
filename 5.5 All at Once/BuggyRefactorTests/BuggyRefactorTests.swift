//
//  BuggyRefactorTests.swift
//  BuggyRefactorTests
//
//  Created by Brian Arnold on 6/20/26.
//

import Testing
import Foundation
@testable import BuggyRefactor

// MARK: - Geometry.area

struct GeometryAreaTests {
    @Test func rectangle() {
        #expect(Geometry.rectangle.area(width: 10, height: 5) == 50)
    }

    @Test func circle() {
        // Only width (radius) is used; height is ignored
        #expect(Geometry.circle.area(width: 4, height: 4) == .pi * 16)
    }

    @Test func triangle() {
        #expect(Geometry.triangle.area(width: 6, height: 4) == 12)
    }

    @Test func ellipse() {
        // width=10, height=6 → semiMajorAxis=5, semiMinorAxis=3 → π*5*3
        #expect(Geometry.ellipse.area(width: 10, height: 6) == .pi * 5 * 3)
    }
}

// MARK: - Geometry.perimeter

struct GeometryPerimeterTests {
    @Test func rectangle() {
        #expect(Geometry.rectangle.perimeter(width: 10, height: 5) == 30)
    }

    @Test func circle() {
        // height is ignored; first argument is radius
        #expect(Geometry.circle.perimeter(width: 4, height: 0) == 2 * .pi * 4)
    }

    @Test func triangle() {
        let a: CGFloat = 6, b: CGFloat = 4
        let expected = a + b + (a * a + b * b).squareRoot()
        #expect(Geometry.triangle.perimeter(width: 6, height: 4) == expected)
    }

    @Test func ellipse() {
        // Ramanujan first approximation: π(3(a+b) − √((3a+b)(a+3b)))
        let a: CGFloat = 5, b: CGFloat = 3  // semi-axes for width=10, height=6
        let sum = a + b
        let product = (3 * a + b) * (a + 3 * b)
        let expected = CGFloat.pi * (3 * sum - product.squareRoot())
        #expect(Geometry.ellipse.perimeter(width: 10, height: 6) == expected)
    }
}

// MARK: - ShapeViewModel.computedArea

struct ViewModelComputedAreaTests {
    @Test func rectangle() {
        let data = ShapeData(x: 0, y: 0, width: 10, height: 5, isFilled: true, showsLabel: true, kind: "rectangle")
        #expect(ShapeViewModel(shapeData: data).computedArea() == 50)
    }

    @Test func circle() {
        // width=8, radius=4; area = π * 4²
        let data = ShapeData(x: 0, y: 0, width: 8, height: 8, isFilled: false, showsLabel: true, kind: "circle")
        #expect(ShapeViewModel(shapeData: data).computedArea() == .pi * 16)
    }

    @Test func triangle() {
        let data = ShapeData(x: 0, y: 0, width: 6, height: 4, isFilled: true, showsLabel: true, kind: "triangle")
        #expect(ShapeViewModel(shapeData: data).computedArea() == 12)
    }

    @Test func ellipse() {
        // width=10, height=6 → area = π * 5 * 3
        let data = ShapeData(x: 0, y: 0, width: 10, height: 6, isFilled: true, showsLabel: true, kind: "ellipse")
        #expect(ShapeViewModel(shapeData: data).computedArea() == .pi * 5 * 3)
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

    @Test func ellipse() {
        let data = ShapeData(x: 0, y: 0, width: 10, height: 6, isFilled: true, showsLabel: true, kind: "ellipse")
        let a: CGFloat = 5, b: CGFloat = 3
        let sum = a + b
        let product = (3 * a + b) * (a + 3 * b)
        let expected = CGFloat.pi * (3 * sum - product.squareRoot())
        #expect(ShapeViewModel(shapeData: data).computedPerimeter() == expected)
    }
}

// MARK: - ShapeViewModel.displayLabel

struct DisplayLabelTests {
    @Test func emptyWhenShowsLabelFalse() {
        let data = ShapeData(x: 0, y: 0, width: 10, height: 5, isFilled: true, showsLabel: false, kind: "rectangle")
        let vm = ShapeViewModel(shapeData: data, isSelected: true, isHighlighted: true)
        #expect(vm.displayLabel() == "")
    }

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

    @Test func normalEllipse() {
        // π * 5 * 3 = 15π ≈ 47.1239 → formatted as "47.1"
        let data = ShapeData(x: 0, y: 0, width: 10, height: 6, isFilled: true, showsLabel: true, kind: "ellipse")
        #expect(ShapeViewModel(shapeData: data).displayLabel() == "ellipse area=47.1")
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

    @Test func selectedNotHighlighted() {
        let data = ShapeData(x: 0, y: 0, width: 10, height: 5, isFilled: true, showsLabel: true, kind: "rectangle")
        let vm = ShapeViewModel(shapeData: data, isSelected: true, isHighlighted: false, zoomLevel: 1.5)
        #expect(vm.boundingInset() == 3.0)  // 2.0 * zoom
    }

    @Test func selectedAndHighlighted() {
        let data = ShapeData(x: 0, y: 0, width: 6, height: 4, isFilled: true, showsLabel: true, kind: "triangle")
        let vm = ShapeViewModel(shapeData: data, isSelected: true, isHighlighted: true, zoomLevel: 2.0)
        #expect(vm.boundingInset() == 8.0)  // 4.0 * zoom
    }
}
