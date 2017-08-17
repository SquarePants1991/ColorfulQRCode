//
//  qrcode.metal
//  ColorfulQRCode
//
//  Created by wang yang on 2017/8/15.
//  Copyright © 2017年 ocean. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct VertexIn
{
    packed_float3  position;
    packed_float2  uv;
};

struct VertexOut
{
    float4  position [[position]];
    float2  uv;
};

struct Uniforms
{
    int colorCount;
};

vertex VertexOut passThroughVertex(uint vid [[ vertex_id ]],
                                   const device VertexIn* vertexIn [[ buffer(0) ]])
{
    VertexOut outVertex;
    VertexIn inVertex = vertexIn[vid];
    outVertex.position = float4(inVertex.position, 1.0);
    outVertex.uv = inVertex.uv;
    return outVertex;
};

constexpr sampler s(coord::normalized, address::repeat, filter::linear);

fragment float4 passThroughFragment(VertexOut inFrag [[stage_in]],
                                   texture2d<float> diffuse [[ texture(0) ]],
                                    const device packed_float3* colors [[ buffer(0) ]],
                                    const device Uniforms& uniform [[ buffer(1) ]])
{
    int colorCount = uniform.colorCount;
    float colorEffectRange = 1.0 / (colorCount - 1.0);
    float3 gradientColor = float3(0.0);
    int colorZoneIndex = inFrag.uv.y / colorEffectRange;
    colorZoneIndex = colorZoneIndex >= colorCount - 1 ? colorCount - 2 : colorZoneIndex;
    float effectFactor = (inFrag.uv.y - colorZoneIndex * colorEffectRange) / colorEffectRange;
    gradientColor = colors[colorZoneIndex] * (1.0 - effectFactor) + colors[colorZoneIndex + 1] * effectFactor;
    float4 qrcodeColor = diffuse.sample(s, inFrag.uv);
    if (qrcodeColor.r > 0.5) {
        discard_fragment();
    } else {
        return float4(gradientColor, 1.0);
    }
};
