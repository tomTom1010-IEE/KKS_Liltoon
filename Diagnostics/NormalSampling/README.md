# Normal Sampling Diagnostics (2026-09-16)

Five full copies of the current lilToon opaque shader, using a private include
snapshot. The regular shaders, manifest, materials, and bundle are not replaced.
This zipmod has a separate GUID and bundle path. Keep the normal lilToon zipmod
installed. Remove this diagnostic zipmod after testing; do not distribute cards
or scenes that depend on these temporary shaders.

## Variants

| Shader | Difference from Debug01 |
| --- | --- |
| lilToonDebug01Baseline | Current production source snapshot, automatic LOD and fixed Linear/Repeat sampler. |
| lilToonDebug02TextureSampler | Only primary BumpMap uses its texture-owned sampler, as xukmi does. |
| lilToonDebug03FixedLOD | Only primary BumpMap uses SampleLevel with DebugLOD (default 0). |
| lilToonDebug04XukmiTBN | Rebuild binormal in the fragment; use interpolated, unnormalized tangent/normal in the TBN matrix, then normalize the transformed normal. |
| lilToonDebug05XukmiDecode | Only primary BumpMap uses Unity UnpackScaleNormal, as xukmi does. |

All ordinary lilToon properties and passes are retained, with their original
defaults. Use the same material values in every variant. The tests target
Windows D3D11. The TBN test keeps the handedness sign applied exactly once.

## Preparation

1. Close Studio, put this zipmod in the game's mods folder, then reopen Studio.
2. Use a copy of the existing test scene. Switch the same sphere/material between
   variants, keeping its transform, camera, lights, textures, and material values
   unchanged. Do not compare different positions as the only A/B test.
3. Use UseBumpMap=1, BumpScale=1, BumpMap Scale=20,20 and Offset=0,0.
   Keep MainTex Scale=1,1 and Offset=0,0; disable scrolling, rotation, parallax,
   second normal, anisotropy, MatCap, Glitter, Rim, Emission and Outline.
   Keep the original test's Reflection settings, Smoothness=0.5 and
   SpecularToon=0. Set DebugUV0=0 and DebugView=0 initially.
4. First check Debug01 reproduces the regular lilToon problem. If it does not,
   stop and compare versions/parameters before interpreting the other variants.
5. Set DebugView=7 briefly: a solid magenta sphere identifies the new diagnostic
   code. Restore DebugView=0 before comparing lit output.

## Debug Controls (MaterialEditor: Debug)

Set DebugView to an integer:

| Value | Output |
| --- | --- |
| 0 | Full original shading with the selected variant's one algorithm change. |
| 1 | Packed primary normal texture RGB, before normal decoding. |
| 2 | Packed primary normal texture alpha shown as grayscale. |
| 3 | Decoded tangent-space normal, mapped from [-1,1] to [0,1]. |
| 4 | World-space normal after TBN conversion and backface adjustment. |
| 5 | Normalized interpolated mesh normal, without the normal texture. |
| 6 | Estimated implicit isotropic LOD / 10, displayed as grayscale. |
| 7 | Solid magenta build marker. |

Views 1-7 bypass material lighting and fog, suppress visible outline and discard
ForwardAdd fragments. External post-processing can still affect the image.
View 6 estimates implicit LOD from UV derivatives; it is not a GPU sampler query.
Even in Debug03 it shows the automatic-LOD estimate, not DebugLOD.

DebugUV0=1 changes only the primary normal's UV input from uvMain to raw UV0
before BumpMap scale/offset. Leave it at 0 except during that separate UV test.
DebugLOD is exposed only in Debug03. Test 0,1,2,3; fractional values are allowed,
but the retained Linear sampler does not guarantee blending between mip levels.
Fixed LOD 0 can increase fine shimmer; observe large block boundaries separately.

## Test Order / Report

- Debug01: compare views 0,1,2,3,4,5,6 at the camera distance that shows blocks.
- Debug01: compare DebugUV0=0 versus 1, then restore 0.
- Debug02: compare to Debug01 with DebugView=0, then 1/3 as necessary.
- Debug03: compare DebugLOD=0,1,2,3, keeping the camera stationary.
- Debug04: compare to Debug01 with views 0 and 4.
- Debug05: compare to Debug01 with views 0 and 3.

For each result report shader name, DebugView, DebugUV0, DebugLOD (if present),
whether the large triangular boundaries remain, and one same-camera screenshot.
No single passing test proves a root cause; fixed LOD, for example, changes the
frequency content of the sampled normal as well as removing LOD transitions.

## Scope

No forced trilinear filtering, GSAA workaround, changed BRDF, or permanent fix.
No SampleGrad or isolated-lighting experiment is included in this first five-shader
package. The texture, sampler, LOD, TBN and decoding tests must be interpreted
before deciding whether those additional tests are necessary.
