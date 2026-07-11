# KKS lilToon

**English** | [简体中文](README_CN.md)

An unofficial lilToon port for **Koikatsu Sunshine (KKS)**, Unity 2019.4.9f1 Built-in Render Pipeline, and MaterialEditor.

The goal is not to reproduce the entire VRChat runtime inside KKS. Instead, this project preserves lilToon's property names, parameter semantics, and common clothing-material effects wherever the KKS rendering environment allows it, making existing lilToon assets easier to migrate to MaterialEditor.

> Current version: `0.0.1 Prototype`
> This project is still under development. It is not an official lilToon release, and materials may require manual adjustment after migration.

## Design Goals

- Preserve original lilToon property names and semantics where practical.
- Expose every render mode as a directly selectable shader because MaterialEditor cannot use the lilToon custom Inspector.
- Prioritize features commonly used by KKS clothing assets: layered main textures, transparency, shadows, MatCap, specular, outlines, emission, and parallax.
- Avoid simulating VR, AudioLink, VRC Light Volumes, and other features without a corresponding KKS runtime.
- Keep KKS-specific depth/prepass and TwoPass behavior for reducing transparent self-sorting artifacts.

## Available Shaders

### Main Series

- `lilToon`
- `lilToonCutout`
- `lilToonTransparent`
- `lilToonOnePassTransparent`
- `lilToonTwoPassTransparent`

### Tessellation Series

- `lilToonTessellation`
- `lilToonTessellationCutout`
- `lilToonTessellationTransparent`
- `lilToonTessellationOnePassTransparent`
- `lilToonTessellationTwoPassTransparent`

### Fur Series

- `lilToonFur`
- `lilToonFurCutout`
- `lilToonFurTwoPass`
- `lilToonFurOnlyTransparent`
- `lilToonFurOnlyCutout`
- `lilToonFurOnlyTwoPass`

All shaders are exposed directly through `manifest.xml` without `Hidden/...` names. Every shader has a matching Material and Prefab entry.

## Current Porting Status

| Module | Status | Notes |
| --- | --- | --- |
| Main / Main2nd / Main3rd | High | Main color, layered textures, UV modes, decals, alpha modes, and blend masks are implemented |
| Alpha / Cutout | High | MainTex alpha, AlphaMask, Main2nd/3rd alpha modes, Cutoff, and Dither are implemented |
| Transparent / TwoPass | High | Continuous alpha, depth prepass, SubpassCutoff, OnePass, and front/back TwoPass rendering are implemented |
| Normal Maps | High | Primary and secondary normal maps, scale masks, and Unity/KKS normal unpacking are implemented |
| Shadows | High | 1st/2nd/3rd shadows, AO, masks, mask LOD, receive shadow, and flat shadow are implemented |
| Specular / Reflection | Medium-high | Toon specular, GGX, metallic, smoothness, GSAA, anisotropy, and basic cubemap paths are implemented |
| MatCap | High | Two MatCap layers, RGB masks, custom normals, shadow/backface masks, LOD blur, and blend modes are implemented |
| Rim / Backlight | High | Rim, Rim Shade, directional controls, shadow influence, and transparency influence are implemented |
| Outline | Medium-high | Forward, ForwardAdd, ShadowCaster, width/vector textures, and major render states are implemented |
| Emission | High | Two emission layers, blink, gradation, parallax depth, and fluorescence are implemented |
| Glitter | Medium-high | Voronoi glitter, shape texture, randomization, lighting, shadow, and transparency influence are implemented |
| Main Parallax / POM | Medium-high | Main texture, normal maps, UV0 layers, AlphaMask, Depth, ShadowCaster, and Outline use consistent parallax UVs |
| Tessellation | Medium-high | Five hull/domain shader variants keep Forward, Outline, Depth, and Shadow geometry consistent |
| Fur | Medium-high | Geometry-layer fur, direction/length/noise/masks/AO/rim, stable randomization, and TwoPass rendering are implemented |

The common lilToon feature set used by KKS clothing materials is already broadly usable. Compared with the complete upstream lilToon shader matrix, however, this remains a partial port.

## Not Implemented or Currently Out of Scope

- AudioLink and other VRChat audio-driven effects.
- VR-specific behavior, VRC Light Volumes, Motion Vectors, and similar runtime integrations.
- Complete Dissolve, ID Mask, and Distance Fade paths.
- Dedicated face SDF shadows.
- Advanced reflection probe and box-projection compatibility.
- Lite, Overlay, Outline Only, FakeShadow, and Multi series.
- Gem, Refraction, and Refraction Blur.
- Fur touch/collision, MultiFur, and Tessellation + Fur combinations.
- The original lilToon Inspector, automatic keyword management, and gradient texture generation tools.

## Major Differences from Upstream lilToon

- KKS uses Unity 2019's Built-in Render Pipeline. Scene lighting, indirect light, reflection probes, and transparency sorting differ from VRChat environments.
- MaterialEditor cannot run the lilToon custom Inspector. Users must select the appropriate shader variant and configure its properties manually.
- Some upstream dropdown controls are exposed through numeric ranges or separate MaterialEditor categories.
- TwoPass/depth rendering uses screen-space dither to reduce transparent self-sorting artifacts. The original 4x4 pattern may be visible at low resolutions.
- POM, Tessellation, and Fur can be expensive, especially with multiple lights, shadows, and outlines enabled.
- Fur touch/collision is intentionally disabled. Fur randomization uses stable vertex IDs and does not change when an object moves through world space.

## Repository Layout

```text
liltoon/
├─ Shader/             ShaderLab sources
│  └─ Includes/        Modular KKS cginc implementation
├─ Material/           MaterialEditor shader entry materials
├─ Prefab/             AssetBundle entry prefabs
├─ manifest.xml        Sideloader / MaterialEditor declarations
└─ goal.md             Development notes and future work
```

AssetBundle path:

```text
chara/tom/liltoon/shaders/liltoon.unity3d
```

Only Prefabs receive an AssetBundle assignment. Unity collects Shaders and Materials as dependencies.

## Development and Building

This repository is intended to live in a Koikatsu Sunshine Modding Tools Unity project at:

```text
Assets/Mods/liltoon
```

Development environment:

- Unity `2019.4.9f1`
- Koikatsu Sunshine Modding Tools
- Windows / Direct3D 11
- MaterialEditor and Sideloader

The latest Unity `AssetDatabase.Refresh` and forced AssetBundle build completed successfully with no lilToon/LTSKKS shader compilation errors across the 16 variants.

This repository contains development sources and Unity entry assets. End users should install a built zipmod release rather than copying the repository directly into the game directory.

## Material Migration Notes

When migrating a VRChat lilToon material:

1. Select the matching Opaque, Cutout, Transparent, OnePass, or TwoPass shader.
2. Transfer MainTex, Color, Main2nd/Main3rd, Normal, Shadow, Reflection, MatCap, Rim, and Emission properties.
3. Verify Cull, ZWrite, Blend, Cutoff, and transparent prepass settings that the original Inspector normally configures automatically.
4. Enable high-cost features such as POM, Tessellation, Glitter, or Fur only after the base material is working.

## Upstream Project and License

This project adapts algorithms and property semantics from [lilToon](https://github.com/lilxyzw/lilToon) under the MIT License.

- Original author: lilxyzw
- Upstream project: <https://github.com/lilxyzw/lilToon>
- This repository is not an official lilToon distribution.

See [LICENSE](LICENSE) for the full license text.
