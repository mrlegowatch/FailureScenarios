//
//  DiagnosticTests.swift
//  DiagnosticTests
//
//  Created by Brian Arnold on 6/20/26.
//

import Testing
import Foundation
@testable import BuggyRefactor

// MARK: - Bug 1: Off-by-one-character typo in Geometry.init(kind:)
//
// In BuggyRefactor/Shapes.swift, the switch that maps kind strings to Geometry cases:
//
//   case "triang1e":  self = .triangle   // digit '1', not letter 'l'
//
// The digit '1' and lowercase 'l' are visually nearly identical in many fonts. The case
// literal is syntactically valid Swift, so the compiler raises no warning. Any ShapeData
// with kind: "triangle" (all letters) misses all three named cases and falls through to
// `default: self = .rectangle`, silently substituting rectangle behavior for every triangle.

@Suite("Bug 1 — Typo: \"triang1e\" (digit 1) vs. \"triangle\" (letter l)")
struct Bug1DiagnosticTests {

    // The correctly spelled string "triangle" falls through to default → .rectangle.
    @Test func correctStringMapsToRectangle() {
        // FAILS: returns .rectangle because "triangle" ≠ "triang1e"
        #expect(Geometry(kind: "triangle") == .triangle)
    }

    // ShapeData.geometry uses kind: "triangle", so it too resolves to .rectangle.
    @Test func triangleShapeDataGeometryIsRectangle() {
        let data = ShapeData(x: 0, y: 0, width: 6, height: 4, isFilled: true, showsLabel: true, kind: "triangle")
        // FAILS: data.geometry == .rectangle, not .triangle
        #expect(data.geometry == .triangle)
    }

    // Consequence: triangle area uses the rectangle formula (w × h) instead of (0.5 × w × h).
    @Test func triangleAreaUsesRectangleFormula() {
        let data = ShapeData(x: 0, y: 0, width: 6, height: 4, isFilled: true, showsLabel: true, kind: "triangle")
        // FAILS: returns 24.0 (rectangle: 6 × 4) instead of 12.0 (triangle: 0.5 × 6 × 4)
        #expect(ShapeViewModel(shapeData: data).computedArea() == 12)
    }

    // Consequence: triangle perimeter uses the rectangle formula (2(w+h) = 20) instead of
    // the right-triangle formula (w + h + √(w²+h²) ≈ 17.21).
    @Test func trianglePerimeterUsesRectangleFormula() {
        let data = ShapeData(x: 0, y: 0, width: 6, height: 4, isFilled: true, showsLabel: true, kind: "triangle")
        let w: CGFloat = 6, h: CGFloat = 4
        let expected = w + h + (w * w + h * h).squareRoot()
        // FAILS: returns 20.0 (rectangle: 2×(6+4)) instead of ≈ 17.21
        #expect(ShapeViewModel(shapeData: data).computedPerimeter() == expected)
    }
}

// MARK: - Bug 2: Swapped labeled arguments in ShapeViewModel.computedArea(), rectangle case
//
// In BuggyRefactor/Shapes.swift, ShapeViewModel.computedArea():
//
//   case .rectangle:
//       return geom.area(width: shapeData.height, height: shapeData.width)   // ← swapped
//
// After the refactor added labeled parameters (width:height:), this call site was left
// in the old positional order — passing height where width is expected and vice versa.
//
// WHY IT IS PERMANENTLY SILENT: area(width:height:) computes `width * height`.
// Multiplication is commutative, so area(width: a, height: b) == area(width: b, height: a)
// for every pair of CGFloat values. No test driven through area() can detect the swap
// because the correct and buggy calls are numerically indistinguishable.

@Suite("Bug 2 — Swapped width:/height: at rectangle area call site (silent — commutative)")
struct Bug2DiagnosticTests {

    // Direct proof of commutativity: both argument orders return the same value.
    @Test func rectangleAreaIsCommutative() {
        let width: CGFloat = 10, height: CGFloat = 3   // deliberately non-square
        let correctCall = Geometry.rectangle.area(width: width, height: height)   // 10 × 3 = 30
        let swappedCall = Geometry.rectangle.area(width: height, height: width)   // 3 × 10 = 30
        // PASSES — this is the invariant that makes Bug 2 invisible.
        #expect(correctCall == swappedCall)
    }

    // The ViewModel passes despite the swap: its result matches the correct value.
    @Test func rectangleViewModelAreaPassesDespiteSwap() {
        let data = ShapeData(x: 0, y: 0, width: 10, height: 3, isFilled: true, showsLabel: true, kind: "rectangle")
        let correct = Geometry.rectangle.area(width: data.width, height: data.height)   // 30
        let swapped = Geometry.rectangle.area(width: data.height, height: data.width)   // 30
        // Both equal 30; vm.computedArea() executes the swapped form and returns 30.
        // PASSES despite the bug — commutativity hides the defect completely.
        #expect(ShapeViewModel(shapeData: data).computedArea() == correct)
        #expect(ShapeViewModel(shapeData: data).computedArea() == swapped)
    }

    // For contrast: other cases in computedArea() pass arguments in the correct order.
    // Using ellipse (unaffected by Bug 1) to avoid cross-contamination from the typo bug.
    @Test func ellipseCaseIsNotSwapped() {
        let ellipseData = ShapeData(x: 0, y: 0, width: 10, height: 6, isFilled: true, showsLabel: true, kind: "ellipse")
        // Ellipse area = π × (w/2) × (h/2) is commutative, so a swap here would also be silent.
        // The point: no behavioral test over any of the current formulas can catch a swap.
        let direct = Geometry.ellipse.area(width: 10, height: 6)
        // PASSES: the ellipse case uses the correct argument order
        #expect(ShapeViewModel(shapeData: ellipseData).computedArea() == direct)
    }
}

// MARK: - Bug 3: Half-inverted condition in ShapeViewModel.boundingInset() guard
//
// In BuggyRefactor/Shapes.swift, ShapeViewModel.boundingInset():
//
//   guard shapeData.width <= 0 || shapeData.height > 0 else { return 0.0 }
//
// The original if-statement proceeded only when `width > 0 && height > 0`, so the guard
// needed that same condition, with no inversion. Instead, the width comparison was
// inverted (`width > 0` became `width <= 0`), the height comparison was left alone, and
// `&&` became `||`. The result lets any zero-width shape through the guard, with or without
// height, while a shape with width but zero height still returns 0.0 as intended.

@Suite("Bug 3 — Half-inverted guard in boundingInset() (zero-width inputs)")
struct Bug3DiagnosticTests {

    // Zero width, positive height: guard should short-circuit to 0.0, but doesn't.
    @Test func zeroWidthPositiveHeightShouldReturnZero() {
        let data = ShapeData(x: 0, y: 0, width: 0, height: 5, isFilled: true, showsLabel: true, kind: "rectangle")
        let vm = ShapeViewModel(shapeData: data, isSelected: true, isHighlighted: true, zoomLevel: 2.0)
        // FAILS: (0<=0 || 5>0) == true → guard passes → returns 4.0 * 2.0 = 8.0
        #expect(vm.boundingInset() == 0.0)
    }

    // Both dimensions zero: the most degenerate case also slips through.
    @Test func bothDimensionsZeroShouldReturnZero() {
        let data = ShapeData(x: 0, y: 0, width: 0, height: 0, isFilled: true, showsLabel: true, kind: "rectangle")
        let vm = ShapeViewModel(shapeData: data, isSelected: true, isHighlighted: true, zoomLevel: 2.0)
        // FAILS: (0<=0 || 0>0) == true → guard passes → returns 4.0 * 2.0 = 8.0
        #expect(vm.boundingInset() == 0.0)
    }

    // Positive width, zero height: both halves are false, so the guard still returns 0.0.
    @Test func positiveWidthZeroHeightReturnsZero() {
        let data = ShapeData(x: 0, y: 0, width: 10, height: 0, isFilled: true, showsLabel: true, kind: "rectangle")
        let vm = ShapeViewModel(shapeData: data, isSelected: true, zoomLevel: 2.0)
        // PASSES: (10<=0 || 0>0) == false → else branch fires → returns 0.0
        #expect(vm.boundingInset() == 0.0)
    }

    // Both dimensions positive: the height half is true, so this case is unaffected.
    @Test func bothDimensionsPositiveUnaffected() {
        let data = ShapeData(x: 0, y: 0, width: 10, height: 5, isFilled: true, showsLabel: true, kind: "rectangle")
        let vm = ShapeViewModel(shapeData: data, isSelected: true, isHighlighted: true, zoomLevel: 2.0)
        // PASSES: (10<=0 || 5>0) == true → returns 4.0 * 2.0 = 8.0
        #expect(vm.boundingInset() == 8.0)
    }
}

// MARK: - Bug 4: Wrong variable in the Ramanujan ellipse perimeter second factor
//
// In BuggyRefactor/Shapes.swift, Geometry.perimeter(width:height:), ellipse case:
//
//   let product = (3 * semiMajorAxis + semiMinorAxis) * (semiMinorAxis + 3 * semiMinorAxis)
//
// The correct second factor is (semiMajorAxis + 3 * semiMinorAxis).
// As written it is (semiMinorAxis + 3 * semiMinorAxis) = 4 * semiMinorAxis.
//
// WHY IT IS SUBTLE: Ramanujan's first approximation is P ≈ π(3(a+b) − √((3a+b)(a+3b))).
// The two factors are (3a+b) and (a+3b) — they differ only in which semi-axis is
// multiplied by 3. When a == b (a circle), (a+3b) == (b+3b) == 4b, so both the correct
// and buggy formulas give identical results. The defect is invisible for any circular
// input and only surfaces when width ≠ height.

@Suite("Bug 4 — semiMinorAxis replaces semiMajorAxis in Ramanujan second factor (non-circle only)")
struct Bug4DiagnosticTests {

    // For a circle (a == b), the correct and buggy second factors are numerically identical.
    @Test func circleSecondFactorIsUnaffected() {
        let a: CGFloat = 4, b: CGFloat = 4   // equal semi-axes (circle)
        let correctFactor = a + 3 * b   // 4 + 12 = 16
        let buggyFactor   = b + 3 * b   // 4 + 12 = 16  ← same when a == b
        // PASSES: confirms why circle tests cannot catch this bug
        #expect(correctFactor == buggyFactor)
    }

    // Verify the actual ellipse perimeter call also passes for circular input.
    @Test func circlePerimeterCorrectDespiteBug() {
        // width=8, height=8 → semiMajorAxis == semiMinorAxis == 4
        let expectedCirclePerimeter = 2 * CGFloat.pi * 4
        // PASSES: bug is numerically invisible when both semi-axes are equal
        #expect(Geometry.ellipse.perimeter(width: 8, height: 8) == expectedCirclePerimeter)
    }

    // For a non-circular ellipse, the second factors diverge.
    @Test func nonCircleSecondFactorDiverges() {
        let a: CGFloat = 5, b: CGFloat = 3   // semi-axes for width=10, height=6
        let correctFactor = a + 3 * b   // 5 + 9 = 14
        let buggyFactor   = b + 3 * b   // 3 + 9 = 12  ← differs when a ≠ b
        // PASSES: illustrates exactly where the values split
        #expect(correctFactor != buggyFactor)
    }

    // The perimeter computed by the buggy code for width=10, height=6 is wrong.
    @Test func ellipsePerimeterIsWrongForNonCircularInput() {
        // Correct Ramanujan: π(3(a+b) − √((3a+b)(a+3b))) with a=5, b=3
        let a: CGFloat = 5, b: CGFloat = 3
        let correctProduct    = (3 * a + b) * (a + 3 * b)   // 18 × 14 = 252
        let expectedPerimeter = CGFloat.pi * (3 * (a + b) - correctProduct.squareRoot())   // ≈ 25.527
        // FAILS: code computes π(3×8 − √((18)(12))) = π(24 − √216) ≈ 29.226
        #expect(Geometry.ellipse.perimeter(width: 10, height: 6) == expectedPerimeter)
    }

    // Confirm the exact value the buggy code does produce, to make the error concrete.
    @Test func ellipsePerimeterMatchesBuggyFormula() {
        let a: CGFloat = 5, b: CGFloat = 3
        let buggyProduct    = (3 * a + b) * (b + 3 * b)   // 18 × 12 = 216 (semiMajorAxis→semiMinorAxis)
        let buggyPerimeter  = CGFloat.pi * (3 * (a + b) - buggyProduct.squareRoot())   // ≈ 29.226
        // PASSES: verifies the buggy code returns exactly this value for width=10, height=6
        #expect(Geometry.ellipse.perimeter(width: 10, height: 6) == buggyPerimeter)
    }
}
