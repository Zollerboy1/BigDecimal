import XCTest
@testable import BigDecimal

import BigInt

final class BigDecimalTests: XCTestCase {
    func testSum() throws {
        let values: [BigDecimal] = [
            2.5,
            0.3,
            0.001,
        ]

        let expectedSum = BigDecimal(2.801)
        let sum = values.reduce(.zero, +)

        XCTAssertEqual(expectedSum, sum)
    }

    func testSum1() {
        let values: [BigDecimal] = [
            0.1,
            0.2
        ]

        let expectedSum = BigDecimal(0.3)
        let sum = values.reduce(.zero, +)

        XCTAssertEqual(expectedSum, sum)
    }

    func testToInt() {
        let values = [
            ("12.34", 12),
            ("3.14", 3),
            ("50", 50),
            ("50000", 50000),
            ("0.001", 0)
        ]

        for (s, ans) in values {
            let calculated = Int(BigDecimal(s)!)

            XCTAssertEqual(ans, calculated)
        }
    }

    func testToDouble() {
        let values = [
            ("12.34", 12.34),
            ("3.14", 3.14),
            ("50", 50.0),
            ("50000", 50000.0),
            ("0.001", 0.001),
        ]

        for (s, ans) in values {
            let diff = Double(exactly: BigDecimal(s)!)! - ans

            XCTAssert(diff.magnitude < 1e-10)
        }
    }

    func testFromInt8() {
        let values = [
            ("0", 0),
            ("1", 1),
            ("12", 12),
            ("-13", -13),
            ("111", 111),
            ("-128", Int8.min),
            ("127", Int8.max),
        ]

        for (s, n) in values {
            let expected = BigDecimal(s)!
            let value = BigDecimal(n)

            XCTAssertEqual(expected, value)
        }
    }

    func testFromFloat() {
        let values: [(String, Float)] = [
            ("1.0", 1.0),
            ("0.5", 0.5),
            ("0.25", 0.25),
            ("50.", 50.0),
            ("50000", 50000.0),
            ("0.001", 0.001),
            ("12.34", 12.34),
            ("0.15625", 5.0 * 0.03125),
            ("3.1415925", Float.pi),
            ("31415.926", Float.pi * 10000.0),
            ("94247.77", Float.pi * 30000.0)
        ]

        for (s, n) in values {
            let expected = BigDecimal(s)!
            let value = BigDecimal(n)!

            XCTAssertEqual(expected, value)
        }
    }

    func testFromDouble() {
        let values = [
            ("1.0", 1.0),
            ("0.5", 0.5),
            ("50", 50.0),
            ("50000", 50000.0),
            ("1e-3", 0.001),
            ("0.25", 0.25),
            ("12.34", 12.34),
            ("0.15625", 5.0 * 0.03125),
            ("0.3333333333333333", 1.0 / 3.0),
            ("3.141592653589793", Double.pi),
            ("31415.926535897932", Double.pi * 10000.0),
            ("94247.7796076938", Double.pi * 30000.0)
        ]

        for (s, n) in values {
            let expected = BigDecimal(s)!
            let value = BigDecimal(n)!

            XCTAssertEqual(expected, value)
        }
    }

    func testNanFloat() {
        XCTAssertNil(BigDecimal(Float.nan))
        XCTAssertNil(BigDecimal(Double.nan))
    }

    func testAdd() {
        let values = [
            ("12.34", "1.234", "13.574"),
            ("12.34", "-1.234", "11.106"),
            ("1234e6", "1234e-6", "1234000000.001234"),
            ("1234e-6", "1234e6", "1234000000.001234"),
            ("18446744073709551616.0", "1", "18446744073709551617"),
            ("184467440737e3380", "0", "184467440737e3380"),
        ]

        for (x, y, z) in values {
            var a = BigDecimal(x)!
            let b = BigDecimal(y)!
            let c = BigDecimal(z)!

            XCTAssertEqual(a + b, c)

            a += b
            XCTAssertEqual(a, c)
        }
    }

    func testSub() {
        let values = [
            ("12.34", "1.234", "11.106"),
            ("12.34", "-1.234", "13.574"),
            ("1234e6", "1234e-6", "1233999999.998766"),
        ]

        for (x, y, z) in values {
            var a = BigDecimal(x)!
            let b = BigDecimal(y)!
            let c = BigDecimal(z)!

            XCTAssertEqual(a - b, c)

            a -= b
            XCTAssertEqual(a, c)
        }
    }

    func testMul() {
        let values = [
            ("2", "1", "2"),
            ("12.34", "1.234", "15.22756"),
            ("2e1", "1", "20"),
            ("3", ".333333", "0.999999"),
            ("2389472934723", "209481029831", "500549251119075878721813"),
            ("1e-450", "1e500", ".1e51"),
        ]

        for (x, y, z) in values {
            var a = BigDecimal(x)!
            let b = BigDecimal(y)!
            let c = BigDecimal(z)!

            XCTAssertEqual(a * b, c)

            a *= b
            XCTAssertEqual(a, c)
        }
    }

    func testDiv() {
        let values = [
            ("0", "1", "0"),
            ("0", "10", "0"),
            ("2", "1", "2"),
            ("2e1", "1", "2e1"),
            ("10", "10", "1"),
            ("100", "10.0", "1e1"),
            ("20.0", "200", ".1"),
            ("4", "2", "2.0"),
            ("15", "3", "5.0"),
            ("1", "2", "0.5"),
            ("1", "2e-2", "5e1"),
            ("1", "0.2", "5"),
            ("1.0", "0.02", "50"),
            ("1", "0.020", "5e1"),
            ("5.0", "4.00", "1.25"),
            ("5.0", "4.000", "1.25"),
            ("5", "4.000", "1.25"),
            ("5", "4", "125e-2"),
            ("100", "5", "20"),
            ("-50", "5", "-10"),
            ("200", "-5", "-40."),
            ("1", "3", ".3333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333"),
            ("-2", "-3", ".6666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666667"),
            ("-12.34", "1.233", "-10.00811030008110300081103000811030008110300081103000811030008110300081103000811030008110300081103001"),
            ("125348", "352.2283", "355.8714617763535752237966114591019517738921035021887792661748076460636467881768727839301952739175132"),
        ]

        for (x, y, z) in values {
            var a = BigDecimal(x)!
            let b = BigDecimal(y)!
            let c = BigDecimal(z)!

            XCTAssertEqual(a / b, c)

            a /= b
            XCTAssertEqual(a, c)
        }
    }

    func testRemainder() {
        let values = [
            ("100", "5", "0"),
            ("2e1", "1", "0"),
            ("2", "1", "0"),
            ("1", "3", "1"),
            ("1", "0.5", "0"),
            ("1.5", "1", "0.5"),
            ("1", "3e-2", "1e-2"),
            ("10", "0.003", "0.001"),
            ("3", "2", "1"),
            ("-3", "2", "-1"),
            ("3", "-2", "1"),
            ("-3", "-2", "-1"),
            ("12.34", "1.233", "0.01"),
        ]

        for (x, y, z) in values {
            let a = BigDecimal(x)!
            let b = BigDecimal(y)!
            let c = BigDecimal(z)!

            let remainder = a.remainder(dividingBy: b)
            XCTAssertEqual(remainder, c)
        }

        let values2 = [
            (("100", -2), ("50", -1), "0"),
            (("100", 0), ("50", -1), "0"),
            (("100", -2), ("30", 0), "10"),
            (("100", 0), ("30", -1), "10"),
        ]

        for ((x, xs), (y, ys), z) in values2 {
            let a = BigDecimal(x)!.withScale(xs)
            let b = BigDecimal(y)!.withScale(ys)
            let c = BigDecimal(z)!

            let remainder = a.remainder(dividingBy: b)

            XCTAssertEqual(remainder, c)
        }
    }

    func testEqual() {
        let values = [
            ("2", ".2e1"),
            ("0e1", "0.0"),
            ("0e0", "0.0"),
            ("0e-0", "0.0"),
            ("-0901300e-3", "-901.3"),
            ("-0.901300e+3", "-901.3"),
            ("-0e-1", "-0.0"),
            ("2123121e1231", "212.3121e1235"),
        ]
        for (x, y) in values {
            let a = BigDecimal(x)!
            let b = BigDecimal(y)!
            XCTAssertEqual(a, b)
        }
    }

    func testNotEqual() {
        let values = [
            ("2", ".2e2"),
            ("1e45", "1e-900"),
            ("1e+900", "1e-900"),
        ]

        for (x, y) in values {
            let a = BigDecimal(x)!
            let b = BigDecimal(y)!
            XCTAssertNotEqual(a, b)
        }
    }

    func testHashEqual() {
        let values = [
            ("1.1234", "1.1234000"),
            ("1.12340000", "1.1234"),
            ("001.1234", "1.1234000"),
            ("001.1234", "0001.1234"),
            ("1.1234000000", "1.1234000"),
            ("1.12340", "1.1234000000"),
            ("-0901300e-3", "-901.3"),
            ("-0.901300e+3", "-901.3"),
            ("100", "100.00"),
            ("100.00", "100"),
            ("0.00", "0"),
            ("0.00", "0.000"),
            ("-0.00", "0.000"),
            ("0.00", "-0.000"),
        ]

        for (x, y) in values {
            let a = BigDecimal(x)!
            let b = BigDecimal(y)!
            XCTAssertEqual(a, b)
            XCTAssertEqual(Self.hash(a), Self.hash(b))
        }
    }

    func testHashNotEqual() {
        let values = [
            ("1.1234", "1.1234001"),
            ("10000", "10"),
            ("10", "10000"),
            ("10.0", "100"),
        ]

        for (x, y) in values {
            let a = BigDecimal(x)!
            let b = BigDecimal(y)!
            XCTAssertNotEqual(a, b)
            XCTAssertNotEqual(Self.hash(a), Self.hash(b))
        }
    }

    func testHashEqualScale() {
        let values = [
            ("1234.5678", -2, "1200", 0),
            ("1234.5678", -2, "1200", -2),
            ("1234.5678", 0, "1234.1234", 0),
            ("1234.5678", -3, "1200", -3),
            ("-1234", -2, "-1200", 0),
        ]

        for (x, xs, y, ys) in values {
            let a = BigDecimal(x)!.withScale(xs)
            let b = BigDecimal(y)!.withScale(ys)

            XCTAssertEqual(a, b)
            XCTAssertEqual(Self.hash(a), Self.hash(b))
        }
    }

    func testWithPrecision() {
        let values = [
            ("7", 1, "7"),
            ("7", 2, "7.0"),
            ("895", 2, "900"),
            ("8934", 2, "8900"),
            ("8934", 1, "9000"),
            ("1.0001", 5, "1.0001"),
            ("1.0001", 4, "1"),
            ("1.00009", 6, "1.00009"),
            ("1.00009", 5, "1.0001"),
            ("1.00009", 4, "1.000"),
        ]

        for (x, p, y) in values {
            let a = BigDecimal(x)!.withPrecision(p)
            XCTAssertEqual(a, BigDecimal(y)!)
        }
    }


    func testDigitCount() {
        let values = [
            ("0", 1),
            ("7", 1),
            ("10", 2),
            ("8934", 4),
        ]

        for (x, y) in values {
            let a = BigDecimal(x)!
            XCTAssertEqual(a.digitCount, y)
        }
    }

    func testGetRoundingTerm() {
        let values: [(String, BigInt)] = [
            ("0", 0),
            ("4", 0),
            ("5", 1),
            ("10", 0),
            ("15", 0),
            ("49", 0),
            ("50", 1),
            ("51", 1),
            ("8934", 1),
            ("9999", 1),
            ("10000", 0),
            ("50000", 1),
            ("99999", 1),
            ("100000", 0),
            ("100001", 0),
            ("10000000000", 0),
            ("9999999999999999999999999999999999999999", 1),
            ("10000000000000000000000000000000000000000", 0),
        ]

        for (x, y) in values {
            let a = BigInt(x)!
            XCTAssertEqual(getRoundingTerm(of: a), y)
        }
    }

    func testMagnitude() {
        let values = [
            ("10", "10"),
            ("-10", "10"),
        ]

        for (x, y) in values {
            let a = BigDecimal(x)!.magnitude
            let b = BigDecimal(y)!

            XCTAssertEqual(a, b)
        }
    }

    func testCountDecimalDigits() {
        let values = [
            ("10", 2),
            ("1", 1),
            ("9", 1),
            ("999", 3),
            ("1000", 4),
            ("9900", 4),
            ("9999", 4),
            ("10000", 5),
            ("99999", 5),
            ("100000", 6),
            ("999999", 6),
            ("1000000", 7),
            ("9999999", 7),
            ("999999999999", 12),
            ("999999999999999999999999", 24),
            ("999999999999999999999999999999999999999999999999", 48),
            ("999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999", 96),
            ("199999911199999999999999999999999999999999999999999999999999999999999999999999999999999999999000", 96),
            ("999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999991", 192),
            ("199999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999", 192),
        ]

        for (x, y) in values {
            let a = BigInt(x)!
            let b = a.digitCount

            XCTAssertEqual(b, y)
        }
    }


    private static func hash<T: Hashable>(_ value: T) -> Int {
        var hasher = Hasher()
        value.hash(into: &hasher)
        return hasher.finalize()
    }
}
