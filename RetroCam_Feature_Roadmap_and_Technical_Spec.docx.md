**RETROCAM — FEATURE ROADMAP & TECHNICAL SPEC**

*V1 Production Plan — Based on Brainstorm Session*

| PRODUCT DEFINITION |
| :---- |

**Name:** RetroCam  
**Tagline:** “Record like it’s 1988\. Or 2003\. Or 1975.”  
**Category:** Photo & Video  
**Price:** Freemium — 3 eras free (watermark, 60s max), Pro $4.99/mo or $29.99 lifetime  
**Platforms:** iPhone (primary), iPad (secondary), Apple Watch (V2 remote)

**The Killer Detail:** Authenticity through hardware replication. We don’t apply filters — we replicate the actual camera settings, codecs, and limitations of each era. Nokia 2008? We lock auto-exposure, encode to 3GP (H.263/AMR-NB), then wrap in MP4. The footage FEELS real because it IS real.

| V1 FEATURE SET — LOCKED |
| :---- |

**TIER 0: CORE CAPTURE (Must-Have, Free \+ Pro)**

| \# | Feature | Scope | Notes |
| :---- | :---- | :---- | :---- |
| C1 | Real-time preview | All eras | See effect before recording. Metal shader pipeline. |
| C2 | Front camera | All eras | Selfie mode with era filter. |
| C3 | Back camera | All eras | Primary capture mode. |
| C4 | Flash toggle | All eras | On/off/auto. Flash look matches era (warm for VHS, harsh for digicam). |
| C5 | Zoom | All eras | Digital zoom with era-appropriate degradation. |
| C6 | Recent recordings gallery | In-app | Thumbnails, quick re-watch, delete, share. Not just Photos library. |

**TIER 1: THE ERA SYSTEM (52 Eras: 1975–2026)**

Free Tier: 3 eras (TBD — see Era Selection below)  
Pro Tier: All 52 eras

**Each era defines:**  
\- Video pipeline: Resolution, codec, frame rate, color space, compression  
\- Visual effects: Shader effects applied in real-time  
\- Audio pipeline: Sample rate, codec, compression, EQ, noise  
\- Date stamp: Font, format, position, color, blink behavior  
\- Camera behavior: Auto-exposure lock, shutter speed, ISO simulation, focus behavior  
\- Export behavior: Native codec → container conversion (e.g., 3GP → MP4)

**ERA CATEGORIES: ANALOG BROADCAST (1975–1984)**

| Year | Name | Resolution | Key Visual | Key Audio | Date Stamp |
| :---- | :---- | :---- | :---- | :---- | :---- |
| 1975 | CRT Broadcast | 480i | Barrel curve, phosphor mask, overscan, warm yellowing | Tube warmth, 50/60Hz hum | None |
| 1977 | Betamax I | 480i | Soft, warm, slight tracking wobble | Analog warmth, hiss | None |
| 1979 | VHS I | 480i | Scan lines, chromatic aberration, tracking noise | Hiss, wow/flutter, 10kHz rolloff | “DEC 25 1979” cyan, bottom-left |
| 1981 | Betamax II | 480i | Sharper than VHS I, less noise | Hi-fi stereo option | “12/25/1981” white |
| 1983 | VHS-C | 480i | Compact camcorder look, slightly softer, battery indicator | Same as VHS I | “DEC 25 1983 3:42 PM” cyan |
| 1984 | Video8 | 480i | Sony 8mm, warmer, film-like grain | PCM audio (hi-fi), clean | White, small |

**ERA CATEGORIES: CAMCORDER GOLDEN AGE (1985–1994)**

| Year | Name | Resolution | Key Visual | Key Audio | Date Stamp |
| :---- | :---- | :---- | :---- | :---- | :---- |
| 1985 | VHS HQ | 480i | Slightly sharper VHS, reduced noise | Same as VHS | Same as VHS |
| 1986 | Hi8 | 480i | Sharper than Video8, better color | Hi-fi stereo, clean | White, smaller |
| 1987 | S-VHS | 480i | S-Video quality, sharper, less color bleed | Hi-fi, wider freq response | Cyan, with time |
| 1988 | VHS Camcorder | 480i | Signature look. Scan lines, chromatic aberration, date stamp, tracking noise, interlacing, vignette | Hiss, wow/flutter, 10kHz rolloff, compression | “DEC 25 1988 3:42 PM” cyan, blinking REC dot |
| 1989 | Video8 Handycam | 480i | Compact, slightly shaky (stabilizer off), warm | PCM, slight hiss | White |
| 1990 | Hi8 Handycam | 480i | Sharp, good color, handheld shake | Hi-fi stereo, clean | White, smaller |
| 1991 | VHS-C Compact | 480i | Smaller form factor, slightly softer | Same as VHS | Same as VHS |
| 1992 | S-VHS-C | 480i | S-VHS in compact form, sharp | Hi-fi | Cyan |
| 1993 | 8mm Camcorder | 480i | Warm, filmic, slight grain | PCM, warm | White |
| 1994 | Hi8 XR | 480i | Extended resolution, sharper than standard Hi8 | Hi-fi, wider range | White |

**ERA CATEGORIES: EARLY DIGITAL (1995–2004)**

| Year | Name | Resolution | Key Visual | Key Audio | Date Stamp |
| :---- | :---- | :---- | :---- | :---- | :---- |
| 1995 | MiniDV | 720×480 | Digital sharpness, mild blockiness in motion, timecode | PCM 16-bit 48kHz, clean | “00:12:34:15” timecode |
| 1996 | Digital8 | 720×480 | Sony Digital8, sharp, slight color banding | PCM, clean | White |
| 1997 | DV Camcorder | 720×480 | Professional DV, sharp, slight compression artifacts | PCM, 16-bit | Timecode |
| 1998 | Webcam (early) | 320×240 | 15fps, heavy pixelation, low light \= noise soup | 8kHz mono, robotic | None |
| 1999 | Webcam (USB) | 352×288 | Slightly better, still blocky, compression artifacts | 11kHz, light compression | None |
| 2000 | MiniDV Consumer | 720×480 | Consumer-grade DV, mild blockiness | PCM, 12-bit option | Timecode |
| 2001 | Digital8 Handycam | 720×480 | Consumer Digital8, good color | PCM, 12-bit | White |
| 2002 | MicroMV | 720×480 | Sony MicroMV, MPEG-2 compression, mild blockiness | MPEG-1 Layer II audio | Timecode |
| 2003 | Early Digicam Video | 640×480 | VGA, pink tint, heavy shadow noise, rolling shutter | 11kHz, light compression | “03/25/2003 2:15 PM” |
| 2004 | Digicam Video (better) | 640×480 | VGA, oversharpened, weird color processing | 22kHz stereo, thin | “Mar 25, 2004” |

**ERA CATEGORIES: MOBILE & EARLY SMARTPHONE (2005–2014)**

| Year | Name | Resolution | Key Visual | Key Audio | Date Stamp |
| :---- | :---- | :---- | :---- | :---- | :---- |
| 2005 | Feature Phone Video | 176×144 | QCIF, blocky, 10fps, color banding | AMR-NB 7.95kbps, muffled | None |
| 2006 | Feature Phone (better) | 320×240 | QVGA, 15fps, still blocky | AMR-NB 12.2kbps | None |
| 2007 | Early Smartphone | 320×240 | QVGA, 15fps, slightly better color | AAC 32kbps, thin | None |
| 2008 | Nokia 3GP | 320×240 | QVGA, blocky, posterized to 256 colors, macroblock grid visible, 15fps, auto-exposure locked | AMR-NB 12.2kbps, muffled, dropouts | Signal bars \+ battery \+ “Options” menu |
| 2009 | iPhone 3GS | 640×480 | VGA, decent color, slight overprocessing | AAC 64kbps, acceptable | None |
| 2010 | iPhone 4 | 720p | 720p, good color, rolling shutter on fast motion | AAC 128kbps, clean | None |
| 2011 | Android 720p | 720p | Slightly oversharpened, variable quality by OEM | AAC, quality varies | None |
| 2012 | Early Smartphone HDR | 720p | Oversharpened, weird HDR, oversaturated | Clean but thin | “Mar 25, 2012” |
| 2013 | iPhone 5s | 1080p | 1080p, good stabilization, slight overprocessing | AAC 256kbps, clean | None |
| 2014 | Android 1080p | 1080p | Good quality, OEM color science differences | AAC, clean | None |

**ERA CATEGORIES: MODERN SMARTPHONE (2015–2026)**

| Year | Name | Resolution | Key Visual | Key Audio | Date Stamp |
| :---- | :---- | :---- | :---- | :---- | :---- |
| 2015 | iPhone 6s 4K | 4K | 4K, good stabilization, slight overprocessing | AAC 256kbps, clean | None |
| 2016 | Smartphone 4K | 4K | Variable quality, some oversharpening | AAC, clean | None |
| 2017 | iPhone X | 4K HDR | 4K, HDR, cinematic color | Stereo, clean | None |
| 2018 | Smartphone 4K60 | 4K60 | Smooth, slight motion blur, good stabilization | Stereo, clean | None |
| 2019 | iPhone 11 Night | 4K | Night mode video, brightened shadows, reduced noise | Stereo, clean | None |
| 2020 | iPhone 12 Dolby Vision | 4K HDR | Dolby Vision, wide color, cinematic | Stereo, spatial audio | None |
| 2021 | iPhone 13 Cinematic | 1080p/4K | Cinematic mode, shallow DOF, rack focus | Spatial audio, clean | None |
| 2022 | iPhone 14 Action | 4K | Action mode, gimbal-like stabilization | Spatial audio, clean | None |
| 2023 | iPhone 15 Pro Log | 4K ProRes | ProRes Log, flat color, high dynamic range | Spatial audio, 48kHz | None |
| 2024 | iPhone 16 Pro 4K120 | 4K120 | 4K120fps, extreme slow-mo, sharp | Spatial audio, 48kHz | None |
| 2025 | iPhone 17 Pro | 4K | Standard iPhone 17 Pro look (reference baseline) | Spatial audio, 48kHz | None |
| 2026 | iPhone 17 Pro Max | 4K | Reference / modern baseline | Spatial audio, 48kHz | None |

**Note:** 2015–2026 are “modern” references. The value prop is recording in 2026 but making it look like 1988\. These modern baselines are included for completeness and for users who want to compare.

**TIER 2: DATE STAMP SYSTEM (All Eras)**

| Feature | Status | Detail |
| :---- | :---- | :---- |
| Auto date | Must-have | Uses actual current date in era-appropriate format |
| Fake date | Must-have | User types any date. “JUL 04 1999” or “my birthday” |
| Real-time clock | Must-have | Date stamp ticks live while recording |
| Font authenticity | Must-have | Each era has exact or closest free equivalent font |
| Position presets | Must-have | Bottom-left (VHS), top-right (Nokia), none (webcam), center, etc. |
| Blinking REC dot | Must-have by era | Red dot blinks 1Hz. Only on eras that had it (VHS, camcorders) |
| Custom text | Pro | User types anything: “JAKE’S BIRTHDAY” instead of date |
| GPS spoof | Pro | Fake GPS coordinates in era-appropriate format |

**TIER 3: AUDIO ENGINE (All Eras)**

| Feature | Status | Detail |
| :---- | :---- | :---- |
| Era-matched audio | Must-have | Each year has its own audio filter preset |
| Audio toggle | Standard | Turn audio effects off, keep video filter |
| Original audio preserve | Pro | Export with clean audio \+ filtered video as separate option |
| Voice isolation | Pro | Strip music/background, keep voice, then apply era audio |
| Dubbed tape sound | Pro | “Tape start” and “tape stop” SFX at record begin/end |
| Audio import | Pro | Add music from library, filter it to match era |

**TIER 4: EXPORT SYSTEM**

| Feature | Status | Detail |
| :---- | :---- | :---- |
| Resolution | Match era | Each era exports at its authentic resolution (upscaled if needed) |
| Aspect ratio | Match era | 4:3 for analog/digital tape, 16:9 for modern, 9:16 for social |
| Frame rate | Match era | 15fps for Nokia/webcam, 30fps for VHS, 60fps for modern |
| TikTok/Instagram direct | Must-have | Export 9:16 with auto-crop center, black bars if 4:3 source |
| Batch export | Pro | Apply same filter to multiple videos |
| Trim in-app | Pro | Basic trim before export |
| Found footage mode | Pro | Random glitches, dropouts, static bursts during recording |

**TIER 5: ADVANCED FEATURES**

| Feature | Status | Detail |
| :---- | :---- | :---- |
| Multi-cam split | Must-have | Record front \+ back simultaneously, split screen, each with different era |
| AR date stamp | Must-have | Date stamp floats in 3D space, moves with camera parallax |
| Import existing videos | Pro | Apply retro filter to videos already in Photos |
| Burst/interval recording | Pro | Auto-capture every N seconds for stop-motion |
| Randomize button | Pro | Random year \+ random settings. “Surprise me.” |

**TIER 6: V2 (Post-Launch)**

| Feature | Status | Detail |
| :---- | :---- | :---- |
| Watch remote | V2 | Use Watch as remote shutter \+ viewfinder |
| Siri shortcut | V2 | “Hey Siri, record a VHS clip” → opens app, starts recording in 1988 mode |
| Photo mode | V2 | Still images with same retro filters (separate tab or separate app) |
| Social sharing | V2 | Direct share to TikTok/Instagram/Reels with era hashtag |
| Collaborative clip | V2 | Friend records from their phone, merge both feeds with same era |

| AUTHENTICITY PIPELINE — THE KILLER DETAIL |
| :---- |

This is what separates RetroCam from every “vintage filter” app.

**The Nokia 2008 Example**

**Most apps:** Apply a “pixelated” filter, add a Nokia UI overlay, export as MP4.

**RetroCam:**

1\. Lock auto-exposure — Nokia phones had terrible auto-exposure. We replicate this by locking exposure to the first frame and never adjusting.

2\. Lock white balance — Nokia sensors had a fixed warm cast. We apply this in the shader.

3\. Record at 15fps — Not 30fps with frame dropping. Actual 15fps capture.

4\. Render at 320×240 — Native QVGA resolution.

5\. Quantize to 256 colors — Posterization to match 16-bit color depth.

6\. Add macroblock grid — 16×16 H.263 macroblock artifacts visible in motion.

7\. Encode audio to AMR-NB 12.2kbps — Actual AMR-NB encoding, not just EQ.

8\. Wrap in 3GP container — Actual 3GP file structure.

9\. Then convert to MP4 — For compatibility, but the 3GP artifacts are baked in.

**The result:** It doesn’t LOOK like a Nokia video. It IS a Nokia video.

**The VHS 1988 Example**

**Interlaced capture —** Render odd/even fields separately, offset by 1 line.

**Chromatic aberration —** Shift R channel 2px left, B channel 2px right.

**Scan lines —** Horizontal lines at 60% opacity, 525-line spacing.

**Tracking noise —** Random horizontal displacement of scan lines, varying intensity based on “tape quality” slider.

**Color bleeding —** Gaussian blur on chroma channels (YUV space), luma stays sharp.

**Saturation boost —** \+30% saturation, slight green tint.

**Vignette —** Darken corners 20%.

**Resolution —** Effective 480i (720×480) with nearest-neighbor upscaling.

**Audio —** White noise at \-40dB, wow/flutter ±0.5% at 3-7Hz, low-pass at 10kHz.

**Date stamp —** Digital-7 font, cyan, bottom-left, blinking REC dot.

| MONETIZATION GATES |
| :---- |

**Free Tier**

• 3 eras (TBD from list above — recommend: 1988 VHS, 2008 Nokia, 2012 Early Smartphone)

• Watermark: Small “RetroCam” bottom-right

• Max recording length: 60 seconds

• Resolution: Authentic to era (no upscaling limitation)

• Audio effects: Era-matched preset only (no toggle, no import)

• Date stamp: Auto date only, no custom text

• Export: MP4 only, no trim, no batch

• Multi-cam: No

• AR date stamp: No

• Import existing: No

**Pro Tier — $4.99/month or $29.99 lifetime**

• All 52 eras (1975–2026)

• No watermark

• Unlimited recording length

• Audio toggle (effects on/off)

• Original audio preserve option

• Voice isolation

• Dubbed tape sound effects

• Audio import from library

• Custom date text

• GPS spoof coordinates

• Batch export

• Trim in-app

• Found footage mode (random glitches)

• Multi-cam split (front \+ back, different eras)

• AR date stamp (3D floating, parallax)

• Import existing videos from Photos

• Burst/interval recording

• Randomize button

**Individual Era Packs — $0.99 each (optional)**

For users who want one specific era but not the full subscription. Example: “I only want the 1988 VHS look.” $0.99 unlocks that era forever.

| UI/UX FLOW |
| :---- |

**Main Screen**

| ┌─────────────────────────────────────┐│  \[Settings\]    RetroCam    \[Gallery\] ││                                     ││         ┌─────────────┐             ││         │             │             ││         │   CAMERA    │             ││         │   PREVIEW   │             ││         │  (filtered) │             ││         │             │             ││         └─────────────┘             ││                                     ││  \[Flash\] \[Flip\] \[REC●\] \[Zoom\]       ││                                     ││  ─────●───────────────────────────  ││  1975  1988  1995  2003  2008 ...   ││        ↑ selected                   ││                                     ││  \[1988 VHS Camcorder\]  \[Pro ▲\]      ││  Scan lines, chromatic aberration   ││  Date stamp, tracking noise         │└─────────────────────────────────────┘ |
| :---- |

**Year Picker (Timeline)**

• Horizontal scrollable timeline

• Years marked as dots

• Selected year shows preview instantly

• Locked years show padlock icon

• Tap locked year → Pro upsell modal

• Long-press any year → info card with historical context

**Recording Flow**

1\. User selects year (e.g., 1988\)

2\. Real-time preview shows filtered camera feed

3\. User taps REC (or presses Camera Control on iPhone 17 Pro Max)

4\. Recording starts with era-appropriate SFX (tape start sound for VHS)

5\. Date stamp appears and ticks in real-time

6\. User taps STOP (or Camera Control again)

7\. Era-appropriate SFX (tape stop for VHS)

8\. Processing screen (authenticity pipeline runs)

9\. Preview of final video

10\. Save to gallery \+ option to share

**Multi-Cam Split Mode**

| ┌─────────────────────────────────────┐│  \[Back: 1988 VHS\]  \[Front: 2008\]    ││  ┌────────────┐  ┌────────────┐     ││  │  BACK CAM  │  │ FRONT CAM  │     ││  │  (VHS)     │  │  (Nokia)   │     ││  └────────────┘  └────────────┘     ││                                     ││  \[REC●\]  \[Swap eras\]  \[Single\]      │└─────────────────────────────────────┘ |
| :---- |

• Tap either half to change that camera’s era

• Both record simultaneously

• Export as single video with split layout

• Audio: Mix both sources, apply era filter to each separately

**AR Date Stamp Mode**

• Switch to AR mode

• Date stamp floats in 3D space at fixed distance from camera

• Moves with parallax as camera moves

• Stays anchored to real-world position (ARKit plane detection)

• Example: Point at table, date stamp floats above table. Move phone, stamp moves realistically.

| TECHNICAL ARCHITECTURE |
| :---- |

**Video Pipeline**

| \[Camera Input\] → \[AVCaptureSession\]       ↓\[Frame Capture\] → \[CVPixelBuffer\]       ↓\[Metal Texture\] → \[MTLTexture from CVPixelBuffer\]       ↓\[Era Shader\] → \[Metal compute/fragment shader applies effects\]       ↓\[Preview\] → \[MTKView displays filtered frame\]       ↓\[Record Branch\] → \[AVAssetWriter writes filtered frames\]       ↓\[Audio Branch\] → \[AVAudioEngine applies era audio effects\]       ↓\[Export\] → \[Final MP4 with era-appropriate settings\] |
| :---- |

**Shader Architecture**

Each era is a JSON configuration file \+ Metal shader function:

| {  "era\_id": "vhs\_1988",  "name": "1988 VHS Camcorder",  "year": 1988,  "video": {    "resolution": \[720, 480\],    "frame\_rate": 30,    "interlaced": true,    "color\_space": "bt601",    "shader": "vhs1988\_fragment",    "auto\_exposure\_lock": true,    "iso\_simulation": 400  },  "audio": {    "sample\_rate": 44100,    "codec": "aac",    "bitrate": 128000,    "effects": \["hiss", "wow\_flutter", "low\_pass\_10k"\],    "hiss\_db": \-40,    "wow\_flutter\_hz": 5  },  "date\_stamp": {    "enabled": true,    "font": "digital7",    "color": "\#00FFFF",    "position": "bottom\_left",    "format": "MMM DD YYYY h:mm A",    "blinking\_rec": true,    "rec\_dot\_color": "\#FF0000"  },  "export": {    "container": "mp4",    "video\_codec": "h264",    "audio\_codec": "aac",    "authenticity\_pipeline": \["interlace", "chroma\_bleed", "scan\_lines"\]  }} |
| :---- |

The shader function **vhs1988\_fragment** is compiled Metal code that reads this config and applies the effects.

**Multi-Cam Architecture**

| \[Back Camera\] → \[Capture Session A\] → \[Shader A\] → \[Texture A\]\[Front Camera\] → \[Capture Session B\] → \[Shader B\] → \[Texture B\]       ↓                                               ↓       └────────→ \[Composite Shader\] → \[Split Layout\] → \[Preview/Record\] |
| :---- |

Two simultaneous AVCaptureSessions. Memory intensive but manageable on iPhone 17 Pro Max (8GB RAM). On older devices, limit to 1080p per camera.

**AR Date Stamp Architecture**

| \[ARKit Session\] → \[Plane Detection\] → \[Anchor Position\]       ↓\[Date Stamp Text\] → \[SCNText / RealityKit Text\] → \[3D Position\]       ↓\[Composite\] → \[Camera Feed \+ AR Overlay\] → \[Preview/Record\] |
| :---- |

Uses ARKit for plane detection and anchor placement. Date stamp is a 3D text node positioned in world space. Moves with parallax naturally.

**Audio Pipeline**

| \[Microphone\] → \[AVAudioEngine InputNode\]       ↓\[Effect Chain\] → \[Distortion\] → \[EQ\] → \[Reverb\] → \[Noise Generator\]       ↓\[Mix\] → \[AVAudioMixerNode\]       ↓\[Export\] → \[AVAssetWriter Audio Input\] |
| :---- |

Each era defines an audio effect chain. Effects are Core Audio units (AVAudioUnitEQ, AVAudioUnitDistortion, etc.) configured per era.

**Authenticity Pipeline (Post-Processing)**

For certain eras, additional processing after capture:

| \[Raw Recording\] → \[Era-Specific Encoder\]       ↓\[Encode to Authentic Codec\] → \[3GP, AVI, DV, etc.\]       ↓\[Decode\] → \[Extract artifacts\]       ↓\[Re-encode to MP4\] → \[Artifacts baked in\]       ↓\[Final Export\] |
| :---- |

**Example: Nokia 2008**

1\. Record raw video \+ audio

2\. Encode video to H.263 @ 320×240, 15fps

3\. Encode audio to AMR-NB @ 12.2kbps

4\. Wrap in 3GP container

5\. Decode 3GP

6\. Re-encode to H.264/AAC in MP4 container

7\. The 3GP compression artifacts are now permanent in the MP4

This is computationally expensive. Run on background queue. Show Live Activity with progress.

| BUILD ESTIMATE |
| :---- |

**V1 Scope (8 weeks, 2 developers)**

| Week | Developer A | Developer B |
| :---- | :---- | :---- |
| 1 | Camera pipeline \+ Metal preview | Audio engine \+ effect chain |
| 2 | Shader framework \+ 10 core eras | Date stamp system \+ fonts |
| 3 | 20 more eras \+ shader tuning | Export pipeline \+ authenticity |
| 4 | Remaining 22 eras | IAP integration (StoreKit 2\) |
| 5 | Multi-cam split mode | AR date stamp (ARKit) |
| 6 | UI polish \+ year picker | Gallery \+ sharing |
| 7 | App Store assets \+ ASO | Testing \+ bug fixes |
| 8 | Submission \+ launch prep | Marketing materials |

**Total:** 8 weeks, 2 developers.

**Risk Areas**

| Risk | Mitigation |
| :---- | :---- |
| 52 eras is too many for V1 | Ship with 15 eras, add rest in updates |
| Multi-cam memory pressure | Limit to 1080p on \<8GB devices |
| Authenticity pipeline too slow | Run async, show Live Activity progress |
| AR date stamp complex | Ship as Pro feature, fallback to 2D stamp |
| StoreKit 2 subscription issues | Test extensively on TestFlight |

| COMPETITIVE DIFFERENTIATION |  |  |
| :---- | :---- | :---- |
| **Competitor** | **What They Do** | **What RetroCam Does Better** |
| VHS Cam | VHS filter only | 52 eras, not just VHS |
| 8mm | 8mm film look | Authentic codec replication, not just filter |
| RetroCam (existing) | Basic filters | Audio effects, multi-cam, AR stamp |
| Prequel | Generic vintage | Year-specific accuracy, not “vintage” |
| TikTok filters | In-app only | Standalone app, export anywhere |

**The moat:** No competitor replicates actual camera settings, codecs, and limitations. They apply filters. We replicate hardware.

| NEXT STEPS |
| :---- |

1\. Lock the 3 free eras — Recommend: 1988 VHS, 2008 Nokia, 2012 Early Smartphone

2\. Prioritize 15 eras for V1 — The most iconic/requested years

3\. Design the year picker UI — Timeline vs. grid vs. carousel

4\. Source fonts — Digital-7, Nokia Pure equivalents, or design custom

5\. Build shader framework — One generic shader that reads era JSON config

6\. Prototype 3 eras — VHS, Nokia, MiniDV. Validate look/feel.

7\. Test multi-cam — Memory profiling on iPhone 17 Pro Max and iPhone 12

8\. Design AR stamp — How does it feel? Is it cool or gimmicky?