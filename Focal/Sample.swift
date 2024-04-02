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
import simd

struct Vertex {
    var position: SIMD4<Float>
    var textureCoordinates: SIMD2<Float>
}

class SamplingDelegate: NSObject, MTKViewDeviceAwareDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {
    var textureCache: CVMetalTextureCache!
    var currentFrameTexture: MTLTexture?
    
    var device: (any MTLDevice)!
    var loader: MTKTextureLoader
    var commandQueue: MTLCommandQueue!
    var pipelineState: MTLRenderPipelineState!
    var replacementTexture: MTLTexture!
    
    var vertexFrame: MTLBuffer?
    var uniformFrame: MTLBuffer?
    
    var captureSession = AVCaptureSession()
    var currentInputDevice: AVCaptureDevice?
    var currentInputMirrored = false
    
    required init(with device: any MTLDevice) {
        self.device = device
        self.loader = MTKTextureLoader(device: device)
        CVMetalTextureCacheCreate(nil, nil, device, nil, &textureCache)
        
        let url = Bundle.main.url(forResource: "original", withExtension: "png")!
        replacementTexture = try? loader.newTexture(URL: url,
                                                    options: [.SRGB: false, .textureStorageMode: MTLStorageMode.shared.rawValue])
        
        super.init()
        
        Task { await setupMetal(); await setupCapture() }
    }
    
    func changeReplacementTexture(_ textureName: String) {
        let url = Bundle.main.url(forResource: textureName, withExtension: "png")!
        replacementTexture = try? loader.newTexture(URL: url,
                                                    options: [.SRGB: false, .textureStorageMode: MTLStorageMode.shared.rawValue])
    }
    
    func setupMetal() async {
        guard let library = device.makeDefaultLibrary(),
              let vertex = library.makeFunction(name: "vertexSampling"),
              let fragment = library.makeFunction(name: "fragmentSampling") else {
            fatalError("Metal library did not properly compile")
        }
        
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertex
        descriptor.fragmentFunction = fragment
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        commandQueue = device.makeCommandQueue()
        pipelineState = try? await device.makeRenderPipelineState(descriptor: descriptor)
    }
    
    func setupCapture() async {
        if AVCaptureDevice.authorizationStatus(for: .video) == .notDetermined {
            await AVCaptureDevice.requestAccess(for: .video) // TODO: handle if we are denied, and remedy that
        }
        
        #if os(macOS)
        let types: [AVCaptureDevice.DeviceType] = [.external, .continuityCamera, .deskViewCamera, .builtInWideAngleCamera]
        #else
        let types: [AVCaptureDevice.DeviceType] = [.builtInDualWideCamera, .builtInTelephotoCamera, .builtInDualCamera, .builtInUltraWideCamera, .external, .continuityCamera]
        #endif
        
        let discovery = AVCaptureDevice.DiscoverySession(
            deviceTypes: types,
            mediaType: .video,
            position: .unspecified)
        
        // TODO: allow selection of device, we'll just get the first here
        // TODO: Allow for screen capture instead of camera
        
        var input = discovery.devices.first
        var activeFormat = input?.activeFormat
        
        captureSession.sessionPreset = .hd1920x1080
        
        for device in discovery.devices {
            for format in device.formats {
                let ranges = format.videoSupportedFrameRateRanges.map { $0.maxFrameRate }.filter { $0 >= 59.0 }
                if !ranges.isEmpty { input = device; activeFormat = format }
            }
        }
        
        if let input = input,
           let activeFormat = activeFormat,
           let wrappedInput = try? AVCaptureDeviceInput(device: input) {
            captureSession.addInput(wrappedInput)
            currentInputDevice = input
            if input.position == .unspecified || input.position == .front { currentInputMirrored = true }
            
            try? input.lockForConfiguration()
            
            input.activeFormat = activeFormat
            input.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: 60)
            input.activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: 60)
            
            input.unlockForConfiguration()
        }
        
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "ai.binarysky.samplingDelegate", qos: .userInteractive))
        output.alwaysDiscardsLateVideoFrames = true
        output.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as String): kCVPixelFormatType_32BGRA]
        captureSession.addOutput(output)
        
        captureSession.startRunning()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {        
        let frame = (width: Float(view.frame.size.width), height: Float(view.frame.size.height))
        let vertices: [Vertex] = [
            .init(position: SIMD4(0.0, 0.0, 0.0, 1.0), textureCoordinates: SIMD2(0.0, 0.0)),
            .init(position: SIMD4(frame.width, 0.0, 0.0, 1.0), textureCoordinates: SIMD2(1.0, 0.0)),
            .init(position: SIMD4(0.0, frame.height, 0.0, 1.0), textureCoordinates: SIMD2(0.0, 1.0)),
            .init(position: SIMD4(frame.width, frame.height, 0.0, 1.0), textureCoordinates: SIMD2(1.0, 1.0))
        ]
        
        let uniforms: [Float] = [2.0 / frame.width, 0, 0, 0,
                                 0, -2.0 / frame.height, 0, 0,
                                 0, 0, 1, 0,
                                 -1, 1, 0, 1]
        
        vertexFrame = device.makeBuffer(bytes: vertices, length: MemoryLayout<Vertex>.stride * vertices.count)
        uniformFrame = device.makeBuffer(bytes: uniforms, length: MemoryLayout<Float>.size * 16)
    }
    
    func draw(in view: MTKView) {
        #if os(iOS)
        view.layer.transform = CATransform3DMakeRotation(.pi / 2, 0, 0, 1)
        #endif
        
        guard let drawable = view.currentDrawable,
              let currentFrameTexture = self.currentFrameTexture,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let passDescriptor = view.currentRenderPassDescriptor else { return }
        
        passDescriptor.colorAttachments[0].texture = drawable.texture
        passDescriptor.colorAttachments[0].storeAction = .store
        passDescriptor.colorAttachments[0].loadAction = .clear
        
        guard let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: passDescriptor) else { return }
        
        commandEncoder.setRenderPipelineState(pipelineState)
        commandEncoder.setFragmentTexture(currentFrameTexture, index: 0)
        commandEncoder.setFragmentTexture(replacementTexture, index: 1)
        commandEncoder.setVertexBuffer(vertexFrame, offset: 0, index: 0)
        commandEncoder.setVertexBuffer(uniformFrame, offset: 0, index: 1)
        commandEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        
        commandEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
        
        self.currentFrameTexture = nil
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard self.currentFrameTexture == nil,
              let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        var cvTextureOut: CVMetalTexture?
        let width = CVPixelBufferGetWidth(imageBuffer)
        let height = CVPixelBufferGetHeight(imageBuffer)

        if currentInputMirrored { connection.isVideoMirrored = true }
        
        CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                  textureCache,
                                                  imageBuffer,
                                                  nil,
                                                  .bgra8Unorm,
                                                  width,
                                                  height,
                                                  0,
                                                  &cvTextureOut)

        if let cv = cvTextureOut { self.currentFrameTexture = CVMetalTextureGetTexture(cv) }
    }
}

extension AVCaptureDevice {
    @discardableResult
    func set(frameRate: Double) -> Bool {
        do { try lockForConfiguration()
            activeFormat = formats.sorted(by: { f1, f2 in
                f1.formatDescription.dimensions.height > f2.formatDescription.dimensions.height
                && f1.formatDescription.dimensions.width > f2.formatDescription.dimensions.width
            }).first { format in format.videoSupportedFrameRateRanges.contains { range in range.maxFrameRate == frameRate } } ?? activeFormat
            
            guard let range = activeFormat.videoSupportedFrameRateRanges.first,
                  range.minFrameRate...range.maxFrameRate ~= frameRate else {
                print("Requested FPS is not supported by the device's activeFormat !")
                return false
            }
            
            activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: Int32(frameRate))
            activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: Int32(frameRate))
            unlockForConfiguration()
            return true
        } catch {
            print("LockForConfiguration failed with error: \(error.localizedDescription)")
            return false
        }
    }
}
