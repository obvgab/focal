//
//  FD55D6F4-1525-4CEF-AB12-73BFC2FDE1B5: 22:49 3/22/24
//  Sampler.metal by Gab
//  

#include <metal_stdlib>
using namespace metal;

struct Vertex {
    float4 position [[ position ]];
    float2 textureCoordinates;
};

vertex Vertex vertexSampling(constant Vertex* vertices [[ buffer(0) ]],
                             constant float4x4 &uniforms [[ buffer(1) ]],
                           uint vertexID [[ vertex_id ]]) {
    Vertex out = vertices[vertexID];
    out.position = uniforms * out.position;
    return out;
}

fragment float4 fragmentSampling(Vertex in [[ stage_in ]],
                                texture2d<float> cameraTexture [[ texture(0) ]],
                                texture2d<float> replacementTexture [[ texture(1) ]]) {
    constexpr sampler linearSampler(mag_filter::linear, min_filter::linear);
    float4 cameraColor = float4(cameraTexture.sample(linearSampler, in.textureCoordinates));
    
    float red = cameraColor.r * 255;
    
    float2 offsetFloor;
    offsetFloor.y = floor(floor(red) / 16);
    offsetFloor.x = floor(red) - (offsetFloor.y * 16);
    
    float2 offsetCeil;
    offsetCeil.y = floor(ceil(red) / 16);
    offsetCeil.x = ceil(red) - (offsetCeil.y * 16);
    
    float2 floorPosition;
    floorPosition.x = (offsetFloor.x * (1.0/16)) + 0.5/replacementTexture.get_width() + ((1.0/16 - 1.0/replacementTexture.get_width()) * cameraColor.b);
    floorPosition.y = (offsetFloor.y * (1.0/16)) + 0.5/replacementTexture.get_height() + ((1.0/16 - 1.0/replacementTexture.get_height()) * cameraColor.g);
    
    float2 ceilPosition;
    ceilPosition.x = (offsetCeil.x * (1.0/16)) + 0.5/replacementTexture.get_width() + ((1.0/16 - 1.0/replacementTexture.get_width()) * cameraColor.b);
    ceilPosition.y = (offsetCeil.y * (1.0/16)) + 0.5/replacementTexture.get_height() + ((1.0/16 - 1.0/replacementTexture.get_height()) * cameraColor.g);
    
    float4 floorColor = replacementTexture.sample(linearSampler, floorPosition);
    float4 ceilColor = replacementTexture.sample(linearSampler, ceilPosition);
    
    return mix(floorColor, ceilColor, float(fract(red)));
}
