# BigDecimal

This package provides arbitrary-precision decimal numbers for Swift.

## Installation

You can install this package by adding the following line to the dependencies of your package:

```swift
.package(url: "https://github.com/Zollerboy1/BigDecimal.git", from: "1.0.0")
```

Then you can add the `BigDecimal` product to your target's dependencies.

## Usage

Import the `BigDecimal` module.

Now you can use the `BigDecimal` type almost like a floating point type:

```swift
let a = BigDecimal(3)
let b: BigDecimal = 1.25e-1
let c = BigDecimal("""
    3.1415926535897932384\
    626433832795028841971\
    693993751058209749445\
    923078164062862089986\
    280348253421170679
    """)!

print(a + b)
// Prints '3.125'

print(a * c)
// Prints '9.4247779607693797153879301498385086525915081981253174629248337769234492188586269958841044760263512037'
```
