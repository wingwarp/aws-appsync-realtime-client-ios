//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AppSyncRealTimeClient

/// Tests for the CountdownTimer internal support type. We do not expose this as
/// part of the public API, but its behavior is critical to the RTC's ability to
/// handle stale connections.
///
/// Clearly many of these tests are timing dependent, and could vary based on the
/// execution environment. We'll try these tests now, and if they turn out to be
/// unstable then we'll remove it and try a different approach.
class CountdownTimerTests: XCTestCase {

    func testTimerFires() {
        let timerFired = expectation(description: "timerFired")
        let timer = CountdownTimer()
        timer.start(interval: 0.1) { timerFired.fulfill() }
        waitForExpectations(timeout: 1.0)
        timer.invalidate()
    }

    func testTimerDoesNotFireEarly() {
        let timerFired = expectation(description: "timerFired")
        timerFired.isInverted = true
        let timer = CountdownTimer()
        timer.start(interval: 0.5) { timerFired.fulfill() }
        waitForExpectations(timeout: 0.1)
        timer.invalidate()
    }

    func testTimerFiresOnBackgroundQueue() {
        let timerFired = expectation(description: "timerFired")
        timerFired.isInverted = true
        XCTAssert(Thread.isMainThread)
        let timer = CountdownTimer()
        timer.start(interval: 1.0) {
            timerFired.fulfill()
            XCTAssertFalse(Thread.isMainThread)
        }
        waitForExpectations(timeout: 0.1)
        timer.invalidate()
    }

    func testTimerDoesNotFireAfterInvalidate() {
        let timerFired = expectation(description: "timerFired")
        timerFired.isInverted = true
        let timer = CountdownTimer()
        timer.start(interval: 0.1) {
            timerFired.fulfill()
        }
        timer.invalidate()
        waitForExpectations(timeout: 0.2)
    }

    /// Timing test
    ///
    /// Given:
    /// - A timer set to fire at a specific interval
    /// When:
    /// - The the interval elapses
    /// Then:
    /// - The timer fires then and only then
    ///
    /// Test timing in ms:
    /// - 000: Set up a timer with a .2 sec interval
    /// - 100: Ensure timer has not yet fired
    /// - 300: Ensure timer has fired
    func testTimerFiresOnSchedule() {
        let timer = CountdownTimer()
        let timerHasFired = AtomicValue(initialValue: false)

        let timerShouldHaveFired = expectation(description: "the timer should have fired by now")

        DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(0)) {
            timer.start(interval: 0.200) {
                timerHasFired.set(true)
            }
        }

        DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(100)) {
            XCTAssertFalse(timerHasFired.get(), "The timer should not have fired yet")
        }

        DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(300)) {
            XCTAssert(timerHasFired.get(), "The timer should have fired by now")
            timerShouldHaveFired.fulfill()
        }

        waitForExpectations(timeout: 1.0)
        timer.invalidate()
    }

    /// Timing test
    ///
    /// Given:
    /// - A timer set to fire at a specific interval
    /// When:
    /// - We `resetCountdown` the timer
    /// Then:
    /// - The timer does not fire until the interval has elapsed from the moment of
    ///   `resetCountdown`
    ///
    /// Test timing in ms:
    /// - 000: Set up a timer with a .3 sec interval
    /// - 100: Ensure timer has not yet fired
    /// - 200: Issue a `reset` before timer would fire
    /// - 400: Ensure timer has not yet fired
    /// - 600: Timer should fire around this time
    /// - 700: Ensure timer has fired
    func testTimerResets() {
        let timer = CountdownTimer()
        let timerHasFired = AtomicValue(initialValue: false)

        let timerShouldHaveFired = expectation(description: "the timer should have fired by now")

        DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(0)) {
            timer.start(interval: 0.300) {
                timerHasFired.set(true)
            }
        }

        DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(100)) {
            XCTAssertFalse(timerHasFired.get(), "The timer should not have fired yet")
        }

        DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(200)) {
            timer.reset()
        }

        DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(400)) {
            XCTAssertFalse(timerHasFired.get(), "The timer should not have fired yet")
        }

        DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(700)) {
            XCTAssert(timerHasFired.get(), "The timer should have fired by now")
            timerShouldHaveFired.fulfill()
        }

        waitForExpectations(timeout: 1.0)

        timer.invalidate()
    }

    /// Test that concurrent operations on the timer do not result in data races
    func testConcurrency() {
        let concurrentCount = expectation(description: "timer fired at least once")
        concurrentCount.expectedFulfillmentCount = 10_000
        let timer = CountdownTimer()

        DispatchQueue.concurrentPerform(iterations: 10_000) { _ in
            let randomInt = Int.random(in: 1 ... 3)
            if randomInt == 1 {
                timer.start(interval: 0.01) { }
            } else if randomInt == 2 {
                timer.invalidate()
            } else {
                timer.reset()
            }
            concurrentCount.fulfill()
        }
        waitForExpectations(timeout: 10)
    }
}
