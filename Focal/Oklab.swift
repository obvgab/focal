//
//  C7E01264-EF05-4BD6-93E8-36F187909265: 08:24 3/16/24
//  Oklab.swift by Gab
//  

import SwiftUI
import MLX

// Oklab Colorspace Implementation: Light, a-axis, b-axis - Non Polar
struct Oklab {
    // This was originally an extension of Color, but we need to store Lab values raw for distance
    /// SwiftUI Color construction of the Oklab color
    let swiftUI: Color
    
    /// A value in the range 0 to 1 that indicates the amount of light in the color. A value of 0 is close to black, and a value of 1 is as bright as possible.
    let lightness: Double
    /// A value that indicates how red or green a color is perceived. Negative values are more green while positive values are more red (unbounded).
    let a: Double
    /// A value that indicates how blue or yellow a color is perceived. Negative values are more blue while positive values are more yellow (unbounded).
    let b: Double
    /// An optional degree of opacity, given in the range 0 to 1. A value of 0 means 100% transparency, while a value of 1 means 100% opacity.
    let opacity: Double
    
    // Matrices sourced from Björn's blog posts
    enum Matrices {
        public static let oklabToLms = MLXArray(
            converting: [
                +1.0000000000, +0.3963377774, +0.2158037573,
                +1.0000000000, -0.1055613458, -0.0638541728,
                +1.0000000000, -0.0894841775, -1.2914855480
            ],
            [3, 3]
        )
        
        public static let lmsToLinearSrgb = MLXArray(
            converting: [
                +4.0767416621, -3.3077115913, +0.2309699292,
                -1.2684380046, +2.6097574011, -0.3413193965,
                -0.0041960863, -0.7034186147, +1.7076147010
            ],
            [3, 3]
        )
    }
    
    /// Creates a constant color from lightness, a, and b values in Oklab perceptual colorspace. Sourced from [Björn Ottoson's blog](https://bottosson.github.io/posts/oklab/).
    /// - Parameters:
    ///   - lightness: A value in the range 0 to 1 that indicates the amount of light in the color. A value of 0 is close to black, and a value of 1 is as bright as possible.
    ///   - a: A value that indicates how red or green a color is perceived. Negative values are more green while positive values are more red (unbounded).
    ///   - b: A value that indicates how blue or yellow a color is perceived. Negative values are more blue while positive values are more yellow (unbounded).
    ///   - opacity: An optional degree of opacity, given in the range 0 to 1. A value of 0 means 100% transparency, while a value of 1 means 100% opacity. The default is 1.
    init(lightness: Double, a: Double, b: Double, opacity: Double = 1) {
        let vector = Matrices.lmsToLinearSrgb * pow(Matrices.oklabToLms * MLXArray(converting: [lightness, a, b]), 3.0)
        
        let red: Double = Double(vector[0].item(Float.self))
        let green: Double = Double(vector[1].item(Float.self))
        let blue: Double = Double(vector[2].item(Float.self))
        
        self.swiftUI = Color(.sRGBLinear, red: red, green: green, blue: blue, opacity: opacity)
        self.lightness = lightness
        self.a = a
        self.b = b
        self.opacity = opacity
    }
    
    /// Find the delta E value (difference in color) to a given Color in Oklab color space. Because the color space is already
    /// perception based, weighting and correction are not necessary. This will be around 100x smaller than CIE76 dE, plus or minus some differences in calculation.
    /// This is because Lightness in Oklab is 0 to 1, instead of 0 to 100 like in CIE L\*a\*b\*. Simple implementation following
    /// [svgeesus's notes.](https://github.com/svgeesus/svgeesus.github.io/blob/master/Color/OKLab-notes.md)
    /// Generally speaking, this is just Euclidean distance.
    /// - Parameters:
    ///   - from: a Color being compared
    ///   - to: a Color to compare against
    /// - Returns: delta E value between the two values
    static func oklabColorDifference(_ from: Oklab, _ to: Oklab) -> Double {
        let deltaL = from.lightness - to.lightness
        let deltaA = from.a - to.a
        let deltaB = from.b - to.b
        
        return sqrt(pow(deltaL, 2) + pow(deltaA, 2) + pow(deltaB, 2))
    }
    
    /// Find the delta E value (difference in color) to a given Color in Oklab color space. Because the color space is already
    /// perception based, weighting and correction are not necessary. This will be around 100x smaller than CIE76 dE, plus or minus some differences in calculation.
    /// This is because Lightness in Oklab is 0 to 1, instead of 0 to 100 like in CIE L\*a\*b\*. Simple implementation following
    /// [svgeesus's notes.](https://github.com/svgeesus/svgeesus.github.io/blob/master/Color/OKLab-notes.md)
    /// Generally speaking, this is just Euclidean distance.
    /// - Parameter to: a Color to compare against
    /// - Returns: delta E value between the two values
    func oklabColorDifferenceTo(_ to: Oklab) -> Double { return Oklab.oklabColorDifference(self, to) }
}
