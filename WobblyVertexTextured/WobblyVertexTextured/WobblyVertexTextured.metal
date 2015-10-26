//
//  WobblyVertexTextured.metal
//  WobblyVertexTextured
//
//  Copyright © 2015 Edge Capture Software LLC. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct WobblyVertexTexturedFragmentOut {
    float4 position [[ position ]];
    float2 textureCoordinates;
};

struct WobbleAdjustment {
    float4 adjustment;
};

struct RenderTargetDimensions {
    int width;
    int height;
};

vertex WobblyVertexTexturedFragmentOut wobblyVertexTexturedVertexShader(
                                                                      device packed_float4 *vertexArray [[ buffer(0) ]],
                                                                      constant WobbleAdjustment *adjustments [[ buffer(1) ]],
                                                                      device packed_float2 *textureCoordinates [[ buffer(2) ]],
                                                                      constant float &wobbleIndex [[ buffer(3) ]],
                                                                      unsigned int vertexIndex [[ vertex_id ]] ) {
    
    WobblyVertexTexturedFragmentOut out;
    out.position.x = vertexArray[ vertexIndex ][0] + adjustments[ vertexIndex ].adjustment.x * sin( ( wobbleIndex / 0.5f ) );
    out.position.y = vertexArray[ vertexIndex ][1] + adjustments[ vertexIndex ].adjustment.y * sin( ( wobbleIndex / 0.5f ) );
    out.position.z = 0.0f;
    out.position.w = 1.0f;
    
    out.textureCoordinates[ 0 ] = textureCoordinates[ vertexIndex ][0];
    out.textureCoordinates[ 1 ] = textureCoordinates[ vertexIndex ][1];
    
    return out;
}

fragment float4 wobblyVertexTexturedFragmentShader(
    WobblyVertexTexturedFragmentOut interpolated [[stage_in]],
    texture2d<float> brianTexture [[ texture(0) ]],
    sampler textureSampler [[ sampler(0) ]] )  {
    
    float4 color = brianTexture.sample( textureSampler, interpolated.textureCoordinates );
    return color;
}


