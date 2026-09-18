# Normal sampling correction

Checkpoint: `0078ee7` (fixed addressing plus the five frozen diagnostic shaders).

The user's KKS A/B test reproduced the block boundaries in raw texture RGB/A
with Debug01, but not with Debug02's texture-owned sampler. This localizes the
observed problem to the sampling path; it does not identify the exact GPU filter
state difference, nor prove that an arbitrary inline sampler matches Debug02.

The production correction retains fixed addressing and adds one shared
`sampler_ltskks_trilinear_repeat_aniso8` for the nine normal texture slots. All
other textures retain their prior Linear Repeat/Clamp policy, including region
masks and LUTs. No public properties, shader defaults, UV transforms, normal
decoding, TBN, BRDF, lighting or pass structure change. The diagnostic snapshots
remain frozen for regression comparison.

Trilinear mip filtering and 8x anisotropic filtering explicitly improve the
normal sampling footprint without relying on a runtime texture's Wrap setting.
This is not an exact reproduction of Debug02's inherited sampler. It may cost
more texture bandwidth, and cannot create mip levels in textures without them.

## Validation status

On 2026-09-19, the user reported that the production `normalfilter1` package
passed their KKS test and approved pushing the correction to GitHub. Unity
AssetBundle compilation and the static sampling/diagnostic checks also passed.
This records user-reported visual acceptance, not an automated rendering test
or confirmation that every texture slot and hardware configuration was tested.

## Regression checklist in KKS (manual)

- With the same mesh, camera, 20x20 normal texture and reflection settings,
  verify the large block boundaries disappear in the regular lilToon shader.
- Verify Scale=1x1 still looks correct and Scale=20x20/25x30 repeats.
- Repeat the test with a texture whose actual wrap state is Clamp; shader
  addressing must still repeat. No game-wide texture state mutation is needed.
- Check Bump2ndMap plus its clamped scale mask, Skin normal/detail, Liquid
  normal and MatCap normal. Look for boundary seams at integer UV crossings.
- Check near/far and grazing camera angles. Compare against Debug01/Debug02.
- If the production candidate does not match the successful Debug02 result,
  retain the checkpoint and inspect actual GPU sampler states before broadening
  the fix. Do not claim the visual defect fixed from compilation alone.

## Automated checks

Run `Tests/Test-TextureSampling.ps1` for all 71 policies and the nine normal
filter exceptions. Run `Tests/Test-NormalDebugShaders.ps1` for the diagnostic
interface/private includes (use `-CheckProductionSnapshot` only when deliberately
checking out the original production checkpoint).

Unity refresh and AssetBundle compilation validate target-platform support.
The existing duplicate AssetBundleBrowser package GUID errors prevent use of
StrictMode; they must be reported separately from shader compilation errors.
