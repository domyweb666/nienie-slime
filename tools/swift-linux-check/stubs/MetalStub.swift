// Stand-ins for Metal, Core Graphics and the little of Core Animation that JellySkin.swift uses (type-check only).
import UIKit
public enum MTLPixelFormat { case r8Unorm, r16Float, bgra8Unorm }
public struct MTLTextureUsage: OptionSet { public let rawValue: Int; public init(rawValue: Int) { self.rawValue = rawValue }; public static let shaderRead = MTLTextureUsage(rawValue: 1), renderTarget = MTLTextureUsage(rawValue: 4) }
public enum MTLStorageMode { case shared, `private`, memoryless }
public enum MTLTextureType { case type2D, type2DMultisample }
public enum MTLBlendOperation { case add, min, max }
public enum MTLIndexType { case uint16, uint32 }
public struct MTLResourceOptions: OptionSet { public let rawValue: UInt; public init(rawValue: UInt) { self.rawValue = rawValue }; public static let storageModeShared = MTLResourceOptions(rawValue: 1) }
public struct MTLScissorRect { public init(x: Int, y: Int, width: Int, height: Int) {} }
public protocol MTLBuffer: AnyObject { var length: Int { get }; func contents() -> UnsafeMutableRawPointer }
public struct MTLRegion {}
public func MTLRegionMake2D(_ x: Int, _ y: Int, _ w: Int, _ h: Int) -> MTLRegion { MTLRegion() }
public protocol MTLTexture: AnyObject { var width: Int { get }; var height: Int { get }; func replace(region: MTLRegion, mipmapLevel: Int, withBytes: UnsafeRawPointer, bytesPerRow: Int) }
public final class MTLTextureDescriptor { public init() {}; public var textureType = MTLTextureType.type2D, pixelFormat = MTLPixelFormat.bgra8Unorm; public var width = 1, height = 1, sampleCount = 1; public static func texture2DDescriptor(pixelFormat: MTLPixelFormat, width: Int, height: Int, mipmapped: Bool) -> MTLTextureDescriptor { MTLTextureDescriptor() }; public var usage: MTLTextureUsage = []; public var storageMode = MTLStorageMode.shared }
public protocol MTLFunction: AnyObject {}
public protocol MTLLibrary: AnyObject { func makeFunction(name: String) -> MTLFunction? }
public protocol MTLRenderPipelineState: AnyObject {}
public protocol MTLSamplerState: AnyObject {}
public enum MTLSamplerMinMagFilter { case nearest, linear }
public enum MTLSamplerAddressMode { case clampToEdge, `repeat` }
public final class MTLSamplerDescriptor { public init() {}; public var minFilter = MTLSamplerMinMagFilter.linear, magFilter = MTLSamplerMinMagFilter.linear; public var sAddressMode = MTLSamplerAddressMode.clampToEdge, tAddressMode = MTLSamplerAddressMode.clampToEdge }
public final class MTLRenderPipelineColorAttachmentDescriptor { public var pixelFormat = MTLPixelFormat.bgra8Unorm; public var isBlendingEnabled = false; public var rgbBlendOperation = MTLBlendOperation.add, alphaBlendOperation = MTLBlendOperation.add }
public final class MTLRenderPipelineColorAttachmentDescriptorArray { public subscript(i: Int) -> MTLRenderPipelineColorAttachmentDescriptor { MTLRenderPipelineColorAttachmentDescriptor() } }
public final class MTLRenderPipelineDescriptor { public init() {}; public var rasterSampleCount = 1; public var vertexFunction: MTLFunction?, fragmentFunction: MTLFunction?; public var colorAttachments: MTLRenderPipelineColorAttachmentDescriptorArray { MTLRenderPipelineColorAttachmentDescriptorArray() } }
public struct MTLClearColor { public init(red: Double, green: Double, blue: Double, alpha: Double) {} }
public enum MTLLoadAction { case clear, load, dontCare }
public enum MTLStoreAction { case store, dontCare, multisampleResolve }
public final class MTLRenderPassColorAttachmentDescriptor { public var texture: MTLTexture?, resolveTexture: MTLTexture?; public var loadAction = MTLLoadAction.clear; public var clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0); public var storeAction = MTLStoreAction.store }
public final class MTLRenderPassColorAttachmentDescriptorArray { public subscript(i: Int) -> MTLRenderPassColorAttachmentDescriptor { MTLRenderPassColorAttachmentDescriptor() } }
public final class MTLRenderPassDescriptor { public init() {}; public var colorAttachments: MTLRenderPassColorAttachmentDescriptorArray { MTLRenderPassColorAttachmentDescriptorArray() } }
public enum MTLPrimitiveType { case triangle, triangleStrip }
public protocol MTLRenderCommandEncoder: AnyObject {
    func setRenderPipelineState(_ s: MTLRenderPipelineState)
    func setFragmentTexture(_ t: MTLTexture?, index: Int)
    func setFragmentSamplerState(_ s: MTLSamplerState?, index: Int)
    func setFragmentBytes(_ b: UnsafeRawPointer, length: Int, index: Int)
    func drawPrimitives(type: MTLPrimitiveType, vertexStart: Int, vertexCount: Int)
    func drawPrimitives(type: MTLPrimitiveType, vertexStart: Int, vertexCount: Int, instanceCount: Int)
    func drawPrimitives(type: MTLPrimitiveType, vertexStart: Int, vertexCount: Int, instanceCount: Int, baseInstance: Int)
    func drawIndexedPrimitives(type: MTLPrimitiveType, indexCount: Int, indexType: MTLIndexType, indexBuffer: MTLBuffer, indexBufferOffset: Int)
    func setVertexBuffer(_ b: MTLBuffer?, offset: Int, index: Int)
    func setVertexBytes(_ b: UnsafeRawPointer, length: Int, index: Int)
    func setScissorRect(_ r: MTLScissorRect)
    func endEncoding()
}
public protocol MTLCommandBuffer: AnyObject { func makeRenderCommandEncoder(descriptor: MTLRenderPassDescriptor) -> MTLRenderCommandEncoder?; func addCompletedHandler(_ block: @escaping (MTLCommandBuffer) -> Void); func commit(); func waitUntilScheduled() }
public protocol MTLCommandQueue: AnyObject { func makeCommandBuffer() -> MTLCommandBuffer? }
public protocol MTLDevice: AnyObject {
    func makeCommandQueue() -> MTLCommandQueue?
    func makeDefaultLibrary() -> MTLLibrary?
    func makeRenderPipelineState(descriptor: MTLRenderPipelineDescriptor) throws -> MTLRenderPipelineState
    func makeSamplerState(descriptor: MTLSamplerDescriptor) -> MTLSamplerState?
    func makeTexture(descriptor: MTLTextureDescriptor) -> MTLTexture?
    func makeBuffer(bytes: UnsafeRawPointer, length: Int, options: MTLResourceOptions) -> MTLBuffer?
    func makeBuffer(length: Int, options: MTLResourceOptions) -> MTLBuffer?
    func supportsTextureSampleCount(_ n: Int) -> Bool
}
public func MTLCreateSystemDefaultDevice() -> MTLDevice? { nil }
public protocol CAMetalDrawable: AnyObject { var texture: MTLTexture { get }; func present() }
public final class CAMetalLayer: CALayer {
    public var device: MTLDevice?
    public var pixelFormat = MTLPixelFormat.bgra8Unorm
    public var framebufferOnly = true, presentsWithTransaction = false
    public var drawableSize = CGSize.zero
    public func nextDrawable() -> CAMetalDrawable? { nil }
}
