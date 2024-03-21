//
//  ACB5CB78-684A-4591-8662-7604943476CC: 11:39 3/20/24
//  Sample.swift by Gab
//  

// Should sample Nvidia's daltonization technique for deutan and protan
// Figure out Tritan later

// Figure out Nvidia's method so we can precompute lower levels of CVD
// Figure out how to use Oklab (perceptual) instead of YCbCr (linear) color space
// ^ This should also help with luminance issues and may make computation simpler

import MetalKit
import AVFoundation

class SamplingDelegate: NSObject, MTKViewDeviceAwareDelegate {
    var device: (any MTLDevice)!
    
    required init(with device: any MTLDevice) {}
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
    
    func draw(in view: MTKView) {}
}
