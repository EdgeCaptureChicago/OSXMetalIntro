//
//  ThreadGroupComputeShader.metal
//  ThreadGroupComputeShader
//
//  Copyright © 2015 Edge Capture Software LLC. All rights reserved.
//

#include <metal_stdlib>
#include <metal_compute>
#include <metal_atomic>

using namespace metal;

kernel void accumulate( const device int *summation [[buffer(0)]], device int *outBuffer [[buffer(1)]], uint id [[ thread_position_in_grid ]] ) {
    threadgroup atomic_int group_accumulator;
    int local_accumulator = 0;
    
    // FIX-ME:  Is there a guarantee that the default constructor sets the accumulator to 0?  If so, next line not required -- hacky
    atomic_store_explicit( &group_accumulator, 0, memory_order_relaxed );
    threadgroup_barrier( mem_flags::mem_threadgroup );

    for( int i = 0; i < 8; i++ ) {
        local_accumulator += summation[id*8 + i];
    }
    
    atomic_fetch_add_explicit( &group_accumulator, local_accumulator, memory_order_relaxed );
    threadgroup_barrier( mem_flags::mem_threadgroup );
    outBuffer[0] = atomic_load_explicit( &group_accumulator, memory_order_relaxed );
}
