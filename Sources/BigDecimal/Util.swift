import BigInt

@inline(__always) @usableFromInline
internal func tenToThe(power: Int) -> BigInt {
    if power < 20 {
        return .init(10).power(power)
    } else {
        let (half, remainder) = power.quotientAndRemainder(dividingBy: 16)

        var x = tenToThe(power: half)

        for _ in 0..<4 {
            x = x * x
        }

        if remainder == 0 {
            return x
        } else {
            return x * tenToThe(power: remainder)
        }
    }
}

@inline(__always) @usableFromInline
internal func getRoundingTerm(of number: BigInt) -> BigInt {
    if number.isZero {
        return 0
    }

    let digits = Int(Double(number.magnitude.bitWidth) / log2_10)
    var n = tenToThe(power: digits)

    // loop-method
    while true {
        if number < n {
            return 1
        }

        n *= 5

        if number < n {
            return 0
        }

        n *= 2
    }
}
