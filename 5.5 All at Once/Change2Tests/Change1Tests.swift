//
//  Change1Tests.swift
//  Change1Tests
//
//  Created by Brian Arnold on 6/20/26.
//

import Testing
import Foundation
@testable import Change2

@Suite("Change 1 — Geometry.init(kind:) and ShapeData.geometry")
struct Change1Tests {

    // MARK: Geometry.init(kind:) — each valid kind maps to its case

    @Test func kindRectangleMapsToRectangle() {
        #expect(Geometry(kind: "rectangle") == .rectangle)
    }

    @Test func kindCircleMapsToCircle() {
        #expect(Geometry(kind: "circle") == .circle)
    }

    @Test func kindTriangleMapsToTriangle() {
        #expect(Geometry(kind: "triangle") == .triangle)
    }

    @Test func unknownKindDefaultsToRectangle() {
        #expect(Geometry(kind: "hexagon") == .rectangle)
    }

    // MARK: ShapeData.geometry — convenience property returns correct case

    @Test func shapeDataGeometryForRectangle() {
        let data = ShapeData(x: 0, y: 0, width: 10, height: 5, isFilled: true, showsLabel: true, kind: "rectangle")
        #expect(data.geometry == .rectangle)
    }

    @Test func shapeDataGeometryForCircle() {
        let data = ShapeData(x: 0, y: 0, width: 8, height: 8, isFilled: false, showsLabel: true, kind: "circle")
        #expect(data.geometry == .circle)
    }

    @Test func shapeDataGeometryForTriangle() {
        let data = ShapeData(x: 0, y: 0, width: 6, height: 4, isFilled: true, showsLabel: true, kind: "triangle")
        #expect(data.geometry == .triangle)
    }
}
