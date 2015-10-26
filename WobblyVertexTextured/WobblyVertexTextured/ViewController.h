//
//  ViewController.h
//  WobblyVertexTextured
//
//  Copyright © 2015 Edge Capture Software LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/CAMetalLayer.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>

struct WobbleAdjustment {
    float adjustment[4];
};

struct RenderTargetDimensions {
    int width;
    int height;
};

@interface ViewController : NSViewController <MTKViewDelegate>


@end

