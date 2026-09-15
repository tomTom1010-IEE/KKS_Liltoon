# lilToon 法线采样诊断包

本包有独立 GUID、shader 名称和 AssetBundle 路径，可与正式版共存。
5 份 shader 均复制自当前 lilToon Opaque，保留原属性及 pass 结构；使用独立的 include 快照，不修改正式版。
这是诊断包，不是最终修复版。请在测试场景副本中使用，暂时不要用于发布角色卡或场景。

## 安装与基线

1. 关闭工作室，把 zipmod 放进游戏 `mods`，重新启动工作室。
2. 在同一个球体、同一个材质上依次切换以下 shader。不要只用不同位置的球体作比较。
3. 保持同一镜头、灯光、法线贴图与材质参数。主贴图 Scale=1,1、Offset=0,0；法线 Scale=20,20、强度=1。
4. 关闭第二层法线、视差、各向异性、MatCap、Glitter、Rim、Emission、Outline，保留之前的 Reflection 测试设置。
5. 默认 `DebugView=0`、`DebugUV0=0`。首先确认 Debug01 能复现正式版的问题；不能复现时先停止对照，核实版本与参数。
6. 可短暂设置 `DebugView=7`，确认表面变为纯洋红色，证明加载了诊断代码，然后恢复 0。

## 五个变体

| ME 中的 shader 名称 | 唯一主要改动 |
| --- | --- |
| lilToonDebug01Baseline | 基线：当前源码的固定 Linear/Repeat、自动 LOD。 |
| lilToonDebug02TextureSampler | 主法线改为读取纹理自带 sampler。 |
| lilToonDebug03FixedLOD | 主法线改用固定 LOD；新增 DebugLOD，默认 0。 |
| lilToonDebug04XukmiTBN | 使用 xukmi 式片元副切线重建及 TBN 转换。 |
| lilToonDebug05XukmiDecode | 主法线改用 xukmi 使用的 Unity UnpackScaleNormal 解码函数。 |

## Debug 分类参数

所有变体都有 `DebugView`，请输入整数：

| 数值 | 显示内容 |
| --- | --- |
| 0 | 正常完整着色。 |
| 1 | 原始主法线纹理 RGB，不做法线解码。 |
| 2 | 原始主法线纹理 A，灰度显示。 |
| 3 | 切线空间法线。 |
| 4 | 世界空间法线。 |
| 5 | 不受法线贴图影响的网格法线。 |
| 6 | 根据 UV 导数估算的隐式 LOD，除以 10 后灰度显示。 |
| 7 | 纯洋红色，确认诊断版本生效。 |

1–7 绕过材质光照和雾，关闭可见描边及附加光输出；游戏后处理仍可能改变显示颜色。
6 不是实际 GPU mip 层查询；即使使用 Debug03，它显示的也是自动 LOD 估算值，不是 DebugLOD。

`DebugUV0=1`：只把主法线的 UV 来源从 uvMain 改为原始 UV0，然后照常应用法线自身的 Scale/Offset。只在单独测试 UV 时开启，其余比较保持 0。

仅 Debug03 有 `DebugLOD`。固定镜头依次测试 0、1、2、3。LOD0 可能增加细密闪烁，请把它与大块三角形分层分开观察。

## 建议顺序

1. Debug01：先正常着色，再依次查看 DebugView 1、2、3、4、5、6，找到大块边界最早出现在哪一级。
2. Debug01：仅切换 DebugUV0，比较后恢复 0。
3. Debug02：与 Debug01 正常着色对照，必要时再看视图 1、3。
4. Debug03：依次测试固定 LOD 0、1、2、3。
5. Debug04：对照正常着色和世界空间法线（视图 4）。
6. Debug05：对照正常着色和切线空间法线（视图 3）。

每次反馈 shader 名称、DebugView、DebugUV0、DebugLOD（如适用）、大块边界是否仍在，以及相同镜头的截图即可。
这版不含强制 Trilinear、SampleGrad 或独立光照输出；先根据五组结果决定是否需要下一轮测试。
