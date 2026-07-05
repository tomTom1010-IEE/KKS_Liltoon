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

## KKS Transparent / TwoPass 屏幕空间 Dither 后续方案

当前 `lilToonTwoPassTransparent` 的可见噪点主要来自屏幕空间 dither，而不是 UV 贴图像素。它的优点是能改善半透明深度写入和自透明排序，缺点是 4x4 屏幕网格在 KKS 画面中容易被看见，尤其在大面积半透明布料、纱、玻璃、披风上会形成规则方格感。

后续完成主系列基础开发后，再评估是否需要做 KKS 特调版本。候选方案：

- 保留原版模式：继续使用 `_DitherMaskLOD` 的 4x4 screen-door dither，作为最接近 lilToon 原版的兼容模式。
- 高频 dither 模式：把 subpass/depth/shadow 的 dither 阈值改成更高频的 screen-space hash / interleaved gradient noise，让网格感变成更细的颗粒感。
- 可调 dither 密度：增加类似 `_SubpassDitherScale` 的内部或公开参数，控制 screen-space dither 的采样密度。默认保持原版，KKS 特调时提高密度。
- visible pass 与 depth pass 解耦：让 TwoPass 的可见 `FORWARD_BACK` 使用连续 alpha blend，不直接显示 dither；只让 depth/prepass/shadow 使用 dither 覆盖率。这会更适合 KKS 视觉，但会偏离原版 two-pass 行为。
- 可选模式设计：如果需要暴露给 ME，可以设计 `Subpass Dither Mode`，例如 `Original 4x4` / `High Frequency` / `KKS Soft`。如果不想增加 UI 复杂度，则先做成 KKS 分支内部默认行为。

评估标准：

- 多层透明衣服的自透明穿插是否明显减少。
- 大面积半透明材质是否还能看到规则方格。
- 运动镜头中 dither 是否闪烁。
- 透明阴影和 depth prepass 是否仍能保持足够稳定。
