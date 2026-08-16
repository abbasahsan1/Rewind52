//
//  ShaderSource.swift
//  Rewind52
//
//  Created by abbas on 17/08/2026.
//

import Foundation

public struct ShaderSource {
    public static let source: String = """
#include <metal_stdlib>
using namespace metal;

// MARK: - Vertex Input & Output Structures

struct VertexInput {
    float2 position  [[attribute(0)]];
    float2 texCoords [[attribute(1)]];
};

struct VertexOutput {
    float4 position [[position]];
    float2 texCoords;
};

// MARK: - Aspect Ratio Scaling Uniforms

struct AspectRatioUniforms {
    float scaleX; // Horizontal scaling
    float scaleY; // Vertical scaling
};

// MARK: - Full Era Uniforms Structure

struct EraUniforms {
    float time;                          // Elapsed time in seconds
    float chromaticAberrationIntensity;  // RGB channel shift
    float scanLineIntensity;             // Scan line darkness
    float trackingWobbleSpeed;           // Horizontal line jitter
    float vignetteStrength;              // Edge darkening
    float noiseFloorStrength;            // Procedural noise floor
    int   posterizeColors;               // Number of colors to quantize (0 = disabled)
    int   macroblockGridSize;            // Block size for DCT/H.263 simulation (0 = disabled)
    int   isInterlaced;                  // 1 = interlaced field rendering, 0 = progressive
    float colorTemperatureShift;         // Kelvin color warmth shift (-1.0 to 1.0)
    float aspectRatioScaleX;             // Aspect ratio correction scale X
    float aspectRatioScaleY;             // Aspect ratio correction scale Y
};

// MARK: - Math & Color Space Conversions

static float hash21(float2 p) {
    p = fract(p * float2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

static float3 rgb2yuv(float3 rgb) {
    float y =  0.299 * rgb.r + 0.587 * rgb.g + 0.114 * rgb.b;
    float u = -0.14713 * rgb.r - 0.28886 * rgb.g + 0.436 * rgb.b;
    float v =  0.615 * rgb.r - 0.51499 * rgb.g - 0.10001 * rgb.b;
    return float3(y, u, v);
}

static float3 yuv2rgb(float3 yuv) {
    float r = yuv.x + 1.13983 * yuv.z;
    float g = yuv.x - 0.39465 * yuv.y - 0.58060 * yuv.z;
    float b = yuv.x + 2.03211 * yuv.y;
    return float3(r, g, b);
}

// MARK: - Default Vertex Shader with Dynamic Aspect Ratio Scaling

vertex VertexOutput default_vertex(VertexInput in [[stage_in]],
                                  constant EraUniforms &uniforms [[buffer(1)]]) {
    VertexOutput out;
    out.position = float4(in.position.x * uniforms.aspectRatioScaleX,
                          in.position.y * uniforms.aspectRatioScaleY,
                          0.0, 1.0);
    out.texCoords = in.texCoords;
    return out;
}

vertex VertexOutput passthrough_vertex(VertexInput in [[stage_in]],
                                       constant AspectRatioUniforms &uniforms [[buffer(1)]]) {
    VertexOutput out;
    out.position = float4(in.position.x * uniforms.scaleX,
                          in.position.y * uniforms.scaleY,
                          0.0, 1.0);
    out.texCoords = in.texCoords;
    return out;
}

fragment float4 passthrough_fragment(VertexOutput in [[stage_in]],
                                     texture2d<float> cameraTexture [[texture(0)]],
                                     sampler textureSampler [[sampler(0)]]) {
    return cameraTexture.sample(textureSampler, in.texCoords);
}

// MARK: - Early Digital (1995–2004) Metal Fragment Shader

fragment float4 early_digital_fragment(VertexOutput in [[stage_in]],
                                       texture2d<float> cameraTexture [[texture(0)]],
                                       sampler textureSampler [[sampler(0)]],
                                       constant EraUniforms &uniforms [[buffer(0)]]) {
    float2 uv = in.texCoords;
    float3 color = cameraTexture.sample(textureSampler, uv).rgb;
    
    if (uniforms.posterizeColors > 0) {
        float levels = float(uniforms.posterizeColors);
        color = floor(color * levels + 0.5) / levels;
    }
    
    float luma = rgb2yuv(color).x;
    if (luma < 0.3) {
        float sensorNoise = (hash21(uv * 300.0 + uniforms.time * 25.0) - 0.5) * uniforms.noiseFloorStrength;
        color += sensorNoise * (1.0 - luma / 0.3);
    }
    
    float2 c = in.texCoords - 0.5;
    color *= clamp(1.0 - dot(c, c) * uniforms.vignetteStrength, 0.0, 1.0);
    return float4(clamp(color, 0.0, 1.0), 1.0);
}

// MARK: - Analog CRT Broadcast Shader (1975–1984)

fragment float4 analog_crt_fragment(VertexOutput in [[stage_in]],
                                    texture2d<float> cameraTexture [[texture(0)]],
                                    sampler textureSampler [[sampler(0)]],
                                    constant EraUniforms &uniforms [[buffer(0)]]) {
    float2 uv = in.texCoords;
    float2 centeredUV = uv - 0.5;
    float dist = dot(centeredUV, centeredUV);
    uv = uv + centeredUV * (dist * 0.15);
    
    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
        return float4(0.02, 0.02, 0.02, 1.0);
    }
    
    if (uniforms.trackingWobbleSpeed > 0.0) {
        float wobble = sin(uv.y * 40.0 + uniforms.time * uniforms.trackingWobbleSpeed * 6.0) * 0.003;
        float glitch = step(0.98, sin(uniforms.time * 3.0 + uv.y * 10.0)) * 0.015;
        uv.x += wobble + glitch;
    }
    
    float caOffset = (uniforms.chromaticAberrationIntensity * 0.004);
    float r = cameraTexture.sample(textureSampler, float2(uv.x - caOffset, uv.y)).r;
    float g = cameraTexture.sample(textureSampler, uv).g;
    float b = cameraTexture.sample(textureSampler, float2(uv.x + caOffset, uv.y)).b;
    float3 color = float3(r, g, b);
    
    float2 screenPos = in.position.xy;
    int pixelX = int(screenPos.x) % 3;
    float3 mask = float3(0.85, 0.85, 0.85);
    if (pixelX == 0) mask = float3(1.15, 0.85, 0.85);
    else if (pixelX == 1) mask = float3(0.85, 1.15, 0.85);
    else mask = float3(0.85, 0.85, 1.15);
    color *= mask;
    
    float scanline = sin(uv.y * 525.0 * 3.14159265);
    scanline = 0.5 + 0.5 * scanline;
    color *= mix(1.0, scanline, uniforms.scanLineIntensity * 0.5);
    
    float n = hash21(uv * 500.0 + uniforms.time * 50.0);
    color += (n - 0.5) * (uniforms.noiseFloorStrength * 0.25);
    
    color.r += 0.04;
    color.b -= 0.03;
    float vignette = 1.0 - dot(centeredUV, centeredUV) * (uniforms.vignetteStrength * 1.5);
    color *= clamp(vignette, 0.0, 1.0);
    
    return float4(clamp(color, 0.0, 1.0), 1.0);
}

// MARK: - Camcorder VHS Golden Age Shader (1985–1994)

fragment float4 camcorder_vhs_fragment(VertexOutput in [[stage_in]],
                                       texture2d<float> cameraTexture [[texture(0)]],
                                       sampler textureSampler [[sampler(0)]],
                                       constant EraUniforms &uniforms [[buffer(0)]]) {
    float2 uv = in.texCoords;
    
    // 1. Tape Wobble & Tearing
    float globalTapeWobble = sin(uv.y * 14.0 + uniforms.time * 4.5) * 0.0022;
    float bottomTear = 0.0;
    if (uv.y > 0.94) {
        float tearFactor = (uv.y - 0.94) / 0.06;
        float tearNoise = hash21(float2(floor(uv.y * 120.0), floor(uniforms.time * 24.0)));
        bottomTear = (tearNoise - 0.5) * 0.08 * tearFactor;
    }
    uv.x += globalTapeWobble + bottomTear;
    
    // 2. True Interlacing
    if (uniforms.isInterlaced == 1) {
        if (int(in.position.y) % 2 == 0) {
            float fieldOffset = sin(uniforms.time * 10.0 + uv.y * 5.0) * 0.002;
            uv.x += fieldOffset;
        }
    }
    
    // 3. Multi-Tap Y/C Delay Line
    float3 yuvCenter = rgb2yuv(cameraTexture.sample(textureSampler, uv).rgb);
    float uBleed = 0.0;
    float vBleed = 0.0;
    float weightSum = 0.0;
    float spread = 0.006; 
    
    for(int i = -3; i <= 3; i++) {
        float weight = exp(-float(i*i)/4.0);
        float3 sampleYUV = rgb2yuv(cameraTexture.sample(textureSampler, float2(uv.x + float(i)*spread, uv.y)).rgb);
        uBleed += sampleYUV.y * weight;
        vBleed += sampleYUV.z * weight;
        weightSum += weight;
    }
    float3 color = yuv2rgb(float3(yuvCenter.x, uBleed / weightSum, vBleed / weightSum));
    
    // 4. Fixed CRT Raster Lines
    float rasterLine = sin(uv.y * cameraTexture.get_height() * 3.14159);
    float rasterDarken = 0.80 + 0.20 * rasterLine;
    color *= mix(1.0, rasterDarken, uniforms.scanLineIntensity);
    
    // Noise & Vignette
    float grain = (hash21(uv * 650.0 + uniforms.time * 25.0) - 0.5) * (uniforms.noiseFloorStrength * 0.3);
    color += grain;
    
    float2 c = in.texCoords - 0.5;
    color *= clamp(1.0 - dot(c, c) * (uniforms.vignetteStrength * 1.25), 0.0, 1.0);
    
    return float4(clamp(color, 0.0, 1.0), 1.0);
}

// MARK: - Mobile & Nokia 3GP Shader (2005–2014)

fragment float4 mobile_3gp_fragment(VertexOutput in [[stage_in]],
                                    texture2d<float> cameraTexture [[texture(0)]],
                                    sampler textureSampler [[sampler(0)]],
                                    constant EraUniforms &uniforms [[buffer(0)]]) {
    float2 uv = in.texCoords;
    float3 color = cameraTexture.sample(textureSampler, uv).rgb;
    
    color.r *= 1.08;
    color.g *= 1.02;
    color.b *= 0.92;
    color = pow(color, float3(1.15));
    
    float2 c = in.texCoords - 0.5;
    color *= clamp(1.0 - dot(c, c) * uniforms.vignetteStrength, 0.0, 1.0);
    return float4(clamp(color, 0.0, 1.0), 1.0);
}

// MARK: - Modern Reference Shader (2015–2026)

fragment float4 modern_reference_fragment(VertexOutput in [[stage_in]],
                                          texture2d<float> cameraTexture [[texture(0)]],
                                          sampler textureSampler [[sampler(0)]],
                                          constant EraUniforms &uniforms [[buffer(0)]]) {
    float2 uv = in.texCoords;
    float4 color = cameraTexture.sample(textureSampler, uv);
    return color;
}

// MARK: - Overlay Compositor Shader

fragment float4 overlay_composite_fragment(VertexOutput in [[stage_in]],
                                          texture2d<float> baseTexture [[texture(0)]],
                                          texture2d<float> overlayTexture [[texture(1)]],
                                          sampler textureSampler [[sampler(0)]]) {
    float2 uv = in.texCoords;
    float4 baseColor = baseTexture.sample(textureSampler, uv);
    float4 overlayColor = overlayTexture.sample(textureSampler, uv);
    float3 finalRGB = mix(baseColor.rgb, overlayColor.rgb, overlayColor.a);
    return float4(finalRGB, 1.0);
}

// MARK: - Multi-Cam Split Screen Shader

struct MultiCamUniforms {
    int splitMode;
    float splitPosition;
    float pipScale;
};

fragment float4 multicam_split_fragment(VertexOutput in [[stage_in]],
                                        texture2d<float> cameraATexture [[texture(0)]],
                                        texture2d<float> cameraBTexture [[texture(1)]],
                                        sampler textureSampler [[sampler(0)]],
                                        constant MultiCamUniforms &multiCam [[buffer(0)]]) {
    float2 uv = in.texCoords;
    if (multiCam.splitMode == 0) {
        if (uv.x < multiCam.splitPosition) {
            float2 uvA = float2(uv.x * 2.0, uv.y);
            return cameraATexture.sample(textureSampler, uvA);
        } else {
            float2 uvB = float2((uv.x - multiCam.splitPosition) * 2.0, uv.y);
            return cameraBTexture.sample(textureSampler, uvB);
        }
    } else if (multiCam.splitMode == 1) {
        float2 pipOrigin = float2(0.68, 0.05);
        float2 pipSize = float2(0.28, 0.28 * 1.33);
        if (uv.x >= pipOrigin.x && uv.x <= pipOrigin.x + pipSize.x &&
            uv.y >= pipOrigin.y && uv.y <= pipOrigin.y + pipSize.y) {
            float2 pipUV = (uv - pipOrigin) / pipSize;
            return cameraBTexture.sample(textureSampler, pipUV);
        }
        return cameraATexture.sample(textureSampler, uv);
    }
    return cameraATexture.sample(textureSampler, uv);
}
"""
}
