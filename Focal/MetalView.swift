//
//  2AEE9458-839A-4DF1-B40D-07213E97B138: 15:27 3/20/24
//  MetalView.swift by Gab
//  

import MetalKit
import SwiftUI
import AVFoundation

protocol MTKViewDeviceAwareDelegate: MTKViewDelegate { var device: MTLDevice! { get }; init(with device: MTLDevice) }
struct MetalView<Delegate: MTKViewDeviceAwareDelegate> {
    var device: MTLDevice!
    var delegate: Delegate
    var mtkView: MTKView!
    
    @State private var config: Configuration
    class Configuration {
        var framebufferOnly: Bool = false
        var preferredFramesPerSecond: Int = 30
    }
}

extension MetalView {
    enum DeviceType {
        case auto
        case external
        case integrated
        case specific(MTLDevice)
    }
    
    init(_ type: DeviceType) {
        switch type {
        case .external: fallthrough // FLESH THIS OUT
        case .integrated: fallthrough // FLESH THIS OUT
        case .auto: device = MTLCreateSystemDefaultDevice()
        case .specific(let chosen): device = chosen
        }
        
        delegate = Delegate(with: device)
        config = Configuration()
        mtkView = MTKView()
    }
    
    func updateMetalValues(_ view: MTKView) {
        view.framebufferOnly = config.framebufferOnly
        view.preferredFramesPerSecond = config.preferredFramesPerSecond
        // Fill out rest of fields
    }
    
    func makeView(context: Context) -> MTKView {
        mtkView.device = self.device
        mtkView.delegate = self.delegate
        
        updateMetalValues(mtkView)
        
        return mtkView
    }
    
    func updateView(_ view: MTKView, context: Context) { updateMetalValues(view) }
}

extension MetalView {
    func framebufferOnly(_ bool: Bool) -> Self { config.framebufferOnly = bool; return self }
    func preferredFramesPerSecond(_ hz: Int) -> Self { config.preferredFramesPerSecond = hz; return self }
}

#if os(iOS)
import UIKit

extension MetalView: UIViewRepresentable {
    func makeUIView(context: Context) -> MTKView { makeView(context: context) }
    func updateUIView(_ uiView: MTKView, context: Context) { updateView(uiView, context: context) }
}
#else
import AppKit

extension MetalView: NSViewRepresentable {
    func makeNSView(context: Context) -> MTKView { makeView(context: context) }
    func updateNSView(_ nsView: MTKView, context: Context) { updateView(nsView, context: context) }
}
#endif
