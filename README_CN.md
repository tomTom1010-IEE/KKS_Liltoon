# KKS lilToon

[English](README.md) | **简体中文**

面向 **Koikatsu Sunshine（KKS）**、Unity 2019.4.9f1 Built-in Render Pipeline 与 MaterialEditor 的非官方 lilToon 移植项目。

本项目的目标不是把 VRChat 运行环境整体搬进 KKS，而是在 KKS 可用的渲染条件下尽量保留 lilToon 的属性名称、参数语义和普通服装材质效果，让已有 lilToon 资产更容易迁移到 MaterialEditor。

> 当前版本：`0.1.1 Prototype`
> 项目仍处于开发阶段，不代表 lilToon 官方，也不保证所有原版材质可以无调整直接迁移。

## 设计原则

- 尽量沿用原版 lilToon 的属性名称和语义。
- MaterialEditor 无法使用 lilToon 自定义 Inspector，因此各渲染模式作为独立 shader 直接提供。
- 优先复现 KKS 服装资产常用的主贴图、透明、阴影、MatCap、高光、轮廓、发光和视差效果。
- 对 VR、AudioLink、VRC Light Volumes 等 KKS 中没有对应运行环境的功能不做强行模拟。
- 对 KKS 自透明问题保留专门的 depth/prepass 与 TwoPass 适配。

## 已提供的 Shader

### 主系列

- `lilToon`
- `lilToonCutout`
- `lilToonTransparent`
- `lilToonOnePassTransparent`
- `lilToonTwoPassTransparent`

### KKS 专用适配系列

- `lilToonKKSSkin` - 保留 lilToon Opaque 光照，同时直接兼容 KKS 身体的贴图、蒙版、叠加层、法线、alpha、emission 与区域汗水控制

### Lite 系列

- `lilToonLite`
- `lilToonLiteCutout`
- `lilToonLiteTransparent`
- `lilToonLiteOnePassTransparent`
- `lilToonLiteTwoPassTransparent`

### Tessellation 系列

- `lilToonTessellation`
- `lilToonTessellationCutout`
- `lilToonTessellationTransparent`
- `lilToonTessellationOnePassTransparent`
- `lilToonTessellationTwoPassTransparent`

### Fur 系列

- `lilToonFur`
- `lilToonFurCutout`
- `lilToonFurTwoPass`
- `lilToonFurOnlyTransparent`
- `lilToonFurOnlyCutout`
- `lilToonFurOnlyTwoPass`

### Refraction 系列

- `lilToonRefraction`
- `lilToonRefractionBlur`

### Gem 系列

- `lilToonGem`

所有 shader 都在 `manifest.xml` 中直接公开，不使用 `Hidden/...` 名称。每个 shader 都有对应的 Material 和 Prefab 入口。

## 当前复现程度

| 模块 | 状态 | 说明 |
| --- | --- | --- |
| Main / Main2nd / Main3rd | 高 | 主色、叠加层、UV 模式、decal、alpha mode、blend mask 等主路径已接入 |
| Alpha / Cutout | 高 | MainTex alpha、AlphaMask、Main2nd/3rd alpha mode、Cutoff、Dither 已接入 |
| Transparent / TwoPass | 高 | 连续 alpha、depth prepass、SubpassCutoff、OnePass 与正反面 TwoPass 已实现 |
| Normal Map | 高 | 主法线、第二法线、scale mask 与 KKS/Unity 法线解包路径已接入 |
| Shadow | 高 | 1st/2nd/3rd shadow、AO、mask、LOD、receive shadow、flat shadow 已实现 |
| Specular / Reflection | 较高 | Toon specular、GGX、metallic、smoothness、GSAA、anisotropy 与 cubemap 基础路径已实现 |
| MatCap | 高 | 双 MatCap、RGB mask、custom normal、shadow/backface mask、LOD blur 与 blend mode 已实现 |
| Rim / Backlight | 高 | Rim、Rim Shade、方向控制、阴影与透明度影响已接入 |
| Outline | 较高 | Forward、ForwardAdd、ShadowCaster、宽度/向量贴图与主要 render state 已实现 |
| Emission | 高 | 双层 emission、blink、gradation、parallax depth、fluorescence 已实现 |
| Glitter | 较高 | Voronoi 闪粉主路径、shape、randomize、lighting、shadow 与透明度影响已实现 |
| Main Parallax / POM | 较高 | 主贴图、法线、UV0 图层、AlphaMask、Depth、ShadowCaster 与 Outline 使用一致视差 UV |
| Lite | 较高 | 5 个轻量变体覆盖常用主贴图、阴影、法线、发光、MatCap、Rim、Outline 与透明渲染路径 |
| Tessellation | 较高 | 5 个变体使用 hull/domain shader，Forward、Outline、Depth 与 Shadow 路径保持一致 |
| Fur | 中高 | Geometry 多层毛、方向/长度/noise/mask/AO/rim、稳定随机与 TwoPass 已实现 |
| KKS Skin | 初步可用 | 主系列 Opaque 已适配 KKS 身体资产，包括颜色蒙版、叠加层、固定法线/alpha/Texture2/Texture3 命名、DetailMask 光滑度，以及通过 lilToon 路径渲染的区域汗水颜色与法线控制 |
| Dissolve | 高 | 全局及 Main2nd/Main3rd 的蒙版、UV、物体空间模式、滚动噪声与边缘发光已接入 Forward、Depth、Shadow 与 Outline 路径 |
| Refraction | 较高 | 已实现 GrabPass Fresnel 折射与粗糙度模糊；KKS 模糊版采用实用的单 Pass 近似 |
| Gem | 高 | 独立加算宝石路径，包含背景色散折射、环境反射色散、内部粒子、MatCap、Rim、Glitter 与 Emission |

如果只评价 KKS 普通服装资产最常用的 lilToon 功能，主系列已经具备较高可用度。若按原版 lilToon 的完整 shader 产品矩阵评价，本项目仍属于部分复现。

## 尚未实现或暂不计划实现

- AudioLink 与其他 VRChat 音频驱动效果。
- VR 专项、VRC Light Volumes、Motion Vector 等运行环境相关功能。
- ID Mask、Distance Fade 的完整路径。
- 面部 SDF shadow 专项。
- 完整的 reflection probe / box projection 高级适配。
- Overlay、Outline Only、FakeShadow、Multi 系列。
- Fur touch / collision、MultiFur、Tessellation + Fur 组合变体。
- 原版 lilToon Inspector、自动 keyword 管理与渐变贴图生成器。

## 与原版的主要差异

- KKS 使用 Unity 2019 Built-in Render Pipeline，场景灯光、间接光、反射探针和透明排序条件与 VRChat 不同。
- MaterialEditor 没有 lilToon 自定义 Inspector；需要直接选择对应 shader，并手动设置参数。
- 部分原版下拉菜单在 manifest 中以数值区间或分类属性暴露。
- TwoPass/depth 使用屏幕空间 dither 改善自透明；低分辨率下可能看到 4x4 方格纹理。
- POM、Tessellation 和 Fur 都会明显增加 GPU 开销，尤其是在多点光、阴影与轮廓同时开启时。
- Fur touch/collision 已有意屏蔽；当前 Fur 随机扰动使用稳定的 vertex ID，不随世界坐标移动。

## 项目结构

```text
liltoon/
├─ Shader/             ShaderLab 源码
│  └─ Includes/        KKS 版模块化 cginc
├─ Material/           MaterialEditor shader 入口材质
├─ Prefab/             AssetBundle 入口 prefab
├─ manifest.xml        Sideloader / MaterialEditor 声明
└─ goal.md             开发记录与后续方向
```

AssetBundle 路径：

```text
chara/tom/liltoon/shaders/liltoon.unity3d
```

只有 Prefab 分配 AssetBundle 名称；Shader 和 Material 作为依赖被 Unity 自动收集。

## 开发与构建

本仓库内容位于 Koikatsu Sunshine Modding Tools Unity 工程的：

```text
Assets/Mods/liltoon
```

开发环境：

- Unity `2019.4.9f1`
- Koikatsu Sunshine Modding Tools
- Windows / Direct3D 11
- MaterialEditor 与 Sideloader

最近一次 Unity `AssetDatabase.Refresh` 和强制 AssetBundle 构建已通过，22 个 shader 变体没有 lilToon/LTSKKS 编译错误。

仓库本身主要保存开发源码和 Unity 入口资产。面向普通玩家的安装包应使用构建完成的 zipmod，而不是直接把仓库放入游戏目录。

## 迁移提示

从 VRChat lilToon 材质迁移时，建议依次确认：

1. 根据原材质渲染模式选择 Opaque、Cutout、Transparent、OnePass 或 TwoPass。
2. 迁移 MainTex、Color、Main2nd/Main3rd、Normal、Shadow、Reflection、MatCap、Rim 和 Emission 属性。
3. 检查原版 Inspector 自动设置但 MaterialEditor 不会自动设置的 Cull、ZWrite、Blend、Cutoff 和透明 prepass 参数。
4. 最后再启用 POM、Tessellation、Glitter 或 Fur 等高开销功能。

## 上游项目与许可

本项目基于 [lilToon](https://github.com/lilxyzw/lilToon) 的算法、属性语义和 MIT 许可进行 KKS 适配。

- 原作者：lilxyzw
- 上游项目：<https://github.com/lilxyzw/lilToon>
- 本项目不是 lilToon 官方版本。

详细许可见 [LICENSE](LICENSE)。
