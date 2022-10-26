import BigInt
import Numerics

extension BigDecimal {
    @inlinable
    public init<T>(_ source: T) where T: BinaryInteger {
        self.init(integerValue: BigInt(source), scale: 0)
    }

    @inlinable
    public init?<T>(_ source: T) where T: BinaryFloatingPoint, T: CustomStringConvertible {
        self.init(source.description)
    }
}

extension BinaryInteger {
    @inlinable
    public init(_ source: BigDecimal) {
        self.init(source.withScale(0).integerValue)
    }

    @inlinable
    public init?(exactly source: BigDecimal) {
        guard let doubleValue = Double.init(exactly: source) else {
            return nil
        }

        self.init(exactly: doubleValue)
    }
}

extension Float {
    @inlinable
    public init?(exactly source: BigDecimal) {
        guard let value = Self(exactly: source.integerValue).map({ $0 * .pow(10, -source.scale) }) else {
            return nil
        }

        self = value
    }
}

extension Double {
    @inlinable
    public init?(exactly source: BigDecimal) {
        guard let value = Self(exactly: source.integerValue).map({ $0 * .pow(10, -source.scale) }) else {
            return nil
        }

        self = value
    }
}

#if (arch(i386) || arch(x86_64)) && !os(Windows) && !os(Android)
extension Float80 {
    @inlinable
    public init?(exactly source: BigDecimal) {
        guard let value = Self(exactly: source.integerValue).map({ $0 * .pow(10, -source.scale) }) else {
            return nil
        }

        self = value
    }
}
#endif
