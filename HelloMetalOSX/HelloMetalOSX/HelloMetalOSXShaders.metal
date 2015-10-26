//
//  HelloMetalOSXShaders.metal
//  HelloMetalOSX
//
//  Copyright © 2015 Edge Capture Software LLC. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct HelloMetalVertexOut {
    float4 position [[ position ]];
    float4 color;
};

vertex HelloMetalVertexOut helloMetalVertexShader( device packed_float4 *vertexArray [[ buffer(0) ]], unsigned int vertexIndex [[ vertex_id ]] ) {
    HelloMetalVertexOut out;
    out.position = vertexArray[ vertexIndex ];
    out.color = float4( 1.0f, 1.0f, 1.0f, 1.0f );
    return out;
}

fragment float4 helloMetalFragmentShader( HelloMetalVertexOut interpolated [[stage_in]] ) {
    return interpolated.color;
}
