//
//  LiveCodecSimulator.h
//  Rewind52
//
//  Created by abbas on 17/08/2026.
//

#import <Foundation/Foundation.h>
#import <CoreVideo/CoreVideo.h>
#import <AVFoundation/AVFoundation.h>

typedef NS_ENUM(NSInteger, EraCodec) {
    EraCodecPassthrough = 0,
    EraCodecVideoH263 = 1,
    EraCodecVideoMpeg4 = 2,
    EraCodecAudioAmrNb = 3
};

typedef struct {
    EraCodec videoCodec;
    int targetWidth;
    int targetHeight;
    int bitrateBps; // e.g. 100000 (100 kbps) for aggressive H.263 macroblocking
    int qpScale;    // Quantization Parameter (1-31)
    
    EraCodec audioCodec;
    int audioSampleRate; // e.g. 8000
    int audioBitrateBps; // e.g. 12200 (12.2 kbps)
} EraCodecConfig;

NS_ASSUME_NONNULL_BEGIN

@interface LiveCodecSimulator : NSObject

+ (instancetype)sharedInstance;

/// In-memory roundtrip video processing:
/// Converts CVPixelBufferRef -> YUV420P -> In-Memory H.263 Macroblock Encode -> In-Memory Decode -> CVPixelBufferRef
- (nullable CVPixelBufferRef)processPixelBuffer:(CVPixelBufferRef)pixelBuffer
                                         config:(EraCodecConfig)config CF_RETURNS_RETAINED;

/// In-memory roundtrip audio processing:
/// Converts AVAudioPCMBuffer -> 8kHz PCM -> In-Memory AMR-NB Encode -> Decode -> AVAudioPCMBuffer
- (nullable AVAudioPCMBuffer *)processAudioBuffer:(AVAudioPCMBuffer *)audioBuffer
                                           config:(EraCodecConfig)config;

@end

NS_ASSUME_NONNULL_END
