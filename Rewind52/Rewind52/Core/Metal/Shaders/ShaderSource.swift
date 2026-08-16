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

// MARK: - Phase 2: Early Digital (1995–2004) Metal Fragment Shader
// Simulates:
// 1. CMOS Line-by-Line Rolling Shutter Distortion & Sensor Readout Skew
// 2. Discrete Cosine Transform (DCT) 8x8 Macroblock Compression & 4:2:0 Chroma Subsampling
// 3. 16-Bit Color Depth Quantization (RGB565 5-bit R, 6-bit G, 5-bit B) with Dithering

fragment float4 early_digital_fragment(VertexOutput in [[stage_in]],
                                       texture2d<float> cameraTexture [[texture(0)]],
                                       sampler textureSampler [[sampler(0)]],
                                       constant EraUniforms &uniforms [[buffer(0)]]) {
    float2 uv = in.texCoords;
    float2 texSize = float2(cameraTexture.get_width(), cameraTexture.get_height());
    if (texSize.x <= 0.0 || texSize.y <= 0.0) {
        texSize = float2(720.0, 480.0);
    }
    
    // -------------------------------------------------------------
    // 1. CMOS ROLLING SHUTTER DISTORTION & SCANLINE READOUT SKEW
    // -------------------------------------------------------------
    // Early CMOS sensors read lines sequentially from top to bottom.
    // Horizontal camera panning induces progressive shear / jello skew.
    float rollingShutterSkew = sin(uniforms.time * 3.5) * 0.010 * (uv.y - 0.5);
    // Subtle sensor line jitter
    float lineJitter = (hash21(float2(floor(uv.y * texSize.y), floor(uniforms.time * 15.0))) - 0.5) * 0.0012;
    uv.x = clamp(uv.x + rollingShutterSkew + lineJitter, 0.0, 1.0);
    
    // -------------------------------------------------------------
    // 2. DISCRETE COSINE TRANSFORM (DCT) 8x8 BLOCKINESS & 4:2:0 SUBSAMPLING
    // -------------------------------------------------------------
    float blockSize = (uniforms.macroblockGridSize > 0) ? float(uniforms.macroblockGridSize) : 8.0;
    float2 blockCount = texSize / blockSize;
    
    // Macroblock anchor UV
    float2 blockUV = floor(uv * blockCount) / blockCount;
    float2 intraBlock = fract(uv * blockCount);
    
    // Sample DC component (block average representative)
    float2 blockCenterUV = blockUV + (blockSize * 0.5) / texSize;
    float3 blockDCSample = cameraTexture.sample(textureSampler, blockCenterUV).rgb;
    
    // Sample raw full-res color
    float3 rawSample = cameraTexture.sample(textureSampler, uv).rgb;
    
    // AC High-Frequency intra-block difference
    float3 intraAC = rawSample - blockDCSample;
    
    // Quantize AC coefficients (coarse DCT high frequency quantization)
    intraAC = floor(intraAC * 3.5 + 0.5) / 3.5;
    
    // Emulate 8x8 block boundary step
    float2 gridLine = step(0.92, intraBlock);
    float gridDarken = 1.0 - max(gridLine.x, gridLine.y) * 0.08;
    
    float3 dctColor = (blockDCSample + intraAC) * gridDarken;
    
    // 4:2:0 Chroma Subsampling (U/V channels downsampled to 16x16 blocks)
    float2 chromaBlockCount = texSize / (blockSize * 2.0);
    float2 chromaUV = (floor(uv * chromaBlockCount) + 0.5) / chromaBlockCount;
    float3 chromaSample = cameraTexture.sample(textureSampler, chromaUV).rgb;
    
    float3 yuvDCT = rgb2yuv(dctColor);
    float3 yuvChroma = rgb2yuv(chromaSample);
    
    // Combine full-res quantized luma (Y) with coarse subsampled chroma (U, V)
    float3 lumaChromaColor = yuv2rgb(float3(yuvDCT.x, yuvChroma.y, yuvChroma.z));
    
    // Slight chromatic fringing / digital sharpen halo
    float caOffset = uniforms.chromaticAberrationIntensity * 0.002;
    float rCA = cameraTexture.sample(textureSampler, float2(uv.x - caOffset, uv.y)).r;
    float bCA = cameraTexture.sample(textureSampler, float2(uv.x + caOffset, uv.y)).b;
    lumaChromaColor.r = mix(lumaChromaColor.r, rCA, 0.4);
    lumaChromaColor.b = mix(lumaChromaColor.b, bCA, 0.4);
    
    // -------------------------------------------------------------
    // 3. 16-BIT COLOR DEPTH QUANTIZATION (RGB565 HIGH COLOR)
    // -------------------------------------------------------------
    // Dithering pattern to break color banding into vintage dot clusters
    float dither = (hash21(uv * texSize + uniforms.time) - 0.5) * (1.0 / 64.0);
    float3 ditheredColor = clamp(lumaChromaColor + dither, 0.0, 1.0);
    
    // 5 bits for Red (32 levels: 0..31)
    float r16 = floor(ditheredColor.r * 31.0 + 0.5) / 31.0;
    // 6 bits for Green (64 levels: 0..63)
    float g16 = floor(ditheredColor.g * 63.0 + 0.5) / 63.0;
    // 5 bits for Blue (32 levels: 0..31)
    float b16 = floor(ditheredColor.b * 31.0 + 0.5) / 31.0;
    
    float3 final16Bit = float3(r16, g16, b16);
    
    // Shadow noise characteristic of late 90s digital sensors
    float luma = yuvDCT.x;
    if (luma < 0.3) {
        float sensorNoise = (hash21(uv * 300.0 + uniforms.time * 25.0) - 0.5) * (uniforms.noiseFloorStrength * 0.35);
        final16Bit += sensorNoise * (1.0 - luma / 0.3);
    }
    
    // Digital lens vignette
    float2 c = in.texCoords - 0.5;
    float vignette = 1.0 - dot(c, c) * (uniforms.vignetteStrength * 1.0);
    final16Bit *= clamp(vignette, 0.0, 1.0);
    
    return float4(clamp(final16Bit, 0.0, 1.0), 1.0);
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
    
    if (uniforms.isInterlaced == 1) {
        int line = int(in.position.y);
        int frameTick = int(uniforms.time * 60.0) % 2;
        if (line % 2 == frameTick) {
            uv.x += 0.001;
        }
    }
    
    if (uv.y > 0.94) {
        float tearNoise = hash21(float2(uv.y * 100.0, uniforms.time * 15.0));
        uv.x += (tearNoise - 0.5) * 0.08 * (uv.y - 0.94) / 0.06;
    }
    
    float ca = uniforms.chromaticAberrationIntensity * 0.003;
    float4 centerSample = cameraTexture.sample(textureSampler, uv);
    float3 yuvCenter = rgb2yuv(centerSample.rgb);
    
    float3 sampleL = cameraTexture.sample(textureSampler, float2(uv.x - ca * 2.0, uv.y)).rgb;
    float3 sampleR = cameraTexture.sample(textureSampler, float2(uv.x + ca * 2.0, uv.y)).rgb;
    float3 yuvL = rgb2yuv(sampleL);
    float3 yuvR = rgb2yuv(sampleR);
    
    float uBleed = (yuvL.y * 0.25 + yuvCenter.y * 0.5 + yuvR.y * 0.25);
    float vBleed = (yuvL.z * 0.25 + yuvCenter.z * 0.5 + yuvR.z * 0.25);
    
    float3 color = yuv2rgb(float3(yuvCenter.x, uBleed, vBleed));
    
    float r = cameraTexture.sample(textureSampler, float2(uv.x - ca, uv.y)).r;
    float b = cameraTexture.sample(textureSampler, float2(uv.x + ca, uv.y)).b;
    color.r = mix(color.r, r, 0.6);
    color.b = mix(color.b, b, 0.6);
    
    float scanline = sin(uv.y * 480.0 * 3.14159265);
    scanline = 0.6 + 0.4 * scanline;
    color *= mix(1.0, scanline, uniforms.scanLineIntensity * 0.35);
    
    float grain = (hash21(uv * 700.0 + uniforms.time * 20.0) - 0.5) * (uniforms.noiseFloorStrength * 0.3);
    color += grain;
    
    color.g *= 1.03;
    color.r *= 0.98;
    
    float2 c = uv - 0.5;
    float vignette = 1.0 - dot(c, c) * (uniforms.vignetteStrength * 1.2);
    color *= clamp(vignette, 0.0, 1.0);
    
    return float4(clamp(color, 0.0, 1.0), 1.0);
}

// MARK: - Mobile & Nokia 3GP Shader (2005–2014)

fragment float4 mobile_3gp_fragment(VertexOutput in [[stage_in]],
                                    texture2d<float> cameraTexture [[texture(0)]],
                                    sampler textureSampler [[sampler(0)]],
                                    constant EraUniforms &uniforms [[buffer(0)]]) {
    float2 uv = in.texCoords;
    float2 lowRes = float2(320.0, 240.0);
    float2 pixelUV = floor(uv * lowRes) / lowRes;
    uv = pixelUV;
    
    float4 texColor = cameraTexture.sample(textureSampler, uv);
    float3 color = texColor.rgb;
    
    if (uniforms.posterizeColors > 0) {
        color.r = floor(color.r * 7.0 + 0.5) / 7.0;
        color.g = floor(color.g * 7.0 + 0.5) / 7.0;
        color.b = floor(color.b * 3.0 + 0.5) / 3.0;
    }
    
    float2 gridPos = fract(in.texCoords * (lowRes / 16.0));
    if (gridPos.x < 0.04 || gridPos.y < 0.04) {
        color *= 0.94;
    }
    
    color.r *= 1.08;
    color.g *= 1.02;
    color.b *= 0.92;
    color = pow(color, float3(1.15));
    
    float n = (hash21(uv * 250.0 + floor(uniforms.time * 15.0)) - 0.5);
    color += n * (uniforms.noiseFloorStrength * 0.35);
    
    float2 c = in.texCoords - 0.5;
    float vignette = 1.0 - dot(c, c) * (uniforms.vignetteStrength * 1.1);
    color *= clamp(vignette, 0.0, 1.0);
    
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
