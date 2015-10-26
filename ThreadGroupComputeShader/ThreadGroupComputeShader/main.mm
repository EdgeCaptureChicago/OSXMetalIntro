//
//  main.m
//  ComputeShaderDemo
//
//  Copyright © 2015 Edge Capture Software LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

#include <iostream>
#include <algorithm>

int main(int argc, const char * argv[]) {
    int const randomIntegerBlockSize( 64 );
    std::unique_ptr< int [] > randomIntegers( new int [ randomIntegerBlockSize ] );
    for( int i = 0; i < randomIntegerBlockSize; i++ ) {
        // randomIntegers[ i ] = rand();
        randomIntegers[i] = i;
    }
    
    int64_t accum = 0;
    for( int i = 0; i < randomIntegerBlockSize; i++ ) {
        accum += randomIntegers[i];
    }
    std::cout << "Accumulator: " << accum << std::endl;
    
    int debugOutBuffer = 0;
    
    @autoreleasepool {
        id< MTLDevice > metalDevice = MTLCreateSystemDefaultDevice();
        id< MTLLibrary > metalLibrary = [metalDevice newDefaultLibrary];
        id< MTLCommandQueue > commandQueue = [metalDevice newCommandQueue];

        id< MTLBuffer > randomIntegerBuffer = [metalDevice newBufferWithBytes:randomIntegers.get() length:sizeof(int) * randomIntegerBlockSize options:0];
        id< MTLBuffer > outputBuffer = [metalDevice newBufferWithBytes:&debugOutBuffer length:sizeof(debugOutBuffer) options:0];
        
        NSError *error = nil;
        id< MTLFunction > accumulateFunction = [metalLibrary newFunctionWithName:@"accumulate"];
        id< MTLComputePipelineState > pipelineDesc1 = [metalDevice newComputePipelineStateWithFunction:accumulateFunction error:&error];
        id< MTLCommandBuffer > commandBuffer = [commandQueue commandBuffer];

        id< MTLComputeCommandEncoder > firstCommandEncoder = [commandBuffer computeCommandEncoder];
        
        // Thread Execution Width
        auto threadExecutionWidth = [pipelineDesc1 threadExecutionWidth];
        // std::cout << "Thread Execution width on Device: " << threadExecutionWidth << std::endl;
        
        MTLSize threadsPerGroupCmd1 = MTLSizeMake( threadExecutionWidth/8, 1, 1 );
        MTLSize numThreadgroupsCmd1 = MTLSizeMake( 1, 1, 1 );
        
        [firstCommandEncoder setComputePipelineState:pipelineDesc1];
        [firstCommandEncoder setBuffer:randomIntegerBuffer offset:0 atIndex:0];
        [firstCommandEncoder setBuffer:outputBuffer offset:0 atIndex:1];

        [firstCommandEncoder dispatchThreadgroups:numThreadgroupsCmd1 threadsPerThreadgroup:threadsPerGroupCmd1];
        [firstCommandEncoder endEncoding];
        
        [commandBuffer commit];
        [commandBuffer waitUntilCompleted];
        
        uint64_t *result = (uint64_t *)[ outputBuffer contents ];
        
        std::cout << "CPU Calculated Sum: " << accum << std::endl;
        std::cout << "GPU Calculated Sum: " << *result << std::endl;
    }
    return 0;
}
