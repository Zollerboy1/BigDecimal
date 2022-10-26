#if swift(>=5.6)
@preconcurrency import BigInt
#elseif swift(>=5.5)
import BigInt

extension BigInt: @unchecked Sendable {}
#else
import BigInt
#endif

/// A big decimal type.
public struct BigDecimal {
    /// The underlying big integer value.
    public let integerValue: BigInt
    /// The scale of the underlying value.
    ///
    /// A positive scale means a negative power of 10 and vice versa.
    public let scale: Int

    /// Creates and initializes a ``BigDecimal``.
    ///
    /// - Parameters:
    ///   - integerValue: The underlying big integer value.
    ///   - scale: The scale of the underlying value.
    @inlinable
    public init(integerValue: BigInt, scale: Int) {
        self.integerValue = integerValue
        self.scale = scale
    }


    /// Returns a new ``BigDecimal`` value equivalent to self, with internal scaling set to the specified number.
    ///
    /// - Parameter newScale: The scale the returned value will have. If it is lower than the current value (indicating a larger power of 10), digits will be dropped (as precision is lower).
    /// - Returns: A new ``BigDecimal`` value with the specified scale.
    @inlinable
    public func withScale(_ newScale: Int) -> BigDecimal {
        if self.integerValue.isZero {
            return .init(integerValue: 0, scale: newScale)
        }

        if newScale > self.scale {
            let scaleDifference = newScale - self.scale
            let integerValue = self.integerValue * tenToThe(power: scaleDifference)
            return .init(integerValue: integerValue, scale: newScale)
        } else if newScale < self.scale {
            let scaleDifference = self.scale - newScale
            let integerValue = self.integerValue / tenToThe(power: scaleDifference)
            return .init(integerValue: integerValue, scale: newScale)
        } else {
            return self
        }
    }

    /// Returns a new ``BigDecimal`` value with its precision set to the new value.
    ///
    /// - Parameter precision: The precision (i.e. the number of significant digits) the returned value will have.
    /// - Returns; A new ``BigDecimal`` value with the specified precision.
    @inlinable
    public func withPrecision(_ precision: Int) -> BigDecimal {
        let digits = self.integerValue.digitCount

        if digits > precision {
            let difference = digits - precision
            let p = tenToThe(power: difference)
            var q: BigInt
            let r: BigInt
            (q, r) = self.integerValue.quotientAndRemainder(dividingBy: p)

            // check for "leading zero" in remainder term; otherwise round
            if p < 10 * r {
                q += getRoundingTerm(of: r)
            }

            return .init(integerValue: q, scale: self.scale - difference)
        } else if digits < precision {
            let difference = precision - digits
            return .init(integerValue: self.integerValue * tenToThe(power: difference), scale: self.scale + difference)
        } else {
            return self
        }
    }


    /// The additive identity value.
    @inlinable
    static public var zero: BigDecimal {
        .init(integerValue: .zero, scale: 0)
    }

    /// The multiplicative identity value.
    @inlinable
    static public var one: BigDecimal {
        .init(integerValue: 1, scale: 0)
    }

    /// Is `true` if this value is equal to `0`, i.e. if it is `+0` or `-0`.
    @inlinable
    public var isZero: Bool {
        self.integerValue.isZero
    }


    /// The sign of this value.
    @inlinable
    public var sign: BigInt.Sign {
        self.integerValue.sign
    }


    /// The number of digits in the non-scaled integer representation.
    @inlinable
    public var digitCount: Int {
        self.integerValue.digitCount
    }
}

extension BigDecimal {
    public enum ParsingError: Error, CustomStringConvertible {
        case nonASCIIString
        case empty
        case exponentCorrupted
        case baseCorrupted
        
        public var description: String {
            switch self {
            case .nonASCIIString:
                return "Cannot parse a BigDecimal from a non-ASCII string."
            case .empty:
                return "Cannot parse a BigDecimal from an empty string."
            case .exponentCorrupted:
                return "The exponent part could not be parsed."
            case .baseCorrupted:
                return "The base part could not be parsed."
            }
        }
    }

    /// Tries to initialize a ``BigDecimal`` by parsing it from a string.
    ///
    /// The string has to be formatted as a real number in decimal format and can contain an exponent part.
    /// Here are some possible strings that will be parsed correctly:
    ///
    /// ```swift
    /// let one = try! BigDecimal(fromString: "1")
    /// let oneHalf = try! BigDecimal(fromString: "0.5")
    /// let oneHalf2 = try! BigDecimal(fromString: "5e-1")
    /// let oneHundredth = try! BigDecimal(fromString: 0.1E-1")
    ///
    /// let piString = """
    /// 3.1415926535897932384\
    /// 626433832795028841971\
    /// 693993751058209749445\
    /// 923078164062862089986\
    /// 280348253421170679
    /// """
    /// let pi = try! BigDecimal(fromString: piString)
    /// let googol = try! BigDecimal(fromString: "1e100")
    /// ```
    ///
    /// - Parameter string: The string to parse the value from.
    /// - Throws: A ``ParsingError`` if parsing failed.
    @inlinable
    public init<S>(fromString string: S) throws where S: StringProtocol {
        guard string.allSatisfy(\.isASCII) else {
            throw ParsingError.nonASCIIString
        }

        let exponentSeparator: [Character] = ["e", "E"]

        let (basePart, exponentValue): (S.SubSequence, Int) = try {
            if let location = string.firstIndex(where: exponentSeparator.contains(_:)) {
                let exponent = string[string.index(after: location)...]

                guard let exponentValue = Int(exponent) else {
                    throw ParsingError.exponentCorrupted
                }

                return (string[..<location], exponentValue)
            } else {
                return (string[...], 0)
            }
        }()

        guard !basePart.isEmpty else {
            throw ParsingError.empty
        }

        let (digits, decimalOffset): (String, Int) = {
            if let location = basePart.firstIndex(of: ".") {
                let trail = basePart[basePart.index(after: location)...]

                var digits = String(basePart[..<location])
                digits.append(contentsOf: trail)

                return (digits, trail.count)
            } else {
                return (.init(basePart), 0)
            }
        }()

        let scale = decimalOffset - exponentValue

        guard let integerValue = BigInt(digits) else {
            throw ParsingError.baseCorrupted
        }

        self.init(integerValue: integerValue, scale: scale)
    }
}


extension BigDecimal: Equatable {
    @inlinable
    public static func ==(lhs: BigDecimal, rhs: BigDecimal) -> Bool {
        if lhs.isZero && rhs.isZero {
            return true
        }

        if lhs.scale > rhs.scale {
            let scaledIntegerValue = rhs.integerValue * tenToThe(power: lhs.scale - rhs.scale)
            return lhs.integerValue == scaledIntegerValue
        } else if lhs.scale < rhs.scale {
            let scaledIntegerValue = lhs.integerValue * tenToThe(power: rhs.scale - lhs.scale)
            return scaledIntegerValue == rhs.integerValue
        } else {
            return lhs.integerValue == rhs.integerValue
        }
    }
}

extension BigDecimal: Comparable {
    @inlinable
    public static func <(lhs: BigDecimal, rhs: BigDecimal) -> Bool {
        if lhs.sign != rhs.sign {
            return lhs.sign == .minus
        }

        return (lhs - rhs).sign == .minus
    }
}


extension BigDecimal: SignedNumeric {
    @inlinable
    public init<T>(exactly source: T) where T : BinaryInteger {
        self.init(source)
    }

    @inlinable
    public var magnitude: BigDecimal {
        .init(integerValue: BigInt(self.integerValue.magnitude), scale: self.scale)
    }

    @inlinable
    public static func +=(lhs: inout BigDecimal, rhs: BigDecimal) {
        let newIntegerValue: BigInt
        var newScale = lhs.scale
        if lhs.scale < rhs.scale {
            let scaled = lhs.withScale(rhs.scale)
            newIntegerValue = scaled.integerValue + rhs.integerValue
            newScale = rhs.scale
        } else if lhs.scale > rhs.scale {
            let scaled = rhs.withScale(lhs.scale)
            newIntegerValue = lhs.integerValue + scaled.integerValue
        } else {
            newIntegerValue = lhs.integerValue + rhs.integerValue
        }

        lhs = .init(integerValue: newIntegerValue, scale: newScale)
    }

    @inlinable
    public static func -=(lhs: inout BigDecimal, rhs: BigDecimal) {
        let newIntegerValue: BigInt
        var newScale = lhs.scale
        if lhs.scale < rhs.scale {
            let scaled = lhs.withScale(rhs.scale)
            newIntegerValue = scaled.integerValue - rhs.integerValue
            newScale = rhs.scale
        } else if lhs.scale > rhs.scale {
            let scaled = rhs.withScale(lhs.scale)
            newIntegerValue = lhs.integerValue - scaled.integerValue
        } else {
            newIntegerValue = lhs.integerValue - rhs.integerValue
        }

        lhs = .init(integerValue: newIntegerValue, scale: newScale)
    }

    @inlinable
    public static func *=(lhs: inout BigDecimal, rhs: BigDecimal) {
        lhs = .init(integerValue: lhs.integerValue * rhs.integerValue, scale: lhs.scale + rhs.scale)
    }

    @inlinable
    public static func /=(lhs: inout BigDecimal, rhs: BigDecimal) {
        precondition(!rhs.isZero, "Division by zero")

        if lhs.isZero || rhs == .one {
            return
        }

        let scale = lhs.scale - rhs.scale

        if lhs.integerValue == rhs.integerValue {
            lhs = .init(integerValue: 1, scale: scale)
        } else {
            lhs = Self._division(numerator: lhs.integerValue, denominator: rhs.integerValue, scale: scale, maxPrecision: 100)
        }
    }


    @inlinable
    public static func +(lhs: BigDecimal, rhs: BigDecimal) -> BigDecimal {
        var result = lhs
        result += rhs
        return result
    }

    @inlinable
    public static func -(lhs: BigDecimal, rhs: BigDecimal) -> BigDecimal {
        var result = lhs
        result -= rhs
        return result
    }

    @inlinable
    public static func *(lhs: BigDecimal, rhs: BigDecimal) -> BigDecimal {
        var result = lhs
        result *= rhs
        return result
    }

    @inlinable
    public static func /(lhs: BigDecimal, rhs: BigDecimal) -> BigDecimal {
        var result = lhs
        result /= rhs
        return result
    }


    /// Returns the remainder of this value divided by the given value.
    ///
    /// - Parameter other: The value to use when dividing this value.
    /// - Returns: The remainder of this value divided by `other`.
    @inlinable
    public func remainder(dividingBy other: BigDecimal) -> BigDecimal {
        let scale = max(self.scale, other.scale)
        let numerator = self.integerValue
        let denominator = other.integerValue

        let result: BigInt
        if self.scale > other.scale {
            let scaledDenominator = denominator * tenToThe(power: scale - other.scale)
            result = numerator % scaledDenominator
        } else if self.scale < other.scale {
            let scaledNumerator = numerator * tenToThe(power: scale - self.scale)
            result = scaledNumerator % denominator
        } else {
            result = numerator % denominator
        }

        return .init(integerValue: result, scale: scale)
    }


    @inline(__always) @usableFromInline
    internal static func _division(numerator: BigInt, denominator: BigInt, scale: Int, maxPrecision: Int) -> BigDecimal {
        if numerator.isZero {
            return .init(integerValue: numerator, scale: 0)
        }

        switch (numerator.sign, denominator.sign) {
            case (.minus, .minus): return Self._division(numerator: -numerator, denominator: -denominator, scale: scale, maxPrecision: maxPrecision)
            case (.minus, .plus): return -Self._division(numerator: -numerator, denominator: denominator, scale: scale, maxPrecision: maxPrecision)
            case (.plus, .minus): return -Self._division(numerator: numerator, denominator: -denominator, scale: scale, maxPrecision: maxPrecision)
            case (.plus, .plus): break
        }

        var numerator = numerator
        var scale = scale

        // shift digits until numerator is larger than denominator (set scale appropriately)
        while numerator < denominator {
            scale += 1
            numerator *= 10
        }

        // first division
        var (quotient, remainder) = numerator.quotientAndRemainder(dividingBy: denominator)

        // division complete
        if remainder.isZero {
            return .init(integerValue: quotient, scale: scale)
        }

        var precision = quotient.digitCount

        // shift remainder by 1 decimal;
        // quotient will be 1 digit upon next division
        remainder *= 10

        while !remainder.isZero && precision < maxPrecision {
            let (q, r) = remainder.quotientAndRemainder(dividingBy: denominator)
            quotient = quotient * 10 + q
            remainder = r * 10

            precision += 1
            scale += 1
        }

        if !remainder.isZero {
            // round final number with remainder
            quotient += getRoundingTerm(of: remainder / denominator)
        }

        return .init(integerValue: quotient, scale: scale)
    }
}


extension BigDecimal: ExpressibleByIntegerLiteral {
    @inlinable
    public init(integerLiteral value: Int64) {
        self.init(value)
    }
}


extension BigDecimal: ExpressibleByFloatLiteral {
    @inlinable
    public init(floatLiteral value: Double) {
        self.init(value)!
    }
}


extension BigDecimal: LosslessStringConvertible {
    @inlinable
    public init?(_ description: String) {
        try? self.init(fromString: description)
    }

    @inlinable
    public var description: String {
        var absoluteIntegerValue = self.integerValue.magnitude.description

        let (before, after): (String, String) = {
            if self.scale >= absoluteIntegerValue.count {
                let after = String(repeating: "0", count: self.scale - absoluteIntegerValue.count) + absoluteIntegerValue
                return ("0", after)
            } else {
                let location = absoluteIntegerValue.count - self.scale
                if location > absoluteIntegerValue.count {
                    let zeros = String(repeating: "0", count: location - absoluteIntegerValue.count)
                    return (absoluteIntegerValue + zeros, "")
                } else {
                    let afterLength = absoluteIntegerValue.count - location
                    let after = absoluteIntegerValue.suffix(afterLength)
                    absoluteIntegerValue.removeLast(afterLength)
                    return (absoluteIntegerValue, String(after))
                }
            }
        }()

        let sign = self.sign == .minus ? "-" : ""

        return sign + (after.isEmpty ? before : "\(before).\(after)")
    }
}

extension BigDecimal: Hashable {
    @inlinable
    public func hash(into hasher: inout Hasher) {
        guard !self.integerValue.isZero else {
            "0".hash(into: &hasher)
            0.hash(into: &hasher)
            return
        }

        var decimalString = self.integerValue.description
        var scale = self.scale
        if scale > 0 {
            var count = -1
            decimalString.removeLast {
                count += 1
                return $0 == "0" && count < scale
            }

            scale -= count
        } else if scale < 0 {
            decimalString.append(contentsOf: String(repeating: "0", count: Int(scale.magnitude)))
            scale = 0
        }

        decimalString.hash(into: &hasher)
        scale.hash(into: &hasher)
    }
}

extension BigDecimal: Codable {
    @inlinable
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        let string = try container.decode(String.self)

        try self.init(fromString: string)
    }

    @inlinable
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        try container.encode(self.description)
    }
}


#if swift(>=5.5)
extension BigDecimal: Sendable {}
#endif
