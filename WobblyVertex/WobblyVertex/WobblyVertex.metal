//
//  WobblyVertex.metal
//  WobblyVertex
//
//  Copyright © 2015 Edge Capture Software LLC. All rights reserved.
//

#include <metal_stdlib>
#include <metal_math>

using namespace metal;

struct WobblyVertexOut {
    float4 position [[ position ]];
    float4 color;
};

struct WobbleAdjustment {
    float4 adjustment;
};

vertex WobblyVertexOut wobblyVertexShader( device packed_float4 *vertexArray [[ buffer(0) ]],
                                           constant WobbleAdjustment *adjustments [[ buffer(1) ]],
                                           constant float &wobbleIndex [[ buffer(2) ]],
                                           unsigned int vertexIndex [[ vertex_id ]] ) {
    WobblyVertexOut out;
    out.position.x = vertexArray[ vertexIndex ][0] + adjustments[ vertexIndex ].adjustment.x  * sin( ( wobbleIndex / 0.5f ) );
    out.position.y = vertexArray[ vertexIndex ][1] + adjustments[ vertexIndex ].adjustment.y * sin( ( wobbleIndex / 0.5f ) );
    out.position.z = vertexArray[ vertexIndex ][2] + adjustments[ vertexIndex ].adjustment.z * sin( ( wobbleIndex / 0.5f ) );
    out.position.w = vertexArray[ vertexIndex ][3] + adjustments[ vertexIndex ].adjustment.w * sin( ( wobbleIndex / 0.5f ) );
    
    // out.position = vertexArray[ vertexIndex ] + adjustments[ vertexIndex ].adjustment;
    out.color = float4( 1.0f, 1.0f, 1.0f, 1.0f );
    return out;
}

fragment float4 wobblyFragmentShader( WobblyVertexOut interpolated [[stage_in]] ) {
    return interpolated.color;
}
