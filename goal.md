lilToon 这个项目当前包含 `64` 个 `.shader` 文件。按用途大致可以分成这些：

**主系列**
- `lilToon`
- `Hidden/lilToonCutout`
- `Hidden/lilToonTransparent`
- `Hidden/lilToonTwoPassTransparent`
- `Hidden/lilToonOnePassTransparent`
- `Hidden/lilToonOutline`
- `Hidden/lilToonCutoutOutline`
- `Hidden/lilToonTransparentOutline`
- `Hidden/lilToonTwoPassTransparentOutline`
- `Hidden/lilToonOnePassTransparentOutline`

**可选 Outline Only / Overlay**
- `_lil/[Optional] lilToonOutlineOnly`
- `_lil/[Optional] lilToonOutlineOnlyCutout`
- `_lil/[Optional] lilToonOutlineOnlyTransparent`
- `_lil/[Optional] lilToonOverlay`
- `_lil/[Optional] lilToonOverlayOnePass`
- `_lil/[Optional] lilToonFakeShadow`

**Lite 系列**
- `Hidden/lilToonLite`
- `Hidden/lilToonLiteCutout`
- `Hidden/lilToonLiteTransparent`
- `Hidden/lilToonLiteTwoPassTransparent`
- `Hidden/lilToonLiteOnePassTransparent`
- `Hidden/lilToonLiteOutline`
- `Hidden/lilToonLiteCutoutOutline`
- `Hidden/lilToonLiteTransparentOutline`
- `Hidden/lilToonLiteTwoPassTransparentOutline`
- `Hidden/lilToonLiteOnePassTransparentOutline`
- `_lil/[Optional] lilToonLiteOverlay`
- `_lil/[Optional] lilToonLiteOverlayOnePass`

**Tessellation 系列**
- `Hidden/lilToonTessellation`
- `Hidden/lilToonTessellationCutout`
- `Hidden/lilToonTessellationTransparent`
- `Hidden/lilToonTessellationTwoPassTransparent`
- `Hidden/lilToonTessellationOnePassTransparent`
- `Hidden/lilToonTessellationOutline`
- `Hidden/lilToonTessellationCutoutOutline`
- `Hidden/lilToonTessellationTransparentOutline`
- `Hidden/lilToonTessellationTwoPassTransparentOutline`
- `Hidden/lilToonTessellationOnePassTransparentOutline`

**Fur / Gem / Refraction**
- `Hidden/lilToonFur`
- `Hidden/lilToonFurCutout`
- `Hidden/lilToonFurTwoPass`
- `_lil/[Optional] lilToonFurOnlyTransparent`
- `_lil/[Optional] lilToonFurOnlyCutout`
- `_lil/[Optional] lilToonFurOnlyTwoPass`
- `Hidden/lilToonGem`
- `Hidden/lilToonRefraction`
- `Hidden/lilToonRefractionBlur`

**Multi 系列**
- `_lil/lilToonMulti`
- `Hidden/lilToonMultiOutline`
- `Hidden/lilToonMultiFur`
- `Hidden/lilToonMultiGem`
- `Hidden/lilToonMultiRefraction`

**内部 Pass / 工具 Shader**
- `Hidden/ltspass_opaque`
- `Hidden/ltspass_cutout`
- `Hidden/ltspass_transparent`
- `Hidden/ltspass_lite_opaque`
- `Hidden/ltspass_lite_cutout`
- `Hidden/ltspass_lite_transparent`
- `Hidden/ltspass_tess_opaque`
- `Hidden/ltspass_tess_cutout`
- `Hidden/ltspass_tess_transparent`
- `Hidden/ltspass_dummy`
- `Hidden/ltspass_proponly`
- `Hidden/ltsother_baker`
- `Hidden/ltsother_bakeramp`

对我们复现 KKS 版本来说，最值得先研究的是 `lilToon`、Cutout、Transparent、Outline、Lite、Tessellation 这几条主线。Fur/Gem/Refraction/Multi 可以后置。