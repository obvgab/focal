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
    var commandQueue: MTLCommandQueue!
    var pipelineState: MTLRenderPipelineState!
    var replacementTexture: MTLTexture!
    
    var vertexFrame: MTLBuffer?
    var uniformFrame: MTLBuffer?
    
    var captureSession = AVCaptureSession()
    var currentInputDevice: AVCaptureDevice?
    var currentInputMirrored = false
    var currentInputRotationCoordinator: AVCaptureDevice.RotationCoordinator?
    
    required init(with device: any MTLDevice) {
        self.device = device
        CVMetalTextureCacheCreate(nil, nil, device, nil, &textureCache)
        
        let loader = MTKTextureLoader(device: device)
        let url = Bundle.main.url(forResource: "deuteranopia", withExtension: "png")!
        replacementTexture = try? loader.newTexture(URL: url, options: [.SRGB: false, .textureStorageMode: MTLStorageMode.shared.rawValue])
        
        super.init()
        
        Task { await setupMetal(); await setupCapture() }
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
        let types: [AVCaptureDevice.DeviceType] = [.builtInDualCamera, .builtInUltraWideCamera, .builtInTelephotoCamera, .external, .continuityCamera]
        #endif
        
        let discovery = AVCaptureDevice.DiscoverySession(
            deviceTypes: types,
            mediaType: .video,
            position: .unspecified)
        
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "ai.binarysky.samplingDelegate", qos: .userInteractive))
        output.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as String): kCVPixelFormatType_32BGRA]
        
        // TODO: allow selection of device, we'll just get the first here
        // TODO: Allow for screen capture instead of camera
        
        if let input = discovery.devices.first,
           let inputDevice = try? AVCaptureDeviceInput(device: input) {
            
            captureSession.addInput(inputDevice)
            captureSession.addOutput(output)
            currentInputDevice = input
            if input.position == .unspecified || input.position == .front { currentInputMirrored = true }
            
            captureSession.startRunning()
        }
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        guard currentInputRotationCoordinator == nil else { return }
        if let input = currentInputDevice {
            currentInputRotationCoordinator = AVCaptureDevice.RotationCoordinator(device: input, previewLayer: view.layer)
        }
        
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
