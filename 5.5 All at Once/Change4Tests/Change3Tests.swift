//
//  Change3Tests.swift
//  Change3Tests
//
//  Created by Brian Arnold on 6/20/26.
//

import Testing
import Foundation
@testable import Change4

@Suite("Change 3 — ShapeData.isEmpty and guard !shapeData.isEmpty")
struct Change3Tests {

    // MARK: ShapeData.isEmpty

    @Test func isEmptyFalseWhenBothPositive() {
        let data = ShapeData(x: 0, y: 0, width: 10, height: 5, isFilled: true, showsLabel: true, kind: "rectangle")
        #expect(data.isEmpty == false)
    }

    @Test func isEmptyTrueWhenWidthIsZero() {
        let data = ShapeData(x: 0, y: 0, width: 0, height: 5, isFilled: true, showsLabel: true, kind: "rectangle")
        #expect(data.isEmpty == true)
    }

    @Test func isEmptyTrueWhenHeightIsZero() {
        let data = ShapeData(x: 0, y: 0, width: 10, height: 0, isFilled: true, showsLabel: true, kind: "rectangle")
        #expect(data.isEmpty == true)
    }

    @Test func isEmptyTrueWhenBothZero() {
        let data = ShapeData(x: 0, y: 0, width: 0, height: 0, isFilled: true, showsLabel: true, kind: "rectangle")
        #expect(data.isEmpty == true)
    }

    // MARK: displayLabel() respects isEmpty via guard

    @Test func displayLabelReturnsEmptyLabelWhenWidthIsZero() {
        let data = ShapeData(x: 0, y: 0, width: 0, height: 5, isFilled: true, showsLabel: true, kind: "rectangle")
        #expect(ShapeViewModel(shapeData: data).displayLabel() == "rectangle (empty)")
    }

    @Test func displayLabelReturnsEmptyLabelWhenHeightIsZero() {
        let data = ShapeData(x: 0, y: 0, width: 10, height: 0, isFilled: true, showsLabel: true, kind: "circle")
        #expect(ShapeViewModel(shapeData: data).displayLabel() == "circle (empty)")
    }

    @Test func displayLabelReturnsNormalLabelWhenNotEmpty() {
        let data = ShapeData(x: 0, y: 0, width: 10, height: 5, isFilled: true, showsLabel: true, kind: "rectangle")
        #expect(ShapeViewModel(shapeData: data).displayLabel() == "rectangle area=50.0")
    }

    // MARK: boundingInset() respects isEmpty via guard

    @Test func boundingInsetReturnsZeroWhenWidthIsZero() {
        let data = ShapeData(x: 0, y: 0, width: 0, height: 5, isFilled: true, showsLabel: true, kind: "rectangle")
        let vm = ShapeViewModel(shapeData: data, isSelected: true, isHighlighted: true, zoomLevel: 2.0)
        #expect(vm.boundingInset() == 0.0)
    }

    @Test func boundingInsetReturnsZeroWhenHeightIsZero() {
        let data = ShapeData(x: 0, y: 0, width: 10, height: 0, isFilled: true, showsLabel: true, kind: "rectangle")
        let vm = ShapeViewModel(shapeData: data, isSelected: true, zoomLevel: 2.0)
        #expect(vm.boundingInset() == 0.0)
    }

    @Test func boundingInsetReturnsNonZeroWhenNotEmpty() {
        let data = ShapeData(x: 0, y: 0, width: 10, height: 5, isFilled: true, showsLabel: true, kind: "rectangle")
        let vm = ShapeViewModel(shapeData: data, isSelected: true, isHighlighted: true, zoomLevel: 2.0)
        #expect(vm.boundingInset() == 8.0)
    }
}
