// HelocViewModelTests.swift

import XCTest
import Foundation
@testable import Quotient

@MainActor
final class HelocViewModelTests: XCTestCase {

    func testBlendedRateBetweenFirstLienAndHeloc() {
        let vm = HelocViewModel()
        let blend = vm.blendedRate
        XCTAssertGreaterThan(blend, vm.inputs.firstLienRate)
        XCTAssertLessThan(blend, vm.inputs.helocFullyIndexedRate)
    }

    func testBlendedRateWeighedByBalance() {
        var inputs = HelocFormInputs.sampleDefault
        inputs.firstLienBalance = 0
        inputs.helocAmount = 100_000
        let vm = HelocViewModel(inputs: inputs)
        // 100% HELOC weight → blend equals HELOC rate.
        XCTAssertEqual(vm.blendedRate, vm.inputs.helocFullyIndexedRate, accuracy: 0.01)
    }

    func testStressPathShockExceedsBase() {
        let vm = HelocViewModel()
        let base = vm.stressPath(kind: .base)
        let shock = vm.stressPath(kind: .shock)
        // Later in the path, shock should exceed base.
        let baseEnd = base.last?.1 ?? 0
        let shockEnd = shock.last?.1 ?? 0
        XCTAssertGreaterThan(shockEnd, baseEnd)
    }
}
