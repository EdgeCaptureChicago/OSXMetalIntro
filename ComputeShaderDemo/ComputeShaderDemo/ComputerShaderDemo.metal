//
//  ComputerShaderDemo.metal
//  ComputeShaderDemo
//
//  Copyright © 2015 Edge Capture Software LLC. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

kernel void accumulate( const device int *summation [[buffer(0)]], device int *outBuffer [[buffer(1)]], uint id [[ thread_position_in_grid ]] ) {
    size_t accumulator = 0;

    for( int i = 0; i < 8; i++ ) {
        accumulator += summation[id*8 + i];
    }
    outBuffer[ id ] = accumulator;
}

kernel void merge( const device int *partialSums [[buffer(0)]], device int *accumulatorBuffer [[buffer(1)]], uint id [[ thread_position_in_grid ]] ) {
    size_t accumulator = 0;
  
    for( int i = 0; i < 8; i++ ) {
        accumulator += partialSums[i];
    }
    
    *((device size_t *) accumulatorBuffer) = accumulator;
}

