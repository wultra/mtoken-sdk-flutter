import XCTest
import integration_test

final class RunnerTests: XCTestCase {
    func testIntegrationTest() {
        var testCount = 0
        FLTIntegrationTestRunner().testIntegrationTest { test, success, failure in
            testCount += 1
            XCTAssertTrue(success, "\(NSStringFromSelector(test)): \(failure ?? "")")
        }
        XCTAssertGreaterThan(testCount, 0)
    }
}
