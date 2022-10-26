import BigInt

@usableFromInline
internal let log2_10 = 3.32192809488736234787031942948939018

extension BigInt {
    @inline(__always) @usableFromInline
    internal var digitCount: Int {
        if self.isZero {
            return 1
        }
        // guess number of digits based on number of bits in UInt
        var digits = Int(Double(self.magnitude.bitWidth) / log2_10)
        var number = tenToThe(power: digits)
        while self >= number {
            number *= 10;
            digits += 1;
        }

        return digits
    }
}
