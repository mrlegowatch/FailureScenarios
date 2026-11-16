//
//  Change2Tests.swift
//  Change2Tests
//
//  Created by Brian Arnold on 6/20/26.
//

import Testing
import Foundation
@testable import Change2

@Suite("Change 2 — Geometry labeled params, circle internal radius, ShapeData computed properties")
struct Change2Tests {

    // MARK: Geometry.area(width:height:) — labeled API, circle derives radius internally

    @Test func geometryAreaRectangle() {
        #expect(Geometry.rectangle.area(width: 10, height: 5) == 50)
    }

    @Test func geometryAreaCircle() {
        // width is diameter; circle derives radius = width / 2 internally
        #expect(Geometry.circle.area(width: 8, height: 8) == .pi * 16)
    }

    @Test func geometryAreaTriangle() {
        #expect(Geometry.triangle.area(width: 6, height: 4) == 12)
    }

    // MARK: Geometry.perimeter(width:height:) — labeled API, circle derives radius internally

    @Test func geometryPerimeterRectangle() {
        #expect(Geometry.rectangle.perimeter(width: 10, height: 5) == 30)
    }

    @Test func geometryPerimeterCircle() {
        // width is diameter; perimeter = π * width (= 2π * radius)
        #expect(Geometry.circle.perimeter(width: 8, height: 8) == .pi * 8)
    }

    @Test func geometryPerimeterTriangle() {
        let w: CGFloat = 6, h: CGFloat = 4
        let expected = w + h + (w * w + h * h).squareRoot()
        #expect(Geometry.triangle.perimeter(width: 6, height: 4) == expected)
    }

    // MARK: ShapeData.computedArea — property (not method) on ShapeData

    @Test func shapeDataComputedAreaRectangle() {
        let data = ShapeData(x: 0, y: 0, width: 10, height: 5, isFilled: true, showsLabel: true, kind: "rectangle")
        #expect(data.computedArea == 50)
    }

    @Test func shapeDataComputedAreaCircle() {
        let data = ShapeData(x: 0, y: 0, width: 8, height: 8, isFilled: false, showsLabel: true, kind: "circle")
        #expect(data.computedArea == .pi * 16)
    }

    @Test func shapeDataComputedAreaTriangle() {
        let data = ShapeData(x: 0, y: 0, width: 6, height: 4, isFilled: true, showsLabel: true, kind: "triangle")
        #expect(data.computedArea == 12)
    }

    // MARK: ShapeData.computedPerimeter — property (not method) on ShapeData

    @Test func shapeDataComputedPerimeterRectangle() {
        let data = ShapeData(x: 0, y: 0, width: 10, height: 5, isFilled: true, showsLabel: true, kind: "rectangle")
        #expect(data.computedPerimeter == 30)
    }

    @Test func shapeDataComputedPerimeterCircle() {
        let data = ShapeData(x: 0, y: 0, width: 8, height: 8, isFilled: false, showsLabel: true, kind: "circle")
        #expect(data.computedPerimeter == .pi * 8)
    }

    @Test func shapeDataComputedPerimeterTriangle() {
        let data = ShapeData(x: 0, y: 0, width: 6, height: 4, isFilled: true, showsLabel: true, kind: "triangle")
        let w: CGFloat = 6, h: CGFloat = 4
        let expected = w + h + (w * w + h * h).squareRoot()
        #expect(data.computedPerimeter == expected)
    }
}
