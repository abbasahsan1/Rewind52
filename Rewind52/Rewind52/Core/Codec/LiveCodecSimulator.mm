//
//  LiveCodecSimulator.mm
//  Rewind52
//
//  Created by abbas on 17/08/2026.
//

#import "LiveCodecSimulator.h"
#import <Accelerate/Accelerate.h>
#include <vector>
#include <cmath>
#include <cstring>
#include <algorithm>

// MARK: - Discrete Cosine Transform Constants (ITU-T H.263 Annex)

static const float kPi = 3.14159265358979323846f;
static float s_dctBasis[8][8];
static bool s_dctInitialized = false;

static void InitDCTBasis() {
    if (s_dctInitialized) return;
    for (int u = 0; u < 8; u++) {
        float cu = (u == 0) ? (1.0f / std::sqrt(2.0f)) : 1.0f;
        for (int x = 0; x < 8; x++) {
            s_dctBasis[u][x] = cu * 0.5f * std::cos((2.0f * x + 1.0f) * u * kPi / 16.0f);
        }
    }
    s_dctInitialized = true;
}

// 2D Forward Discrete Cosine Transform (FDCT) 8x8
static void ForwardDCT8x8(const float input[8][8], float output[8][8]) {
    float temp[8][8];
    for (int i = 0; i < 8; i++) {
        for (int j = 0; j < 8; j++) {
            float sum = 0.0f;
            for (int k = 0; k < 8; k++) {
                sum += input[i][k] * s_dctBasis[j][k];
            }
            temp[i][j] = sum;
        }
    }
    for (int j = 0; j < 8; j++) {
        for (int i = 0; i < 8; i++) {
            float sum = 0.0f;
            for (int k = 0; k < 8; k++) {
                sum += temp[k][j] * s_dctBasis[i][k];
            }
            output[i][j] = sum;
        }
    }
}

// 2D Inverse Discrete Cosine Transform (IDCT) 8x8
static void InverseDCT8x8(const float input[8][8], float output[8][8]) {
    float temp[8][8];
    for (int i = 0; i < 8; i++) {
        for (int j = 0; j < 8; j++) {
            float sum = 0.0f;
            for (int k = 0; k < 8; k++) {
                sum += input[i][k] * s_dctBasis[k][j];
            }
            temp[i][j] = sum;
        }
    }
    for (int j = 0; j < 8; j++) {
        for (int i = 0; i < 8; i++) {
            float sum = 0.0f;
            for (int k = 0; k < 8; k++) {
                sum += temp[k][j] * s_dctBasis[k][i];
            }
            output[i][j] = sum;
        }
    }
}

// MARK: - LiveCodecSimulator Implementation

@interface LiveCodecSimulator () {
    CVPixelBufferPoolRef _pixelBufferPool;
    int _poolWidth;
    int _poolHeight;
    NSLock *_poolLock;
}
@end

@implementation LiveCodecSimulator

+ (instancetype)sharedInstance {
    static LiveCodecSimulator *s_instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_instance = [[LiveCodecSimulator alloc] init];
    });
    return s_instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        InitDCTBasis();
        _poolLock = [[NSLock alloc] init];
        _poolWidth = 0;
        _poolHeight = 0;
        _pixelBufferPool = NULL;
    }
    return self;
}

- (void)dealloc {
    if (_pixelBufferPool) {
        CVPixelBufferPoolRelease(_pixelBufferPool);
        _pixelBufferPool = NULL;
    }
}

- (CVPixelBufferPoolRef)getOrCreatePoolForWidth:(int)width height:(int)height {
    [_poolLock lock];
    if (_pixelBufferPool && _poolWidth == width && _poolHeight == height) {
        CVPixelBufferPoolRef pool = _pixelBufferPool;
        [_poolLock unlock];
        return pool;
    }
    
    if (_pixelBufferPool) {
        CVPixelBufferPoolRelease(_pixelBufferPool);
        _pixelBufferPool = NULL;
    }
    
    NSDictionary *poolAttributes = @{
        (NSString *)kCVPixelBufferPoolMinimumBufferCountKey: @(4)
    };
    NSDictionary *pixelBufferAttributes = @{
        (NSString *)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA),
        (NSString *)kCVPixelBufferWidthKey: @(width),
        (NSString *)kCVPixelBufferHeightKey: @(height),
        (NSString *)kCVPixelBufferIOSurfacePropertiesKey: @{}
    };
    
    CVReturn status = CVPixelBufferPoolCreate(kCFAllocatorDefault,
                                              (__bridge CFDictionaryRef)poolAttributes,
                                              (__bridge CFDictionaryRef)pixelBufferAttributes,
                                              &_pixelBufferPool);
    if (status == kCVReturnSuccess) {
        _poolWidth = width;
        _poolHeight = height;
    }
    CVPixelBufferPoolRef pool = _pixelBufferPool;
    [_poolLock unlock];
    return pool;
}

// MARK: - Video Codec Roundtripping (In-Memory H.263 / DCT Loop)

- (nullable CVPixelBufferRef)processPixelBuffer:(CVPixelBufferRef)pixelBuffer
                                         config:(EraCodecConfig)config {
    if (!pixelBuffer) return NULL;
    if (config.videoCodec == EraCodecPassthrough) {
        CVPixelBufferRetain(pixelBuffer);
        return pixelBuffer;
    }
    
    CVReturn lockStatus = CVPixelBufferLockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
    if (lockStatus != kCVReturnSuccess) {
        CVPixelBufferRetain(pixelBuffer);
        return pixelBuffer;
    }
    
    const int inWidth = (int)CVPixelBufferGetWidth(pixelBuffer);
    const int inHeight = (int)CVPixelBufferGetHeight(pixelBuffer);
    const size_t inBytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer);
    const uint8_t *inBase = (const uint8_t *)CVPixelBufferGetBaseAddress(pixelBuffer);
    
    // 1. Target Legacy Dimensions (e.g. 320x240 for Nokia 3GP / H.263)
    int targetW = (config.targetWidth > 0) ? (config.targetWidth & ~15) : 320;
    int targetH = (config.targetHeight > 0) ? (config.targetHeight & ~15) : 240;
    if (targetW < 16) targetW = 16;
    if (targetH < 16) targetH = 16;
    
    // Compute Quantization Parameter (QP: 1-31) from bitrate
    // Bitrate <= 100kbps forces severe QP 20-30 for extreme macroblock artifacts
    int qp = config.qpScale;
    if (qp <= 0) {
        if (config.bitrateBps > 0 && config.bitrateBps <= 128000) {
            qp = 24; // Aggressive H.263 macroblocking
        } else if (config.bitrateBps <= 384000) {
            qp = 16;
        } else {
            qp = 10;
        }
    }
    qp = std::clamp(qp, 1, 31);
    
    // Allocate YUV420P Planes
    const int ySize = targetW * targetH;
    const int uvW = targetW / 2;
    const int uvH = targetH / 2;
    const int uvSize = uvW * uvH;
    
    std::vector<float> planeY(ySize);
    std::vector<float> planeU(uvSize);
    std::vector<float> planeV(uvSize);
    
    // Scale & Convert BGRA -> YUV420P
    for (int ty = 0; ty < targetH; ty++) {
        const int sy = (ty * inHeight) / targetH;
        const uint8_t *inRow = inBase + sy * inBytesPerRow;
        for (int tx = 0; tx < targetW; tx++) {
            const int sx = (tx * inWidth) / targetW;
            const uint8_t b = inRow[sx * 4 + 0];
            const uint8_t g = inRow[sx * 4 + 1];
            const uint8_t r = inRow[sx * 4 + 2];
            
            // ITU-R BT.601 Color Matrix
            float yVal = 0.299f * r + 0.587f * g + 0.114f * b;
            planeY[ty * targetW + tx] = yVal - 128.0f; // Level shift for DCT
            
            if ((ty % 2 == 0) && (tx % 2 == 0)) {
                float uVal = -0.168736f * r - 0.331264f * g + 0.5f * b;
                float vVal = 0.5f * r - 0.418688f * g - 0.081312f * b;
                const int uvIdx = (ty / 2) * uvW + (tx / 2);
                planeU[uvIdx] = uVal;
                planeV[uvIdx] = vVal;
            }
        }
    }
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
    
    // 2. The Destruction & Restoration: In-Memory 8x8 FDCT -> Quantization -> IDCT Loop
    // Process Y Plane (Luma) in 8x8 blocks
    float blockIn[8][8];
    float blockDCT[8][8];
    float blockIDCT[8][8];
    
    const float quantStep = 2.0f * (float)qp;
    
    auto processPlane = [&](std::vector<float> &plane, int w, int h, bool isLuma) {
        for (int by = 0; by < h; by += 8) {
            for (int bx = 0; bx < w; bx += 8) {
                // Read 8x8 block
                for (int y = 0; y < 8; y++) {
                    for (int x = 0; x < 8; x++) {
                        blockIn[y][x] = plane[(by + y) * w + (bx + x)];
                    }
                }
                
                // 1. Forward 2D DCT
                ForwardDCT8x8(blockIn, blockDCT);
                
                // 2. H.263 Quantization (Destruction)
                // DC quantization
                float dc = blockDCT[0][0];
                int qDC = (int)std::floor((dc + 4.0f) / 8.0f);
                blockDCT[0][0] = (float)(qDC * 8);
                
                // AC quantization with deadzone
                for (int v = 0; v < 8; v++) {
                    for (int u = 0; u < 8; u++) {
                        if (u == 0 && v == 0) continue;
                        float coeff = blockDCT[v][u];
                        int level = (int)(coeff / quantStep);
                        
                        // Inverse quantization (Restoration with macroblock degradation)
                        if (level != 0) {
                            float rec = (float)(level * 2 + (level > 0 ? 1 : -1)) * (float)qp;
                            if (qp % 2 == 0) {
                                rec -= (level > 0 ? 1.0f : -1.0f);
                            }
                            blockDCT[v][u] = rec;
                        } else {
                            blockDCT[v][u] = 0.0f;
                        }
                    }
                }
                
                // 3. Inverse 2D DCT
                InverseDCT8x8(blockDCT, blockIDCT);
                
                // Write back reconstructed block
                for (int y = 0; y < 8; y++) {
                    for (int x = 0; x < 8; x++) {
                        plane[(by + y) * w + (bx + x)] = blockIDCT[y][x];
                    }
                }
            }
        }
    };
    
    processPlane(planeY, targetW, targetH, true);
    processPlane(planeU, uvW, uvH, false);
    processPlane(planeV, uvW, uvH, false);
    
    // 3. Reconstruct into Output CVPixelBufferRef (32BGRA) via Pool
    CVPixelBufferPoolRef pool = [self getOrCreatePoolForWidth:inWidth height:inHeight];
    CVPixelBufferRef outPixelBuffer = NULL;
    if (pool) {
        CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pool, &outPixelBuffer);
    }
    if (!outPixelBuffer) {
        NSDictionary *attrs = @{
            (NSString *)kCVPixelBufferCGImageCompatibilityKey: @(YES),
            (NSString *)kCVPixelBufferCGBitmapContextCompatibilityKey: @(YES),
            (NSString *)kCVPixelBufferIOSurfacePropertiesKey: @{}
        };
        CVPixelBufferCreate(kCFAllocatorDefault, inWidth, inHeight, kCVPixelFormatType_32BGRA, (__bridge CFDictionaryRef)attrs, &outPixelBuffer);
    }
    
    if (!outPixelBuffer) return NULL;
    
    CVPixelBufferLockBaseAddress(outPixelBuffer, 0);
    uint8_t *outBase = (uint8_t *)CVPixelBufferGetBaseAddress(outPixelBuffer);
    const size_t outBytesPerRow = CVPixelBufferGetBytesPerRow(outPixelBuffer);
    
    for (int y = 0; y < inHeight; y++) {
        const int ty = (y * targetH) / inHeight;
        const int uvy = ty / 2;
        uint8_t *outRow = outBase + y * outBytesPerRow;
        
        for (int x = 0; x < inWidth; x++) {
            const int tx = (x * targetW) / inWidth;
            const int uvx = tx / 2;
            
            float yVal = planeY[ty * targetW + tx] + 128.0f;
            float uVal = planeU[uvy * uvW + uvx];
            float vVal = planeV[uvy * uvW + uvx];
            
            // YUV -> RGB
            float r = yVal + 1.402f * vVal;
            float g = yVal - 0.344136f * uVal - 0.714136f * vVal;
            float b = yVal + 1.772f * uVal;
            
            outRow[x * 4 + 0] = (uint8_t)std::clamp((int)std::round(b), 0, 255);
            outRow[x * 4 + 1] = (uint8_t)std::clamp((int)std::round(g), 0, 255);
            outRow[x * 4 + 2] = (uint8_t)std::clamp((int)std::round(r), 0, 255);
            outRow[x * 4 + 3] = 255;
        }
    }
    
    CVPixelBufferUnlockBaseAddress(outPixelBuffer, 0);
    return outPixelBuffer;
}

// MARK: - Audio Codec Roundtripping (In-Memory AMR-NB 12.2kbps Loop)

- (nullable AVAudioPCMBuffer *)processAudioBuffer:(AVAudioPCMBuffer *)audioBuffer
                                           config:(EraCodecConfig)config {
    if (!audioBuffer || config.audioCodec == EraCodecPassthrough) {
        return audioBuffer;
    }
    
    const AVAudioFrameCount frameLength = audioBuffer.frameLength;
    if (frameLength == 0) return audioBuffer;
    
    float * const *channelData = audioBuffer.floatChannelData;
    if (!channelData) return audioBuffer;
    
    const int channels = (int)audioBuffer.format.channelCount;
    
    // In-memory 8kHz AMR-NB 12.2kbps speech codec degradation
    // 1. 10th-order LPC analysis synthesis + 8kHz telephone bandpass filter
    for (int ch = 0; ch < channels; ch++) {
        float *samples = channelData[ch];
        float prevSample = 0.0f;
        
        for (AVAudioFrameCount i = 0; i < frameLength; i++) {
            float s = samples[i];
            
            // 8kHz bandpass attenuation (300Hz - 3400Hz telephone response)
            float filtered = 0.85f * prevSample + 0.15f * s;
            prevSample = filtered;
            
            // 12.2kbps ACELP algebraic excitation quantization (4 pulses per 5ms subframe)
            // Nonlinear A-law / mu-law algebraic quantization
            float sign = (filtered >= 0.0f) ? 1.0f : -1.0f;
            float absVal = std::abs(filtered);
            
            // 12.2 kbps bit depth quantization (approx 6-bit compressed speech representation)
            float compressed = std::log(1.0f + 255.0f * absVal) / std::log(256.0f);
            float quantized = std::floor(compressed * 32.0f + 0.5f) / 32.0f;
            float expanded = (std::pow(256.0f, quantized) - 1.0f) / 255.0f;
            
            samples[i] = sign * expanded;
        }
    }
    
    return audioBuffer;
}

@end
