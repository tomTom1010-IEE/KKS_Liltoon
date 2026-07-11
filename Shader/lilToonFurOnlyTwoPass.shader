Shader "lilToonFurOnlyTwoPass"
{
    Properties
    {
        // Base
        _Invisible ("sInvisible", Int) = 0
        _AsUnlit ("sAsUnlit", Range(0, 1)) = 0
        _Cutoff ("sCutoff", Range(-0.001, 1.001)) = 0.001
        _SubpassCutoff ("sSubpassCutoff", Range(0, 1)) = 0.5
        _FlipNormal ("sFlipBackfaceNormal", Int) = 0
        _ShiftBackfaceUV ("sShiftBackfaceUV", Int) = 0
        _BackfaceForceShadow ("sBackfaceForceShadow", Range(0, 1)) = 0
        [HDR] _BackfaceColor ("sColor", Color) = (0,0,0,0)
        _VertexLightStrength ("sVertexLightStrength", Range(0, 1)) = 0
        _LightMinLimit ("sLightMinLimit", Range(0, 1)) = 0.05
        _LightMaxLimit ("sLightMaxLimit", Range(0, 10)) = 1
        _BeforeExposureLimit ("sBeforeExposureLimit", Float) = 10000
        _MonochromeLighting ("sMonochromeLighting", Range(0, 1)) = 0
        _AlphaBoostFA ("sAlphaBoostFA", Range(1, 100)) = 10
        _lilDirectionalLightStrength ("sDirectionalLightStrength", Range(0, 1)) = 1
        _LightDirectionOverride ("sLightDirectionOverrides", Vector) = (0.001,0.002,0.001,0)
        _AAStrength ("sAAShading", Range(0, 1)) = 1
        _UseDither ("sDither", Int) = 0
        [NoScaleOffset] _DitherTex ("Dither", 2D) = "white" {}
        _DitherMaxValue ("Max Value", Float) = 255
        _EnvRimBorder ("[VRCLV] Rim Border", Range(0, 3)) = 3
        _EnvRimBlur ("[VRCLV] Rim Blur", Range(0, 1)) = 0.35

        // Main
        [HDR] [MainColor] _Color ("sColor", Color) = (1,1,1,1)
        [MainTexture] _MainTex ("Texture", 2D) = "white" {}
        _MainTex_ScrollRotate ("sScrollRotates", Vector) = (0,0,0,0)
        _MainTexHSVG ("sHSVGs", Vector) = (0,1,1,1)
        _MainGradationStrength ("Gradation Strength", Range(0, 1)) = 0
        [NoScaleOffset] _MainGradationTex ("Gradation Map", 2D) = "white" {}
        [NoScaleOffset] _MainColorAdjustMask ("Adjust Mask", 2D) = "white" {}

        // Parallax
        _UseParallax ("sParallax", Int) = 0
        _UsePOM ("sPOM", Int) = 0
        [NoScaleOffset] _ParallaxMap ("Parallax Map", 2D) = "gray" {}
        _Parallax ("Parallax Scale", Float) = 0.02
        _ParallaxOffset ("sParallaxOffset", Float) = 0.5

        // Main2nd
        _UseMain2ndTex ("sMainColor2nd", Int) = 0
        [HDR] _Color2nd ("sColor", Color) = (1,1,1,1)
        _Main2ndTex ("Texture", 2D) = "white" {}
        _Main2ndTexAngle ("sAngle", Float) = 0
        _Main2ndTex_ScrollRotate ("sScrollRotates", Vector) = (0,0,0,0)
        _Main2ndTex_UVMode ("UV Mode", Int) = 0
        _Main2ndTex_Cull ("sCullModes", Int) = 0
        _Main2ndTexDecalAnimation ("sDecalAnimations", Vector) = (1,1,1,30)
        _Main2ndTexDecalSubParam ("sDecalSubParams", Vector) = (1,1,0,1)
        _Main2ndTexIsDecal ("sAsDecal", Int) = 0
        _Main2ndTexIsLeftOnly ("Left Only", Int) = 0
        _Main2ndTexIsRightOnly ("Right Only", Int) = 0
        _Main2ndTexShouldCopy ("Copy", Int) = 0
        _Main2ndTexShouldFlipMirror ("Flip Mirror", Int) = 0
        _Main2ndTexShouldFlipCopy ("Flip Copy", Int) = 0
        _Main2ndTexIsMSDF ("sAsMSDF", Int) = 0
        [NoScaleOffset] _Main2ndBlendMask ("Mask", 2D) = "white" {}
        _Main2ndTexBlendMode ("sBlendModes", Int) = 0
        _Main2ndTexAlphaMode ("sAlphaModes", Int) = 0
        _Main2ndEnableLighting ("sEnableLighting", Range(0, 1)) = 1
        _Main2ndDistanceFade ("sDistanceFadeSettings", Vector) = (0.1,0.01,0,0)

        // Main3rd
        _UseMain3rdTex ("sMainColor3rd", Int) = 0
        [HDR] _Color3rd ("sColor", Color) = (1,1,1,1)
        _Main3rdTex ("Texture", 2D) = "white" {}
        _Main3rdTexAngle ("sAngle", Float) = 0
        _Main3rdTex_ScrollRotate ("sScrollRotates", Vector) = (0,0,0,0)
        _Main3rdTex_UVMode ("UV Mode", Int) = 0
        _Main3rdTex_Cull ("sCullModes", Int) = 0
        _Main3rdTexDecalAnimation ("sDecalAnimations", Vector) = (1,1,1,30)
        _Main3rdTexDecalSubParam ("sDecalSubParams", Vector) = (1,1,0,1)
        _Main3rdTexIsDecal ("sAsDecal", Int) = 0
        _Main3rdTexIsLeftOnly ("Left Only", Int) = 0
        _Main3rdTexIsRightOnly ("Right Only", Int) = 0
        _Main3rdTexShouldCopy ("Copy", Int) = 0
        _Main3rdTexShouldFlipMirror ("Flip Mirror", Int) = 0
        _Main3rdTexShouldFlipCopy ("Flip Copy", Int) = 0
        _Main3rdTexIsMSDF ("sAsMSDF", Int) = 0
        [NoScaleOffset] _Main3rdBlendMask ("Mask", 2D) = "white" {}
        _Main3rdTexBlendMode ("sBlendModes", Int) = 0
        _Main3rdTexAlphaMode ("sAlphaModes", Int) = 0
        _Main3rdEnableLighting ("sEnableLighting", Range(0, 1)) = 1
        _Main3rdDistanceFade ("sDistanceFadeSettings", Vector) = (0.1,0.01,0,0)

        // Alpha Mask
        _AlphaMaskMode ("sAlphaMaskModes", Int) = 0
        _AlphaMask ("AlphaMask", 2D) = "white" {}
        _AlphaMaskScale ("Scale", Float) = 1
        _AlphaMaskValue ("Offset", Float) = 0

        // NormalMap
        _UseBumpMap ("sNormalMap", Int) = 0
        [Normal] _BumpMap ("Normal Map", 2D) = "bump" {}
        _BumpScale ("Scale", Range(-10, 10)) = 1
        _UseBump2ndMap ("sNormalMap2nd", Int) = 0
        [Normal] _Bump2ndMap ("Normal Map", 2D) = "bump" {}
        _Bump2ndMap_UVMode ("UV Mode", Int) = 0
        _Bump2ndScale ("Scale", Range(-10, 10)) = 1
        [NoScaleOffset] _Bump2ndScaleMask ("Mask", 2D) = "white" {}

        // Anisotropy
        _UseAnisotropy ("sAnisotropy", Int) = 0
        [Normal] _AnisotropyTangentMap ("Tangent Map", 2D) = "bump" {}
        _AnisotropyScale ("Scale", Range(-1, 1)) = 1
        [NoScaleOffset] _AnisotropyScaleMask ("Scale Mask", 2D) = "white" {}
        _AnisotropyTangentWidth ("sTangentWidth", Range(0, 10)) = 1
        _AnisotropyBitangentWidth ("sBitangentWidth", Range(0, 10)) = 1
        _AnisotropyShift ("sOffset", Range(-10, 10)) = 0
        _AnisotropyShiftNoiseScale ("sNoiseStrength", Range(-1, 1)) = 0
        _AnisotropySpecularStrength ("sStrength", Range(0, 10)) = 1
        _Anisotropy2ndTangentWidth ("sTangentWidth", Range(0, 10)) = 1
        _Anisotropy2ndBitangentWidth ("sBitangentWidth", Range(0, 10)) = 1
        _Anisotropy2ndShift ("sOffset", Range(-10, 10)) = 0
        _Anisotropy2ndShiftNoiseScale ("sNoiseStrength", Range(-1, 1)) = 0
        _Anisotropy2ndSpecularStrength ("sStrength", Range(0, 10)) = 0
        _AnisotropyShiftNoiseMask ("sNoise", 2D) = "white" {}
        _Anisotropy2Reflection ("sReflection", Int) = 0
        _Anisotropy2MatCap ("sMatCap", Int) = 0
        _Anisotropy2MatCap2nd ("sMatCap2nd", Int) = 0

        // Backlight
        _UseBacklight ("sBacklight", Int) = 0
        [HDR] _BacklightColor ("sColor", Color) = (0.85,0.8,0.7,1)
        [NoScaleOffset] _BacklightColorTex ("Texture", 2D) = "white" {}
        _BacklightMainStrength ("sMainColorPower", Range(0, 1)) = 0
        _BacklightNormalStrength ("sNormalStrength", Range(0, 1)) = 1
        _BacklightBorder ("Border", Range(0, 1)) = 0.35
        _BacklightBlur ("sBlur", Range(0, 1)) = 0.05
        _BacklightDirectivity ("sDirectivity", Float) = 5
        _BacklightViewStrength ("sViewDirectionStrength", Range(0, 1)) = 1
        _BacklightReceiveShadow ("sReceiveShadow", Int) = 1
        _BacklightBackfaceMask ("sBackfaceMask", Int) = 1

        // Shadow
        _UseShadow ("sShadow", Int) = 0
        _ShadowStrength ("sStrength", Range(0, 1)) = 1
        [NoScaleOffset] _ShadowStrengthMask ("sStrength", 2D) = "white" {}
        _ShadowStrengthMaskLOD ("LOD", Range(0, 1)) = 0
        [NoScaleOffset] _ShadowBorderMask ("sBorder", 2D) = "white" {}
        _ShadowBorderMaskLOD ("LOD", Range(0, 1)) = 0
        [NoScaleOffset] _ShadowBlurMask ("sBlur", 2D) = "white" {}
        _ShadowBlurMaskLOD ("LOD", Range(0, 1)) = 0
        _ShadowAOShift ("1st Scale|1st Offset|2nd Scale|2nd Offset", Vector) = (1,0,1,0)
        _ShadowAOShift2 ("3rd Scale|3rd Offset", Vector) = (1,0,1,0)
        _ShadowPostAO ("sIgnoreBorderProperties", Int) = 0
        _ShadowColorType ("sShadowColorTypes", Int) = 0
        _ShadowColor ("Shadow Color", Color) = (0.82,0.76,0.85,1)
        [NoScaleOffset] _ShadowColorTex ("Shadow Color", 2D) = "black" {}
        _ShadowNormalStrength ("sNormalStrength", Range(0, 1)) = 1
        _ShadowBorder ("sBorder", Range(0, 1)) = 0.5
        _ShadowBlur ("sBlur", Range(0, 1)) = 0.1
        _ShadowReceive ("sReceiveShadow", Range(0, 1)) = 0
        _Shadow2ndColor ("2nd Color", Color) = (0.68,0.66,0.79,1)
        [NoScaleOffset] _Shadow2ndColorTex ("2nd Color", 2D) = "black" {}
        _Shadow2ndNormalStrength ("sNormalStrength", Range(0, 1)) = 1
        _Shadow2ndBorder ("sBorder", Range(0, 1)) = 0.15
        _Shadow2ndBlur ("sBlur", Range(0, 1)) = 0.1
        _Shadow2ndReceive ("sReceiveShadow", Range(0, 1)) = 0
        _Shadow3rdColor ("3rd Color", Color) = (0,0,0,0)
        [NoScaleOffset] _Shadow3rdColorTex ("3rd Color", 2D) = "black" {}
        _Shadow3rdNormalStrength ("sNormalStrength", Range(0, 1)) = 1
        _Shadow3rdBorder ("sBorder", Range(0, 1)) = 0.25
        _Shadow3rdBlur ("sBlur", Range(0, 1)) = 0.1
        _Shadow3rdReceive ("sReceiveShadow", Range(0, 1)) = 0
        _ShadowBorderColor ("sShadowBorderColor", Color) = (1,0.1,0,1)
        _ShadowBorderRange ("sShadowBorderRange", Range(0, 1)) = 0.08
        _ShadowMainStrength ("sContrast", Range(0, 1)) = 0
        _ShadowEnvStrength ("sShadowEnvStrength", Range(0, 1)) = 0
        _ShadowMaskType ("sShadowMaskTypes", Int) = 0
        _ShadowFlatBorder ("sBorder", Range(-2, 2)) = 1
        _ShadowFlatBlur ("sBlur", Range(0.001, 2)) = 1

        // Rim Shade
        _UseRimShade ("RimShade", Int) = 0
        _RimShadeColor ("sColor", Color) = (0.5,0.5,0.5,1)
        [NoScaleOffset] _RimShadeMask ("Mask", 2D) = "white" {}
        _RimShadeNormalStrength ("sNormalStrength", Range(0, 1)) = 1
        _RimShadeBorder ("sBorder", Range(0, 1)) = 0.5
        _RimShadeBlur ("sBlur", Range(0, 1)) = 1
        _RimShadeFresnelPower ("sFresnelPower", Range(0.01, 50)) = 1

        // Reflection
        _UseReflection ("sReflection", Int) = 0
        _Smoothness ("Smoothness", Range(0, 1)) = 1
        [NoScaleOffset] _SmoothnessTex ("Smoothness", 2D) = "white" {}
        [Gamma] _Metallic ("Metallic", Range(0, 1)) = 0
        [NoScaleOffset] _MetallicGlossMap ("Metallic", 2D) = "white" {}
        [Gamma] _Reflectance ("sReflectance", Range(0, 1)) = 0.04
        _GSAAStrength ("GSAA", Range(0, 1)) = 0
        _ApplySpecular ("Apply Specular", Int) = 1
        _ApplySpecularFA ("sMultiLightSpecular", Int) = 1
        _SpecularToon ("Specular Toon", Int) = 1
        _SpecularNormalStrength ("sNormalStrength", Range(0, 1)) = 1
        _SpecularBorder ("sBorder", Range(0, 1)) = 0.5
        _SpecularBlur ("sBlur", Range(0, 1)) = 0
        _ApplyReflection ("sApplyReflection", Int) = 0
        _ReflectionNormalStrength ("sNormalStrength", Range(0, 1)) = 1
        [HDR] _ReflectionColor ("sColor", Color) = (1,1,1,1)
        [NoScaleOffset] _ReflectionColorTex ("sColor", 2D) = "white" {}
        _ReflectionApplyTransparency ("sApplyTransparency", Int) = 1
        [NoScaleOffset] _ReflectionCubeTex ("Cubemap Fallback", Cube) = "black" {}
        [HDR] _ReflectionCubeColor ("sColor", Color) = (0,0,0,1)
        _ReflectionCubeOverride ("Override", Int) = 0
        _ReflectionCubeEnableLighting ("sEnableLighting+ (Fallback)", Range(0, 1)) = 1
        _ReflectionBlendMode ("sBlendModes", Int) = 1

        // MatCap
        _UseMatCap ("sMatCap", Int) = 0
        [HDR] _MatCapColor ("sColor", Color) = (1,1,1,1)
        _MatCapTex ("Texture", 2D) = "white" {}
        [NoScaleOffset] _MatCapBlendMask ("Mask", 2D) = "white" {}
        _MatCapBlend ("Blend", Range(0, 1)) = 1
        _MatCapBlendMode ("sBlendModes", Int) = 1
        _MatCapEnableLighting ("sEnableLighting", Range(0, 1)) = 1
        _MatCapShadowMask ("sShadowMask", Range(0, 1)) = 0
        _MatCapBackfaceMask ("sBackfaceMask", Int) = 1
        _MatCapLod ("Blur", Range(0, 10)) = 0
        _MatCapApplyTransparency ("sApplyTransparency", Int) = 1
        _MatCapNormalStrength ("sNormalStrength", Range(0, 1)) = 1
        _MatCapCustomNormal ("sMatCapCustomNormal", Int) = 0
        _MatCapMainStrength ("sMainColorPower", Range(0, 1)) = 0
        _MatCapPerspective ("Perspective", Int) = 1
        _MatCapZRotCancel ("Z-axis Rotation Cancellation", Int) = 1
        _MatCapVRParallaxStrength ("VR Parallax Strength", Range(0, 1)) = 1
        [Normal] _MatCapBumpMap ("Normal Map", 2D) = "bump" {}
        _MatCapBumpScale ("Scale", Range(-10, 10)) = 1
        _MatCapBlendUV1 ("sBlendUV1", Vector) = (0,0,0,0)

        // MatCap 2nd
        _UseMatCap2nd ("sMatCap2nd", Int) = 0
        [HDR] _MatCap2ndColor ("sColor", Color) = (1,1,1,1)
        _MatCap2ndTex ("Texture", 2D) = "white" {}
        [NoScaleOffset] _MatCap2ndBlendMask ("Mask", 2D) = "white" {}
        _MatCap2ndBlend ("Blend", Range(0, 1)) = 1
        _MatCap2ndBlendMode ("sBlendModes", Int) = 1
        _MatCap2ndEnableLighting ("sEnableLighting", Range(0, 1)) = 1
        _MatCap2ndShadowMask ("sShadowMask", Range(0, 1)) = 0
        _MatCap2ndBackfaceMask ("sBackfaceMask", Int) = 1
        _MatCap2ndLod ("Blur", Range(0, 10)) = 0
        _MatCap2ndApplyTransparency ("sApplyTransparency", Int) = 1
        _MatCap2ndNormalStrength ("sNormalStrength", Range(0, 1)) = 1
        _MatCap2ndCustomNormal ("sMatCapCustomNormal", Int) = 0
        _MatCap2ndMainStrength ("sMainColorPower", Range(0, 1)) = 0
        _MatCap2ndPerspective ("Perspective", Int) = 1
        _MatCap2ndZRotCancel ("Z-axis Rotation Cancellation", Int) = 1
        _MatCap2ndVRParallaxStrength ("VR Parallax Strength", Range(0, 1)) = 1
        [Normal] _MatCap2ndBumpMap ("Normal Map", 2D) = "bump" {}
        _MatCap2ndBumpScale ("Scale", Range(-10, 10)) = 1
        _MatCap2ndBlendUV1 ("sBlendUV1", Vector) = (0,0,0,0)

        // Rim
        _UseRim ("sRimLight", Int) = 0
        [HDR] _RimColor ("sColor", Color) = (1,1,1,1)
        [NoScaleOffset] _RimColorTex ("Texture", 2D) = "white" {}
        _RimMainStrength ("sMainColorPower", Range(0, 1)) = 0
        _RimNormalStrength ("sNormalStrength", Range(0, 1)) = 1
        [HDR] _RimIndirColor ("sColor", Color) = (1,1,1,1)
        _RimBorder ("sBorder", Range(0, 1)) = 0.5
        _RimBlur ("sBlur", Range(0, 1)) = 0.65
        _RimFresnelPower ("sFresnelPower", Range(0.01, 50)) = 3
        _RimShadowMask ("sShadowMask", Range(0, 1)) = 0
        _RimBackfaceMask ("sBackfaceMask", Int) = 1
        _RimVRParallaxStrength ("VR Parallax Strength", Range(0, 1)) = 1
        _RimApplyTransparency ("sApplyTransparency", Int) = 1
        _RimEnableLighting ("sEnableLighting", Range(0, 1)) = 1
        _RimBlendMode ("sBlendModes", Int) = 1
        _RimDirStrength ("sDirectionStrength", Range(0, 1)) = 0
        _RimDirRange ("sDirectionRange", Range(-1, 1)) = 0
        _RimIndirRange ("sIndirectionRange", Range(-1, 1)) = 0
        _RimIndirBorder ("sBorder", Range(0, 1)) = 0.5
        _RimIndirBlur ("sBlur", Range(0, 1)) = 0.1
        _RimIndirColorStrength ("sIndirectionColorStrength", Range(0, 1)) = 0

        // Glitter
        _UseGlitter ("sGlitter", Int) = 0
        _GlitterUVMode ("UV Mode", Int) = 0
        [HDR] _GlitterColor ("sColor", Color) = (1,1,1,1)
        _GlitterColorTex ("Texture", 2D) = "white" {}
        _GlitterColorTex_UVMode ("UV Mode", Int) = 0
        _GlitterMainStrength ("sMainColorPower", Range(0, 1)) = 0
        _GlitterNormalStrength ("sNormalStrength", Range(0, 1)) = 1
        _GlitterScaleRandomize ("sRandomize+ (Size)", Range(0, 1)) = 0
        _GlitterApplyShape ("Shape", Int) = 0
        _GlitterShapeTex ("Texture", 2D) = "white" {}
        _GlitterAtras ("Atras", Vector) = (1,1,0,0)
        _GlitterAngleRandomize ("sRandomize+ (+sAngle+)", Int) = 0
        _GlitterParams1 ("Tiling|Particle Size|Contrast", Vector) = (256,256,0.16,50)
        _GlitterParams2 ("sGlitterParams2", Vector) = (0.25,0,0,0)
        _GlitterPostContrast ("sPostContrast", Float) = 1
        _GlitterSensitivity ("Sensitivity", Float) = 0.25
        _GlitterEnableLighting ("sEnableLighting", Range(0, 1)) = 1
        _GlitterShadowMask ("sShadowMask", Range(0, 1)) = 0
        _GlitterBackfaceMask ("sBackfaceMask", Int) = 0
        _GlitterApplyTransparency ("sApplyTransparency", Int) = 1
        _GlitterVRParallaxStrength ("sVRParallaxStrength", Range(0, 1)) = 0

        // Fur
        _FurNoiseMask ("Noise", 2D) = "white" {}
        [NoScaleOffset] _FurMask ("Mask", 2D) = "white" {}
        [NoScaleOffset] _FurLengthMask ("Length Mask", 2D) = "white" {}
        [NoScaleOffset][Normal] _FurVectorTex ("Vector", 2D) = "bump" {}
        _FurVectorScale ("Vector scale", Range(-10,10)) = 1
        _FurVector ("sFurVectors", Vector) = (0.0,0.0,1.0,0.02)
        _VertexColor2FurVector ("sVertexColor2Vector", Int) = 0
        _FurGravity ("sGravity", Range(0,1)) = 0.25
        _FurRandomize ("sRandomize", Float) = 0
        _FurAO ("sAO", Range(0,1)) = 0
        _FurLayerNum ("sLayerNum", Range(1,3)) = 2
        _FurRootOffset ("sRootWidth", Range(-1,0)) = 0
        _FurCutoutLength ("sLength+ (Cutout)", Float) = 0.8
        _FurTouchStrength ("sTouchStrength", Range(0,1)) = 0
        [HDR] _FurRimColor ("sColor", Color) = (0.0,0.0,0.0,1.0)
        _FurRimFresnelPower ("sFresnelPower", Range(0.01,50)) = 3.0
        _FurRimAntiLight ("sAntiLight", Range(0,1)) = 0.5

        // Fur Rendering
        _FurCull ("sCullModes", Int) = 0
        _FurSrcBlend ("sSrcBlendRGB", Int) = 5
        _FurDstBlend ("sDstBlendRGB", Int) = 10
        _FurSrcBlendAlpha ("sSrcBlendAlpha", Int) = 1
        _FurDstBlendAlpha ("sDstBlendAlpha", Int) = 10
        _FurBlendOp ("sBlendOpRGB", Int) = 0
        _FurBlendOpAlpha ("sBlendOpAlpha", Int) = 0
        _FurSrcBlendFA ("sSrcBlendRGB", Int) = 1
        _FurDstBlendFA ("sDstBlendRGB", Int) = 1
        _FurSrcBlendAlphaFA ("sSrcBlendAlpha", Int) = 0
        _FurDstBlendAlphaFA ("sDstBlendAlpha", Int) = 1
        _FurBlendOpFA ("sBlendOpRGB", Int) = 4
        _FurBlendOpAlphaFA ("sBlendOpAlpha", Int) = 4
        _FurZClip ("sZClip", Int) = 1
        _FurZWrite ("sZWrite", Int) = 0
        _FurZTest ("sZTest", Int) = 4
        _FurStencilRef ("Ref", Range(0,255)) = 0
        _FurStencilReadMask ("ReadMask", Range(0,255)) = 255
        _FurStencilWriteMask ("WriteMask", Range(0,255)) = 255
        _FurStencilComp ("Comp", Float) = 8
        _FurStencilPass ("Pass", Float) = 0
        _FurStencilFail ("Fail", Float) = 0
        _FurStencilZFail ("ZFail", Float) = 0
        _FurOffsetFactor ("sOffsetFactor", Float) = 0
        _FurOffsetUnits ("sOffsetUnits", Float) = 0
        _FurColorMask ("sColorMask", Int) = 15
        _FurAlphaToMask ("sAlphaToMask", Int) = 0
        // Emission
        _UseEmission ("sEmission", Int) = 0
        [HDR] _EmissionColor ("sColor", Color) = (1,1,1,1)
        _EmissionMap ("Texture", 2D) = "white" {}
        _EmissionMap_ScrollRotate ("sScrollRotates", Vector) = (0,0,0,0)
        _EmissionMainStrength ("sMainColorPower", Range(0, 1)) = 0
        [NoScaleOffset] _EmissionBlendMask ("Mask", 2D) = "white" {}
        _EmissionBlendMask_ScrollRotate ("sScrollRotates", Vector) = (0,0,0,0)
        _EmissionBlend ("Blend", Range(0, 1)) = 1
        _EmissionBlendMode ("sBlendModes", Int) = 1
        _EmissionMap_UVMode ("UV Mode", Int) = 0
        _EmissionBlink ("sBlinkSettings", Vector) = (0,0,3.141593,0)
        _EmissionUseGrad ("sGradation", Int) = 0
        [NoScaleOffset] _EmissionGradTex ("Gradation Texture", 2D) = "white" {}
        _EmissionGradSpeed ("Gradation Speed", Float) = 1
        _EmissionParallaxDepth ("sParallaxDepth", Float) = 0
        _EmissionFluorescence ("sFluorescence", Range(0, 1)) = 0
        _UseEmission2nd ("sEmission2nd", Int) = 0
        [HDR] _Emission2ndColor ("sColor", Color) = (1,1,1,1)
        _Emission2ndMap ("Texture", 2D) = "white" {}
        _Emission2ndMap_ScrollRotate ("sScrollRotates", Vector) = (0,0,0,0)
        _Emission2ndMainStrength ("sMainColorPower", Range(0, 1)) = 0
        [NoScaleOffset] _Emission2ndBlendMask ("Mask", 2D) = "white" {}
        _Emission2ndBlendMask_ScrollRotate ("sScrollRotates", Vector) = (0,0,0,0)
        _Emission2ndBlend ("Blend", Range(0, 1)) = 1
        _Emission2ndBlendMode ("sBlendModes", Int) = 1
        _Emission2ndMap_UVMode ("UV Mode", Int) = 0
        _Emission2ndBlink ("sBlinkSettings", Vector) = (0,0,3.141593,0)
        _Emission2ndUseGrad ("sGradation", Int) = 0
        [NoScaleOffset] _Emission2ndGradTex ("Gradation Texture", 2D) = "white" {}
        _Emission2ndGradSpeed ("Gradation Speed", Float) = 1
        _Emission2ndParallaxDepth ("sParallaxDepth", Float) = 0
        _Emission2ndFluorescence ("sFluorescence", Range(0, 1)) = 0

        // Outline
        [HDR] _OutlineColor ("sColor", Color) = (0.6,0.56,0.73,1)
        _OutlineTex ("Texture", 2D) = "white" {}
        _OutlineTex_ScrollRotate ("sScrollRotates", Vector) = (0,0,0,0)
        _OutlineTexHSVG ("sHSVGs", Vector) = (0,1,1,1)
        [HDR] _OutlineLitColor ("sColor", Color) = (1,0.2,0,0)
        _OutlineLitApplyTex ("sColorFromMain", Int) = 0
        _OutlineLitScale ("Scale", Float) = 10
        _OutlineLitOffset ("Offset", Float) = -8
        _OutlineLitShadowReceive ("sReceiveShadow", Int) = 0
        _OutlineWidth ("Width", Range(0,1)) = 0.08
        [NoScaleOffset] _OutlineWidthMask ("Width", 2D) = "white" {}
        _OutlineFixWidth ("sFixWidth", Range(0,1)) = 0.5
        _OutlineVertexR2Width ("sOutlineVertexColorUsages", Int) = 0
        _OutlineDeleteMesh ("sDeleteMesh0", Int) = 0
        [NoScaleOffset][Normal] _OutlineVectorTex ("Vector", 2D) = "bump" {}
        _OutlineVectorUVMode ("UV Mode", Int) = 0
        _OutlineVectorScale ("Vector scale", Range(-10,10)) = 1
        _OutlineEnableLighting ("sEnableLighting", Range(0, 1)) = 1
        _OutlineZBias ("Z Bias", Float) = 0
        _OutlineDisableInVR ("sDisableInVR", Int) = 0
        _UseOutline ("Use Outline", Int) = 0

        // Outline Advanced
        _OutlineCull ("sCullModes", Int) = 1
        _OutlineSrcBlend ("sSrcBlendRGB", Int) = 5
        _OutlineDstBlend ("sDstBlendRGB", Int) = 10
        _OutlineSrcBlendAlpha ("sSrcBlendAlpha", Int) = 1
        _OutlineDstBlendAlpha ("sDstBlendAlpha", Int) = 10
        _OutlineBlendOp ("sBlendOpRGB", Int) = 0
        _OutlineBlendOpAlpha ("sBlendOpAlpha", Int) = 0
        _OutlineSrcBlendFA ("sSrcBlendRGB", Int) = 1
        _OutlineDstBlendFA ("sDstBlendRGB", Int) = 1
        _OutlineSrcBlendAlphaFA ("sSrcBlendAlpha", Int) = 0
        _OutlineDstBlendAlphaFA ("sDstBlendAlpha", Int) = 1
        _OutlineBlendOpFA ("sBlendOpRGB", Int) = 4
        _OutlineBlendOpAlphaFA ("sBlendOpAlpha", Int) = 4
        _OutlineZClip ("sZClip", Int) = 1
        _OutlineZWrite ("sZWrite", Int) = 1
        _OutlineZTest ("sZTest", Int) = 2
        _OutlineStencilRef ("Ref", Range(0, 255)) = 0
        _OutlineStencilReadMask ("ReadMask", Range(0, 255)) = 255
        _OutlineStencilWriteMask ("WriteMask", Range(0, 255)) = 255
        _OutlineStencilComp ("Comp", Float) = 8
        _OutlineStencilPass ("Pass", Float) = 0
        _OutlineStencilFail ("Fail", Float) = 0
        _OutlineStencilZFail ("ZFail", Float) = 0
        _OutlineOffsetFactor ("sOffsetFactor", Float) = 0
        _OutlineOffsetUnits ("sOffsetUnits", Float) = 0
        _OutlineColorMask ("sColorMask", Int) = 15
        _OutlineAlphaToMask ("sAlphaToMask", Int) = 0
        // Distance Fade
        [HDR] _DistanceFadeColor ("sColor", Color) = (0,0,0,1)
        _DistanceFade ("sDistanceFadeSettings", Vector) = (0.1,0.01,0,0)
        _DistanceFadeMode ("sDistanceFadeModes", Int) = 0
        [HDR] _DistanceFadeRimColor ("sColor", Color) = (0,0,0,0)
        _DistanceFadeRimFresnelPower ("sFresnelPower", Range(0.01, 50)) = 5

        // Rendering
        _Cull ("sCullModes", Int) = 2
        _SrcBlend ("sSrcBlendRGB", Int) = 1
        _DstBlend ("sDstBlendRGB", Int) = 10
        _SrcBlendAlpha ("sSrcBlendAlpha", Int) = 1
        _DstBlendAlpha ("sDstBlendAlpha", Int) = 10
        _BlendOp ("sBlendOpRGB", Int) = 0
        _BlendOpAlpha ("sBlendOpAlpha", Int) = 0
        _SrcBlendFA ("sSrcBlendRGB", Int) = 1
        _DstBlendFA ("sDstBlendRGB", Int) = 1
        _SrcBlendAlphaFA ("sSrcBlendAlpha", Int) = 0
        _DstBlendAlphaFA ("sDstBlendAlpha", Int) = 1
        _BlendOpFA ("sBlendOpRGB", Int) = 4
        _BlendOpAlphaFA ("sBlendOpAlpha", Int) = 4
        _ZClip ("sZClip", Int) = 1
        _ZWrite ("sZWrite", Int) = 1
        _ZTest ("sZTest", Int) = 4
        _StencilRef ("Ref", Range(0, 255)) = 0
        _StencilReadMask ("ReadMask", Range(0, 255)) = 255
        _StencilWriteMask ("WriteMask", Range(0, 255)) = 255
        _StencilComp ("Comp", Float) = 8
        _StencilPass ("Pass", Float) = 0
        _StencilFail ("Fail", Float) = 0
        _StencilZFail ("ZFail", Float) = 0
        _OffsetFactor ("sOffsetFactor", Float) = 0
        _OffsetUnits ("sOffsetUnits", Float) = 0
        _ColorMask ("sColorMask", Int) = 15
        _AlphaToMask ("sAlphaToMask", Int) = 0
        [HDR] _PreColor ("Pre Color", Color) = (1,1,1,1)
        _PreOutType ("Pre Out Type", Int) = 0
        _PreCutoff ("Pre Cutoff", Range(-0.001, 1.001)) = 0.001
        _PreCull ("Pre Cull Mode", Int) = 1
        _PreSrcBlend ("Pre Src Blend RGB", Int) = 1
        _PreDstBlend ("Pre Dst Blend RGB", Int) = 10
        _PreSrcBlendAlpha ("Pre Src Blend Alpha", Int) = 1
        _PreDstBlendAlpha ("Pre Dst Blend Alpha", Int) = 10
        _PreBlendOp ("Pre BlendOp RGB", Int) = 0
        _PreBlendOpAlpha ("Pre BlendOp Alpha", Int) = 0
        _PreSrcBlendFA ("Pre Src Blend RGB FA", Int) = 1
        _PreDstBlendFA ("Pre Dst Blend RGB FA", Int) = 1
        _PreSrcBlendAlphaFA ("Pre Src Blend Alpha FA", Int) = 0
        _PreDstBlendAlphaFA ("Pre Dst Blend Alpha FA", Int) = 1
        _PreBlendOpFA ("Pre BlendOp RGB FA", Int) = 4
        _PreBlendOpAlphaFA ("Pre BlendOp Alpha FA", Int) = 4
        _PreZClip ("Pre ZClip", Int) = 1
        _PreZWrite ("Pre ZWrite", Int) = 1
        _PreZTest ("Pre ZTest", Int) = 4
        _PreStencilRef ("Pre Ref", Range(0, 255)) = 0
        _PreStencilReadMask ("Pre ReadMask", Range(0, 255)) = 255
        _PreStencilWriteMask ("Pre WriteMask", Range(0, 255)) = 255
        _PreStencilComp ("Pre Comp", Float) = 8
        _PreStencilPass ("Pre Pass", Float) = 0
        _PreStencilFail ("Pre Fail", Float) = 0
        _PreStencilZFail ("Pre ZFail", Float) = 0
        _PreOffsetFactor ("Pre Offset Factor", Float) = 0
        _PreOffsetUnits ("Pre Offset Units", Float) = 0
        _PreColorMask ("Pre ColorMask", Int) = 15
        _PreAlphaToMask ("Pre AlphaToMask", Int) = 0
        _lilShadowCasterBias ("Shadow Caster Bias", Float) = 0
    }

    SubShader
    {
        Tags { "RenderType" = "TransparentCutout" "Queue" = "AlphaTest+10" }
        LOD 300

        Pass
        {
            Name "FORWARD_FUR_PRE"
            Tags { "LightMode" = "ForwardBase" }
            Stencil
            {
                Ref [_FurStencilRef]
                ReadMask [_FurStencilReadMask]
                WriteMask [_FurStencilWriteMask]
                Comp [_FurStencilComp]
                Pass [_FurStencilPass]
                Fail [_FurStencilFail]
                ZFail [_FurStencilZFail]
            }
            Cull [_FurCull]
            ZWrite On
            ZClip [_FurZClip]
            ZTest [_FurZTest]
            Offset [_FurOffsetFactor], [_FurOffsetUnits]
            ColorMask [_FurColorMask]
            Blend One Zero, One OneMinusSrcAlpha
            BlendOp Add, Add
            AlphaToMask On
            CGPROGRAM
            #pragma target 4.0
            #pragma require geometry
            #pragma vertex vert
            #pragma geometry geom
            #pragma fragment frag
            #pragma multi_compile_fwdbase
            #pragma multi_compile_fog
            #pragma multi_compile_instancing
            #define LTSKKS_RENDER_TWOPASS_TRANSPARENT 1
            #define LTSKKS_TRANSPARENT_PRE 1
            #define LTSKKS_FUR_PRE 1
            #define LTSKKS_PASS_FORWARD 1
            #include "Includes/LTSKKSFur.cginc"
            ENDCG
        }
        Pass
        {
            Name "FORWARD_FUR"
            Tags { "LightMode" = "ForwardBase" }
            Stencil
            {
                Ref [_FurStencilRef]
                ReadMask [_FurStencilReadMask]
                WriteMask [_FurStencilWriteMask]
                Comp [_FurStencilComp]
                Pass [_FurStencilPass]
                Fail [_FurStencilFail]
                ZFail [_FurStencilZFail]
            }
            Cull [_FurCull]
            ZWrite [_FurZWrite]
            ZClip [_FurZClip]
            ZTest [_FurZTest]
            Offset [_FurOffsetFactor], [_FurOffsetUnits]
            ColorMask [_FurColorMask]
            Blend [_FurSrcBlend] [_FurDstBlend], [_FurSrcBlendAlpha] [_FurDstBlendAlpha]
            BlendOp [_FurBlendOp], [_FurBlendOpAlpha]
            AlphaToMask [_FurAlphaToMask]
            CGPROGRAM
            #pragma target 4.0
            #pragma require geometry
            #pragma vertex vert
            #pragma geometry geom
            #pragma fragment frag
            #pragma multi_compile_fwdbase
            #pragma multi_compile_fog
            #pragma multi_compile_instancing
            #define LTSKKS_RENDER_TWOPASS_TRANSPARENT 1
            #define LTSKKS_PASS_FORWARD 1
            #include "Includes/LTSKKSFur.cginc"
            ENDCG
        }
        Pass
        {
            Name "FORWARD_ADD_FUR_PRE"
            Tags { "LightMode" = "ForwardAdd" }
            Stencil
            {
                Ref [_FurStencilRef]
                ReadMask [_FurStencilReadMask]
                WriteMask [_FurStencilWriteMask]
                Comp [_FurStencilComp]
                Pass [_FurStencilPass]
                Fail [_FurStencilFail]
                ZFail [_FurStencilZFail]
            }
            Cull [_FurCull]
            ZWrite Off
            ZClip [_FurZClip]
            ZTest LEqual
            Offset [_FurOffsetFactor], [_FurOffsetUnits]
            ColorMask [_FurColorMask]
            Blend [_FurSrcBlendFA] [_FurDstBlendFA], Zero One
            BlendOp [_FurBlendOpFA], [_FurBlendOpAlphaFA]
            AlphaToMask On
            CGPROGRAM
            #pragma target 4.0
            #pragma require geometry
            #pragma vertex vert
            #pragma geometry geom
            #pragma fragment frag
            #pragma multi_compile_fwdadd_fullshadows
            #pragma multi_compile_fog
            #pragma multi_compile_instancing
            #define LTSKKS_RENDER_TWOPASS_TRANSPARENT 1
            #define LTSKKS_FUR_PRE 1
            #define LTSKKS_PASS_FORWARDADD 1
            #include "Includes/LTSKKSFur.cginc"
            ENDCG
        }
        Pass
        {
            Name "FORWARD_ADD_FUR"
            Tags { "LightMode" = "ForwardAdd" }
            Stencil
            {
                Ref [_FurStencilRef]
                ReadMask [_FurStencilReadMask]
                WriteMask [_FurStencilWriteMask]
                Comp [_FurStencilComp]
                Pass [_FurStencilPass]
                Fail [_FurStencilFail]
                ZFail [_FurStencilZFail]
            }
            Cull [_FurCull]
            ZWrite Off
            ZClip [_FurZClip]
            ZTest LEqual
            Offset [_FurOffsetFactor], [_FurOffsetUnits]
            ColorMask [_FurColorMask]
            Blend [_FurSrcBlendFA] [_FurDstBlendFA], [_FurSrcBlendAlphaFA] [_FurDstBlendAlphaFA]
            BlendOp [_FurBlendOpFA], [_FurBlendOpAlphaFA]
            AlphaToMask [_FurAlphaToMask]
            CGPROGRAM
            #pragma target 4.0
            #pragma require geometry
            #pragma vertex vert
            #pragma geometry geom
            #pragma fragment frag
            #pragma multi_compile_fwdadd_fullshadows
            #pragma multi_compile_fog
            #pragma multi_compile_instancing
            #define LTSKKS_RENDER_TWOPASS_TRANSPARENT 1
            #define LTSKKS_PASS_FORWARDADD 1
            #include "Includes/LTSKKSFur.cginc"
            ENDCG
        }
    }

    Fallback "Diffuse"
}
