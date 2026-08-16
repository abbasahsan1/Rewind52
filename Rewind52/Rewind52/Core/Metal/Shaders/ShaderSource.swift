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

// MARK: - Vertex Data & Uniform Structures

struct VertexInput {
    float2 position  [[attribute(0)]];
    float2 texCoords [[attribute(1)]];
};

struct VertexOutput {
    float4 position [[position]];
    float2 texCoords;
};

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

// MARK: - Procedural Hash & Noise Functions

static float hash21(float2 p) {
    p = fract(p * float2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

static float noise(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    
    float a = hash21(i);
    float b = hash21(i + float2(1.0, 0.0));
    float c = hash21(i + float2(0.0, 1.0));
    float d = hash21(i + float2(1.0, 1.0));
    
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// MARK: - YUV / RGB Color Space Conversions

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

// MARK: - Vertex Shader

vertex VertexOutput default_vertex(VertexInput in [[stage_in]],
                                  constant EraUniforms &uniforms [[buffer(1)]]) {
    VertexOutput out;
    out.position = float4(in.position.x * uniforms.aspectRatioScaleX,
                          in.position.y * uniforms.aspectRatioScaleY,
                          0.0, 1.0);
    out.texCoords = in.texCoords;
    return out;
}

// MARK: - 1. Analog CRT Broadcast Shader (1975–1984)

fragment float4 analog_crt_fragment(VertexOutput in [[stage_in]],
                                    texture2d<float> cameraTexture [[texture(0)]],
                                    sampler textureSampler [[sampler(0)]],
                                    constant EraUniforms &uniforms [[buffer(0)]]) {
    float2 uv = in.texCoords;
    
    // 1. Barrel Curvature Distortion (Cathode Ray Tube Bulb)
    float2 centeredUV = uv - 0.5;
    float dist = dot(centeredUV, centeredUV);
    uv = uv + centeredUV * (dist * 0.15);
    
    // Bounds check with black CRT bezel
    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
        return float4(0.02, 0.02, 0.02, 1.0);
    }
    
    // 2. Horizontal Magnetic Tape Tracking Wobble
    if (uniforms.trackingWobbleSpeed > 0.0) {
        float wobble = sin(uv.y * 40.0 + uniforms.time * uniforms.trackingWobbleSpeed * 6.0) * 0.003;
        float glitch = step(0.98, sin(uniforms.time * 3.0 + uv.y * 10.0)) * 0.015;
        uv.x += wobble + glitch;
    }
    
    // 3. Chromatic Aberration (Phosphor Convergence Offset)
    float caOffset = (uniforms.chromaticAberrationIntensity * 0.004);
    float r = cameraTexture.sample(textureSampler, float2(uv.x - caOffset, uv.y)).r;
    float g = cameraTexture.sample(textureSampler, uv).g;
    float b = cameraTexture.sample(textureSampler, float2(uv.x + caOffset, uv.y)).b;
    float3 color = float3(r, g, b);
    
    // 4. Phosphor Mask (Trinitron RGB Stripes / Shadow Mask)
    float2 screenPos = in.position.xy;
    int pixelX = int(screenPos.x) % 3;
    float3 mask = float3(0.85, 0.85, 0.85);
    if (pixelX == 0) mask = float3(1.15, 0.85, 0.85);
    else if (pixelX == 1) mask = float3(0.85, 1.15, 0.85);
    else mask = float3(0.85, 0.85, 1.15);
    color *= mask;
    
    // 5. 525-Line Scanline Rasterization
    float scanline = sin(uv.y * 525.0 * 3.14159265);
    scanline = 0.5 + 0.5 * scanline;
    color *= mix(1.0, scanline, uniforms.scanLineIntensity * 0.5);
    
    // 6. Analog Noise Floor & Hum
    float n = hash21(uv * 500.0 + uniforms.time * 50.0);
    color += (n - 0.5) * (uniforms.noiseFloorStrength * 0.25);
    
    // 7. Warm Color Temperature & Tube Vignette
    color.r += 0.04;
    color.b -= 0.03;
    float vignette = 1.0 - dot(centeredUV, centeredUV) * (uniforms.vignetteStrength * 1.5);
    color *= clamp(vignette, 0.0, 1.0);
    
    return float4(clamp(color, 0.0, 1.0), 1.0);
}

// MARK: - 2. Camcorder VHS Golden Age Shader (1985–1994)

fragment float4 camcorder_vhs_fragment(VertexOutput in [[stage_in]],
                                       texture2d<float> cameraTexture [[texture(0)]],
                                       sampler textureSampler [[sampler(0)]],
                                       constant EraUniforms &uniforms [[buffer(0)]]) {
    float2 uv = in.texCoords;
    
    // 1. Interlaced Field Alternation (30fps / 60i simulation)
    if (uniforms.isInterlaced == 1) {
        int line = int(in.position.y);
        int frameTick = int(uniforms.time * 60.0) % 2;
        if (line % 2 == frameTick) {
            uv.x += 0.001;
        }
    }
    
    // 2. Bottom Tape Head Switching Noise
    if (uv.y > 0.94) {
        float tearNoise = hash21(float2(uv.y * 100.0, uniforms.time * 15.0));
        uv.x += (tearNoise - 0.5) * 0.08 * (uv.y - 0.94) / 0.06;
    }
    
    // 3. Horizontal Chroma Bleeding & YUV Separation
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
    
    // 4. Subtle Scanlines
    float scanline = sin(uv.y * 480.0 * 3.14159265);
    scanline = 0.6 + 0.4 * scanline;
    color *= mix(1.0, scanline, uniforms.scanLineIntensity * 0.35);
    
    // 5. Film Grain / Magnetic Tape Grain
    float grain = (hash21(uv * 700.0 + uniforms.time * 20.0) - 0.5) * (uniforms.noiseFloorStrength * 0.3);
    color += grain;
    
    // 6. Saturation boost & green/cyan tint
    color.g *= 1.03;
    color.r *= 0.98;
    
    // 7. Vignette
    float2 c = uv - 0.5;
    float vignette = 1.0 - dot(c, c) * (uniforms.vignetteStrength * 1.2);
    color *= clamp(vignette, 0.0, 1.0);
    
    return float4(clamp(color, 0.0, 1.0), 1.0);
}

// MARK: - 3. Early Digital Shader (1995–2004)

fragment float4 early_digital_fragment(VertexOutput in [[stage_in]],
                                       texture2d<float> cameraTexture [[texture(0)]],
                                       sampler textureSampler [[sampler(0)]],
                                       constant EraUniforms &uniforms [[buffer(0)]]) {
    float2 uv = in.texCoords;
    
    // 1. DCT 8x8 Blockiness Simulation
    if (uniforms.macroblockGridSize > 0) {
        float2 texSize = float2(cameraTexture.get_width(), cameraTexture.get_height());
        if (texSize.x > 0 && texSize.y > 0) {
            float blockSize = float(uniforms.macroblockGridSize);
            float2 blockCount = texSize / blockSize;
            uv = floor(uv * blockCount) / blockCount;
        }
    }
    
    // 2. Sample Color with slight chromatic fringing
    float ca = uniforms.chromaticAberrationIntensity * 0.0015;
    float r = cameraTexture.sample(textureSampler, float2(uv.x - ca, uv.y)).r;
    float g = cameraTexture.sample(textureSampler, uv).g;
    float b = cameraTexture.sample(textureSampler, float2(uv.x + ca, uv.y)).b;
    float3 color = float3(r, g, b);
    
    // 3. Color Quantization
    if (uniforms.posterizeColors > 0) {
        float steps = float(uniforms.posterizeColors);
        color = floor(color * steps) / steps;
    }
    
    // 4. Shadow Noise Soup
    float luma = dot(color, float3(0.299, 0.587, 0.114));
    if (luma < 0.35) {
        float shadowNoise = (hash21(uv * 400.0 + uniforms.time * 30.0) - 0.5);
        color += shadowNoise * (uniforms.noiseFloorStrength * 0.4) * (1.0 - luma / 0.35);
    }
    
    // 5. Sharpening Halo Artifacts
    float3 sampleNorth = cameraTexture.sample(textureSampler, uv + float2(0.0, 0.002)).rgb;
    float3 sampleSouth = cameraTexture.sample(textureSampler, uv - float2(0.0, 0.002)).rgb;
    float3 sampleEast  = cameraTexture.sample(textureSampler, uv + float2(0.002, 0.0)).rgb;
    float3 sampleWest  = cameraTexture.sample(textureSampler, uv - float2(0.002, 0.0)).rgb;
    float3 laplacian = (color * 4.0) - (sampleNorth + sampleSouth + sampleEast + sampleWest);
    color += laplacian * 0.18;
    
    // 6. Vignette
    float2 c = in.texCoords - 0.5;
    float vignette = 1.0 - dot(c, c) * (uniforms.vignetteStrength * 0.8);
    color *= clamp(vignette, 0.0, 1.0);
    
    return float4(clamp(color, 0.0, 1.0), 1.0);
}

// MARK: - 4. Mobile & Nokia 3GP Shader (2005–2014)

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

// MARK: - 5. Modern Reference Shader (2015–2026)

fragment float4 modern_reference_fragment(VertexOutput in [[stage_in]],
                                          texture2d<float> cameraTexture [[texture(0)]],
                                          sampler textureSampler [[sampler(0)]],
                                          constant EraUniforms &uniforms [[buffer(0)]]) {
    float2 uv = in.texCoords;
    float4 color = cameraTexture.sample(textureSampler, uv);
    
    if (uniforms.vignetteStrength > 0.0) {
        float2 c = uv - 0.5;
        float vignette = 1.0 - dot(c, c) * (uniforms.vignetteStrength * 0.5);
        color.rgb *= clamp(vignette, 0.0, 1.0);
    }
    
    return color;
}

// MARK: - 6. Dynamic OSD / Date Stamp Compositor

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

// MARK: - 7. Multi-Cam Split Screen Compositor

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
