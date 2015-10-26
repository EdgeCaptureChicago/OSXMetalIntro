//
//  ViewController.m
//  WobblyVertexTextured
//
//  Copyright © 2015 Edge Capture Software LLC. All rights reserved.
//

#import "ViewController.h"

struct Pixel {
    union {
        uint8_t r, g, b, a;
        uint32_t rgba;
    };
} __attribute__((packed));

static float _positionBuffer[] = {
    -0.5,  0.5, 0, 1,
    -0.5, -0.5, 0, 1,
    0.5, -0.5, 0, 1,
    -0.5, 0.5, 0, 1,
    0.5, 0.5, 0, 1,
    0.5, -0.5, 0, 1
};

static float _texCoordinates[] = {
    0.0f, 0.0f,
    0.0f, 1.0f,
    1.0f, 1.0f,
    0.0f, 0.0f,
    1.0f, 0.0f,
    1.0f, 1.0f
};

static float _wobbleParameter[] = {
    0.0f
};

struct WobbleAdjustment _adjustments[] = {
    { 0.1f, -0.1f, 0.0f, 0.0f },
    { 0.0f, 0.1f, 0.0f, 0.0f },
    { -0.1f, 0.1f, 0.0f, 0.0f },
    { 0.1f, -0.1f, 0.0f, 0.0f },
    { 0.0f, 0.1f, 0.0f, 0.0f },
    { -0.1f, 0.1f, 0.0f, 0.0f }
};

@interface ViewController ()

@property (nonatomic) id< MTLDevice > defaultMetalDevice;
@property (nonatomic) id< MTLCommandQueue > commandQueue;
@property (nonatomic) id< MTLLibrary > metalLibrary;
@property (nonatomic) id< MTLRenderPipelineState > pipelineState;

@property (nonatomic) id< MTLBuffer > vertexBuffer;
@property (nonatomic) id< MTLBuffer > wobbleAdjustments;
@property (nonatomic) id< MTLBuffer > textureCoordinates;

@property (nonatomic) id< MTLTexture > brianZableTexture;
@property (nonatomic) id< MTLSamplerState > brianZableSamplerState;

@property (nonatomic, strong) MTLRenderPipelineDescriptor *pipelineDescriptor;
@property (nonatomic,strong) CAMetalLayer *metalLayer;

@property (nonatomic,strong) NSDate *startTime;

@end

@implementation ViewController {
    dispatch_semaphore_t _gpuResourceSemaphore;
}

-(void) initTextureComponents {
    NSImage *image = [NSImage imageNamed:@"BrianZable.jpg"];
    
    NSRect pRect = NSMakeRect( 0, 0, [image size].width, [image size].height);
    CGImageRef imageRef = [image CGImageForProposedRect:&pRect context:NULL hints:0];
    
    // Create a suitable bitmap context for extracting the bits of the image
    NSUInteger width = CGImageGetWidth(imageRef);
    NSUInteger height = CGImageGetHeight(imageRef);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    struct Pixel *rawData = (struct Pixel *) calloc( height * width, sizeof( struct Pixel ) );
    
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;

    CGContextRef context = CGBitmapContextCreate( (uint8_t *) rawData, width, height,
                                                 bitsPerComponent, bytesPerRow, colorSpace,
                                                 kCGImageAlphaNoneSkipLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    
    CGContextDrawImage( context, CGRectMake(0, 0, width, height), imageRef );
    CGContextRelease( context );
    
    MTLTextureDescriptor *brianZableTextureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA8Unorm width:width height:height mipmapped:YES];
    self.brianZableTexture = [self.defaultMetalDevice newTextureWithDescriptor:brianZableTextureDescriptor];
    
    MTLRegion region = MTLRegionMake2D(0, 0, width, height);
    [self.brianZableTexture replaceRegion:region mipmapLevel:0 withBytes:rawData bytesPerRow:bytesPerRow];
    
    MTLSamplerDescriptor *samplerDescriptor = [MTLSamplerDescriptor new];
    samplerDescriptor.minFilter = MTLSamplerMinMagFilterNearest;
    samplerDescriptor.magFilter = MTLSamplerMinMagFilterLinear;
    self.brianZableSamplerState = [self.defaultMetalDevice newSamplerStateWithDescriptor:samplerDescriptor];

    free( rawData );
}

- (void) viewDidLoad {
    [super viewDidLoad];
    
    ((MTKView *)self.view).delegate = self;
    _gpuResourceSemaphore = dispatch_semaphore_create(3);
    
    self.startTime = [NSDate date];
    
    self.defaultMetalDevice = MTLCreateSystemDefaultDevice();
    self.commandQueue = [self.defaultMetalDevice newCommandQueue];
    self.vertexBuffer = [self.defaultMetalDevice newBufferWithBytes:_positionBuffer length:sizeof(_positionBuffer) options:0];
    self.wobbleAdjustments = [self.defaultMetalDevice newBufferWithBytes:_adjustments length:sizeof(_adjustments) options:0];
    self.textureCoordinates = [self.defaultMetalDevice newBufferWithBytes:_texCoordinates length:sizeof(_texCoordinates) options:0];
    
    self.metalLayer = (CAMetalLayer *)[self.view layer];;
    self.metalLayer.device = self.defaultMetalDevice;
    self.metalLayer.pixelFormat = MTLPixelFormatBGRA8Unorm;
    
    self.metalLibrary = [self.defaultMetalDevice newDefaultLibrary];
    
    self.pipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    self.pipelineDescriptor.vertexFunction = [self.metalLibrary newFunctionWithName:@"wobblyVertexTexturedVertexShader"];
    self.pipelineDescriptor.fragmentFunction = [self.metalLibrary newFunctionWithName:@"wobblyVertexTexturedFragmentShader"];
    self.pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    
    NSError *error = nil;
    self.pipelineState = [self.defaultMetalDevice newRenderPipelineStateWithDescriptor:self.pipelineDescriptor error:&error];
    [self initTextureComponents];
    
    // Do any additional setup after loading the view.
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
    
    // Update the view, if already loaded.
}

#pragma mark - MTKViewDelegate methods

-(void) drawInMTKView:(MTKView *)view {
    @autoreleasepool {
        _wobbleParameter[0] = (float) [[NSDate date] timeIntervalSinceDate:self.startTime];
        [self render];
    }
}

-(void) mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {
    // FIX-ME:  This is left as an exercise for the reader.  :-)
}

-(void) render {
    dispatch_semaphore_wait( _gpuResourceSemaphore, DISPATCH_TIME_FOREVER );
    
    id< CAMetalDrawable > drawable = [(CAMetalLayer *)self.view.layer nextDrawable];
    id< MTLTexture > framebufferTexture = drawable.texture;
    
    MTLRenderPassDescriptor *renderPass = [MTLRenderPassDescriptor renderPassDescriptor];
    renderPass.colorAttachments[0].texture = framebufferTexture;
    renderPass.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 0.0);
    renderPass.colorAttachments[0].storeAction = MTLStoreActionStore;
    renderPass.colorAttachments[0].loadAction = MTLLoadActionClear;
    
    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
    id<MTLRenderCommandEncoder> commandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPass];
    
    struct RenderTargetDimensions targetDimensions;
    targetDimensions.width = self.view.frame.size.width * [NSScreen mainScreen].backingScaleFactor;
    targetDimensions.height = self.view.frame.size.height * [NSScreen mainScreen].backingScaleFactor;
    
    id< MTLBuffer > wobbleIndex = [self.defaultMetalDevice newBufferWithBytes:_wobbleParameter length:sizeof( _wobbleParameter ) options:0];

    
    [commandEncoder setRenderPipelineState:self.pipelineState];
    [commandEncoder setVertexBuffer:self.vertexBuffer offset:0 atIndex:0];
    [commandEncoder setVertexBuffer:self.wobbleAdjustments offset:0 atIndex:1];
    [commandEncoder setVertexBuffer:self.textureCoordinates offset:0 atIndex:2];
    [commandEncoder setVertexBuffer:wobbleIndex offset:0 atIndex:3];
    
    
    [commandEncoder setFragmentTexture:self.brianZableTexture atIndex:0];
    [commandEncoder setFragmentSamplerState:self.brianZableSamplerState atIndex:0];
    
    
    [commandEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6 instanceCount:1];
    [commandEncoder endEncoding];
    
    [commandBuffer presentDrawable:drawable];
    [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> cmdBuffer) {
        dispatch_semaphore_signal( _gpuResourceSemaphore );
    }];
    [commandBuffer commit];
}

@end

