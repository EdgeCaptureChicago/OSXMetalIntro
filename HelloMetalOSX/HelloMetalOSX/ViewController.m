//
//  ViewController.m
//  HelloMetalOSX
//
//  Copyright © 2015 Edge Capture Software LLC. All rights reserved.
//

#import "ViewController.h"

static float _positionBuffer[] = {
    0.0,  0.5, 0, 1,
    -0.5, -0.5, 0, 1,
    0.5, -0.5, 0, 1,
};

@interface ViewController ()

@property (nonatomic) id< MTLDevice > defaultMetalDevice;
@property (nonatomic) id< MTLCommandQueue > commandQueue;
@property (nonatomic) id< MTLBuffer > vertexBuffer;
@property (nonatomic) id< MTLLibrary > metalLibrary;
@property (nonatomic) id< MTLRenderPipelineState > pipelineState;

@property (nonatomic, strong) MTLRenderPipelineDescriptor *pipelineDescriptor;
@property (nonatomic,strong) CAMetalLayer *metalLayer;

@end

@implementation ViewController {
    dispatch_semaphore_t _gpuResourceSemaphore;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    ((MTKView *)self.view).delegate = self;
    _gpuResourceSemaphore = dispatch_semaphore_create(3);

    self.defaultMetalDevice = MTLCreateSystemDefaultDevice();
    self.commandQueue = [self.defaultMetalDevice newCommandQueue];
    self.vertexBuffer = [self.defaultMetalDevice newBufferWithBytes:_positionBuffer length:sizeof(_positionBuffer) options:0];
    
    self.metalLayer = (CAMetalLayer *)[self.view layer];;
    self.metalLayer.device = self.defaultMetalDevice;
    self.metalLayer.pixelFormat = MTLPixelFormatBGRA8Unorm;
    
    self.metalLibrary = [self.defaultMetalDevice newDefaultLibrary];
    
    self.pipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    self.pipelineDescriptor.vertexFunction = [self.metalLibrary newFunctionWithName:@"helloMetalVertexShader"];
    self.pipelineDescriptor.fragmentFunction = [self.metalLibrary newFunctionWithName:@"helloMetalFragmentShader"];
    self.pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    
    NSError *error = nil;
    self.pipelineState = [self.defaultMetalDevice newRenderPipelineStateWithDescriptor:self.pipelineDescriptor error:&error];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
}

#pragma mark - MTKViewDelegate methods

-(void) drawInMTKView:(MTKView *)view {
    @autoreleasepool {
        [self render];
    }
}

-(void) mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {
    // FIX-ME:  This is left as an exercise for the reader.  (This will be mentioned
    // in the slides accompanying the presentation.)
}

-(void) render {
    dispatch_semaphore_wait( _gpuResourceSemaphore, DISPATCH_TIME_FOREVER );
    
    id< CAMetalDrawable > drawable = [(CAMetalLayer *)self.view.layer nextDrawable];
    id< MTLTexture > framebufferTexture = drawable.texture;
    
    MTLRenderPassDescriptor *renderPass = [MTLRenderPassDescriptor renderPassDescriptor];
    renderPass.colorAttachments[0].texture = framebufferTexture;
    renderPass.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 1);
    renderPass.colorAttachments[0].storeAction = MTLStoreActionStore;
    renderPass.colorAttachments[0].loadAction = MTLLoadActionClear;
    
    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
    id<MTLRenderCommandEncoder> commandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPass];
    
    [commandEncoder setRenderPipelineState:self.pipelineState];
    [commandEncoder setVertexBuffer:self.vertexBuffer offset:0 atIndex:0];
    
    [commandEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3 instanceCount:1];
    [commandEncoder endEncoding];
    
    [commandBuffer presentDrawable:drawable];
    
    [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> cmdBuffer) {
        dispatch_semaphore_signal( _gpuResourceSemaphore );
    }];
    
    [commandBuffer commit];
}

@end
