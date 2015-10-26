//
//  WobblyVertexRedFragment.metal
//  WobbyVertexRedFragment
//
//  Copyright © 2015 Edge Capture Software LLC. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct WobblyVertexRedFragmentOut {
    float4 position [[ position ]];
    float4 color;
};

struct WobbleAdjustment {
    float4 adjustment;
};

struct RenderTargetDimensions {
    int width;
    int height;
};

vertex WobblyVertexRedFragmentOut wobblyVertexRedFragmentVertexShader(
    device packed_float4 *vertexArray [[ buffer(0) ]],
    constant WobbleAdjustment *adjustments [[ buffer(1) ]],
    device packed_float4 *colors [[ buffer(2) ]],
    constant float &wobbleIndex [[ buffer(3) ]],
    unsigned int vertexIndex [[ vertex_id ]] ) {
    
    WobblyVertexRedFragmentOut out;
    out.position.x = vertexArray[ vertexIndex ][0] + adjustments[ vertexIndex ].adjustment.x  * sin( ( wobbleIndex / 0.5f ) );
    out.position.y = vertexArray[ vertexIndex ][1] + adjustments[ vertexIndex ].adjustment.y * sin( ( wobbleIndex / 0.5f ) );
    out.position.z = 0.0f;
    out.position.w = 1.0f;
    
    out.color = float4( colors[ vertexIndex ][0], colors[ vertexIndex ][1], colors[ vertexIndex ][2], colors[ vertexIndex ][3] );
    
    return out;
}

fragment float4 wobblyVertexRedFragmentFragmentShader(
    WobblyVertexRedFragmentOut interpolated [[stage_in]],
    device const packed_float4 *vertexArray [[ buffer(0) ]],
    constant RenderTargetDimensions& targetDimensions [[buffer(1)]] )  {
    
    float4 unpackedV1 = float4( vertexArray[0][0], vertexArray[0][1], vertexArray[0][2], vertexArray[0][3] );
    float4 unpackedV2 = float4( vertexArray[1][0], vertexArray[1][1], vertexArray[1][2], vertexArray[1][3] );
    
    float interpolatedx = interpolated.position.x / (float)targetDimensions.width - 1.0;
    float interpolatedy = -(interpolated.position.y / (float)targetDimensions.height) + 1.0;
    float interpolatedz = 0.0f;
    float interpolatedw = 1.0f;
    
    float4 normInterp( interpolatedx, interpolatedy, interpolatedz, interpolatedw );
    
    float4 v1Interp = normInterp - unpackedV1;
    float4 v1v2 = unpackedV2 - unpackedV1;
    
    float redComponent = ( dot( v1Interp, v1v2 ) / length( v1v2 ) );
    
    return float4( redComponent, 0.0f, 0.0f, 1.0f );
}


