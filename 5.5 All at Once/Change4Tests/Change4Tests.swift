//
//  Change4Tests.swift
//  Change4Tests
//
//  Created by Brian Arnold on 6/20/26.
//

import Testing
import Foundation
@testable import Change4

@Suite("Change 4 — Geometry.ellipse case")
struct Change4Tests {

    // MARK: Geometry.init(kind:) maps "ellipse" to .ellipse

    @Test func kindEllipseMapsToEllipse() {
        #expect(Geometry(kind: "ellipse") == .ellipse)
    }

    // MARK: Geometry.ellipse.area(width:height:)

    @Test func ellipseArea() {
        // width=10, height=6: semiMajorAxis=5, semiMinorAxis=3 → π × 5 × 3
        #expect(Geometry.ellipse.area(width: 10, height: 6) == .pi * 5 * 3)
    }

    @Test func ellipseAreaDegeneratesForCircle() {
        // When width == height (a == b), result should match the circle area formula
        #expect(Geometry.ellipse.area(width: 8, height: 8) == .pi * 16)
    }

    // MARK: Geometry.ellipse.perimeter(width:height:) — Ramanujan approximation

    @Test func ellipsePerimeter() {
        // Ramanujan: π(3(a+b) − √((3a+b)(a+3b))) with a=5, b=3
        let a: CGFloat = 5, b: CGFloat = 3
        let sum = a + b
        let product = (3 * a + b) * (a + 3 * b)
        let expected = CGFloat.pi * (3 * sum - product.squareRoot())
        #expect(Geometry.ellipse.perimeter(width: 10, height: 6) == expected)
    }

    @Test func ellipsePerimeterDegeneratesForCircle() {
        // When a == b, Ramanujan simplifies to π(3(2a) − √(4a × 4a)) = π(6a − 4a) = 2πa
        #expect(Geometry.ellipse.perimeter(width: 8, height: 8) == .pi * 8)
    }

    // MARK: ShapeData.computedArea and computedPerimeter for kind "ellipse"

    @Test func shapeDataComputedAreaEllipse() {
        let data = ShapeData(x: 0, y: 0, width: 10, height: 6, isFilled: true, showsLabel: true, kind: "ellipse")
        #expect(data.computedArea == .pi * 5 * 3)
    }

    @Test func shapeDataComputedPerimeterEllipse() {
        let data = ShapeData(x: 0, y: 0, width: 10, height: 6, isFilled: true, showsLabel: true, kind: "ellipse")
        let a: CGFloat = 5, b: CGFloat = 3
        let sum = a + b
        let product = (3 * a + b) * (a + 3 * b)
        let expected = CGFloat.pi * (3 * sum - product.squareRoot())
        #expect(data.computedPerimeter == expected)
    }
}
