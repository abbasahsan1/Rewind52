**RETROCAM — TECHNICAL PHASED DEVELOPMENT PLAN**

*Sequential Technical Architecture & Implementation Roadmap (No Timelines)*

| DEVELOPMENT METHODOLOGY & ARCHITECTURAL OBJECTIVES |
| :---- |

This document outlines the purely technical, phased engineering plan for RetroCam. The sequence is structured by dependency ordering: building foundational hardware drivers, real-time Metal rendering pipelines, and Core Audio DSP engines first, followed by era shader configurations, multi-pass post-processing, advanced AR/Multi-Cam features, and monetization framework integrations.

| PHASE 1: CORE CAPTURE PIPELINE & RENDERING ENGINE |
| :---- |

**Objective:** Establish the low-level media engine, hardware device configuration, and real-time GPU rendering framework.

**1.1 AVCaptureSession & Device Subsystem**

• Configure custom AVCaptureSession instance optimized for zero-copy frame delivery.

• Implement device discovery & switching for Front/Back cameras and lens selections.

• Program hardware controls: manual focus, locked exposure, fixed white balance, and torch mode integration.

• Implement native pixel buffer capture delivering CVPixelBuffer formats (YUV/NV12 and BGRA).

**1.2 Metal Real-Time Shader Pipeline Engine**

• Construct MTKView rendering pipeline backed by MTLCommandQueue and MTLRenderPipelineState.

• Develop CVMetalTextureCache bindings for zero-copy transfer of CVPixelBuffer to MTLTexture.

• Implement generic Metal shader host framework capable of reading JSON configuration primitives dynamically.

• Build standard vertex shader transformations supporting dynamic aspect ratio scaling (4:3, 16:9, 9:16 pillarboxing/cropping).

**1.3 Core Audio Engine Foundation**

• Initialize AVAudioEngine instance managing real-time audio input node processing.

• Construct Core Audio graph connecting AVAudioUnitEQ, AVAudioUnitDistortion, and AVAudioMixerNode.

• Configure AVAudioSession for low-latency voice and background ambient capturing.

| PHASE 2: SHADER LIBRARY & ERA SYSTEM CONFIGURATION |
| :---- |

**Objective:** Build the JSON configuration engine and develop the complete Metal fragment shader library for all 52 eras.

**2.1 JSON Era Schema & Configuration Loader**

• Define strict Codable Era Configuration schema mapping video, audio, date stamp, and export metadata.

• Build thread-safe Era Engine Manager to parse configuration JSONs and bind shaders dynamically at runtime.

**2.2 Visual Effect Metal Fragment Shaders**

• Analog Broadcast Shaders (1975–1984): Barrel distortion, phosphor mask CRT grids, magnetic tracking wobble, scan line generation, and luma/chroma noise.

• Camcorder Golden Age Shaders (1985–1994): YUV color space separation, chroma bleeding (chroma low-pass), horizontal chromatic aberration, and interlaced field offsetting.

• Early Digital Shaders (1995–2004): Discrete Cosine Transform (DCT) blockiness simulation, color depth quantization (16-bit), shadow noise generation, and rolling shutter distortion.

• Mobile & Early Smartphone Shaders (2005–2014): 16x16 macroblock grid overlay, posterization (256 colors), motion blur, and low frame-rate interpolation (10/15 fps lock).

**2.3 Audio Effect DSP Chains**

• Implement procedural tape hiss generators (-40dB white noise floor).

• Implement wow/flutter tape speed modulation using dynamic delay-line modulation (3–7Hz frequency deviation).

• Configure bandpass/low-pass filtering profiles (10kHz rolloff for VHS, 8kHz/11kHz mono downsampling for early digicams).

| PHASE 3: DATE STAMP ENGINE & REAL-TIME OVERLAYS |
| :---- |

**Objective:** Develop the dynamic text and graphics overlay renderer integrated directly into the GPU pipeline.

**3.1 Dynamic Overlay & Text Subsystem**

• Integrate custom bitmap & vector font assets (Digital-7, Nokia Pure, classic green/cyan phosphor fonts).

• Build real-time string formatter handling current live timestamps, custom text strings, timecodes, and GPS coordinates.

• Implement 1Hz square-wave oscillator for blinking REC indicators and tape counter animations.

**3.2 Shader-Based Compositing**

• Render date stamp text onto offscreen CoreGraphics texture buffer.

• Composite date stamp texture directly within the main Metal render pass before final display/encoding.

| PHASE 4: AUTHENTICITY PIPELINE & EXPORT SYSTEM |
| :---- |

**Objective:** Implement recording capture, multi-pass hardware codec re-encoding, and async background processing.

**4.1 Real-Time Capture Encoding**

• Set up AVAssetWriter and AVAssetWriterInputPixelBufferAdaptor for real-time frame writing.

• Lock target framerates (10/15/30/60 fps) natively during writer append operations.

• Tap AVAudioEngine buffer to stream filtered audio buffers directly into AVAssetWriter audio input.

**4.2 Multi-Pass Authenticity Post-Processing Pipeline**

• Construct background execution pipeline using Swift Concurrency (Task / Actor model).

• Step 1: Write initial raw captured video and audio streams.

• Step 2: Re-encode video stream through native low-bitrate H.263 encoder (or low-bitrate H.264 profile) at target resolution (e.g., 320x240 QCIF/QVGA).

• Step 3: Downsample audio stream to AMR-NB 12.2kbps or 8kHz PCM.

• Step 4: Mux compressed streams into temporary 3GP container.

• Step 5: Decode temporary 3GP container and bake macroblock/compression artifacts permanently into final H.264/AAC MP4 container.

• Integrate Live Activity framework (ActivityKit) to display background encoding progress on iOS Lock Screen / Dynamic Island.

**4.3 Export & Gallery Subsystem**

• Implement in-app video gallery with local thumbnail generation and file management.

• Integrate PhotoKit (PHPhotoLibrary) for seamless export to iOS Camera Roll.

• Construct dynamic social aspect-ratio formatter (9:16 auto-crop center, 4:3 pillarbox with black bars).

| PHASE 5: ADVANCED FEATURES (MULTI-CAM, AR, AUDIO PRO) |
| :---- |

**Objective:** Implement high-complexity multi-stream hardware pipelines and AR spatial rendering features.

**5.1 Multi-Cam Dual Capture Architecture**

• Configure dual AVCaptureMultiCamSession managing simultaneous front and back camera inputs.

• Build dual Metal texture processing pipeline binding Camera A \-\> Shader A and Camera B \-\> Shader B.

• Develop Composite Shader pass executing split-screen or picture-in-picture layout rendering.

• Implement device memory profiling to fallback to 1080p resolution on hardware with \<8GB RAM.

**5.2 ARKit 3D Date Stamp Engine**

• Initialize ARKit Session with ARWorldTrackingConfiguration and plane detection.

• Construct RealityKit / SceneKit 3D Scene Node embedding date stamp geometry in world space.

• Calculate real-time camera projection transform to lock 3D date stamp position with natural parallax motion.

• Composite AR Scene layer onto real-time video feed before AVAssetWriter encoding.

**5.3 Pro Audio Processing Engine**

• Integrate Core ML / SoundAnalysis framework for real-time voice isolation (isolating voice from background music/noise).

• Build audio import module allowing user music library tracks to be processed through era-specific audio DSP filters.

• Construct SFX trigger engine for 'Tape Start' and 'Tape Stop' mechanical audio sample overlays.

| PHASE 6: MONETIZATION, UI INTEGRATION & STABILITY |
| :---- |

**Objective:** Implement StoreKit 2 monetization gates, polish application UI/UX, and execute technical validation.

**6.1 StoreKit 2 Monetization Architecture**

• Build StoreKit 2 transaction observer handling auto-renewable subscriptions ($4.99/mo, $29.99 lifetime) and Non-Consumable IAPs ($0.99 Era Packs).

• Implement feature-gating entitlement manager controlling watermark toggles, maximum recording duration, and Pro-tier era unlocks.

• Implement App Store receipt validation and cryptographic signature verification.

**6.2 UI/UX Implementation**

• Build horizontal scrollable era timeline selector with real-time dynamic shader switching.

• Implement custom camera controls (Zoom wheel, Flash mode toggles, Flip camera, Audio toggle).

• Integrate Camera Control button API (iOS 18+ / iPhone 16/17 Pro series) for hardware shutter and year switching.

**6.3 Profiling, Optimization & Testing**

• Execute Metal System Trace profiling to ensure steady 60fps preview rendering.

• Execute Instruments Memory Leak and Thermal Profiling during prolonged recording sessions.

• Conduct unit and integration testing across supported hardware devices.

| TECHNICAL DEPENDENCY MATRIX |  |  |
| :---- | :---- | :---- |
| **Phase** | **Key Technical Pre-requisites** | **Unlocks / Dependent Modules** |
| Phase 1 | Hardware AVCaptureSession & Metal Base | Phase 2 (Shaders) & Phase 4 (Recording) |
| Phase 2 | Metal Base Framework & Era Config JSONs | Phase 3 (Overlays) & Phase 4 (Encoding) |
| Phase 3 | Core Graphics Text Engine & Metal Pass | Phase 4 (Final Muxing) & Phase 5 (AR) |
| Phase 4 | AVAssetWriter Engine & Swift Concurrency | Phase 5 (Multi-Cam/AR Export) |
| Phase 5 | AVCaptureMultiCamSession & ARKit Core | Phase 6 (UI Gating) |
| Phase 6 | StoreKit 2 Framework & UI Controls | Production Release |

