Shader "lilToonKKSLiquidOverlay"
{
    Properties
    {
        [HideInInspector] _MainTex ("Internal Main Texture", 2D) = "white" {}
        [HideInInspector] _LTSKKSInternalSamplerKeepAlive ("Internal Sampler Keep Alive", Float) = 0

        // KKS Liquid
        _Texture2 ("KKS Liquid Pattern (R/G)", 2D) = "black" {}
        _Texture3 ("KKS Liquid Normal (Packed AG)", 2D) = "bump" {}
        _liquidmask ("KKS Liquid Region Mask", 2D) = "black" {}
        _LiquidTiling ("Liquid UV (Offset XY, Scale ZW)", Vector) = (0,0,2,2)
        _liquidftop ("Liquid Front Top", Range(0,2)) = 0
        _liquidfbot ("Liquid Front Bottom", Range(0,2)) = 0
        _liquidbtop ("Liquid Back Top", Range(0,2)) = 0
        _liquidbbot ("Liquid Back Bottom", Range(0,2)) = 0
        _liquidface ("Liquid Face", Range(0,2)) = 0

        // Liquid Appearance
        [HDR] _LiquidColor ("Liquid Color (RGBA)", Color) = (1,1,1,0.15)
        _LiquidOpacity ("Liquid Opacity", Range(0,1)) = 1
        _LiquidNormalScale ("Liquid Normal Scale", Range(0,2)) = 1
        _LiquidCutoff ("Liquid Mask Cutoff", Range(0,1)) = 0.001

        // Optional Base Normal
        _UseBaseNormalMap ("Use Base Normal Map", Range(0,1)) = 0
        [Normal] _BaseNormalMap ("Base Normal Map", 2D) = "bump" {}
        _BaseNormalScale ("Base Normal Scale", Range(-10,10)) = 1

        // Base / OpenLit
        _AsUnlit ("As Unlit", Range(0,1)) = 0
        _FlipNormal ("Flip Backface Normal", Range(0,1)) = 1
        _BackfaceForceShadow ("Backface Force Shadow", Range(0,1)) = 0
        _VertexLightStrength ("Vertex Light Strength", Range(0,1)) = 0
        _LightMinLimit ("Light Min Limit", Range(0,1)) = 0.05
        _LightMaxLimit ("Light Max Limit", Range(0,10)) = 1
        _MonochromeLighting ("Monochrome Lighting", Range(0,1)) = 0
        _lilDirectionalLightStrength ("Directional Light Strength", Range(0,1)) = 1
        _LightDirectionOverride ("Light Direction Override", Vector) = (0.001,0.002,0.001,0)
        _BeforeExposureLimit ("Before Exposure Limit", Float) = 10000
        _AAStrength ("AA Strength", Range(0,1)) = 1

        // Shadow
        _UseShadow ("Shadow", Int) = 1
        _ShadowStrength ("Strength", Range(0,1)) = 1
        [NoScaleOffset] _ShadowStrengthMask ("Strength Mask", 2D) = "white" {}
        _ShadowStrengthMaskLOD ("Strength Mask LOD", Range(0,1)) = 0
        [NoScaleOffset] _ShadowBorderMask ("Border Mask", 2D) = "white" {}
        _ShadowBorderMaskLOD ("Border Mask LOD", Range(0,1)) = 0
        [NoScaleOffset] _ShadowBlurMask ("Blur Mask", 2D) = "white" {}
        _ShadowBlurMaskLOD ("Blur Mask LOD", Range(0,1)) = 0
        _ShadowAOShift ("AO Shift", Vector) = (1,0,1,0)
        _ShadowAOShift2 ("AO Shift 2", Vector) = (1,0,1,0)
        _ShadowPostAO ("Post AO", Int) = 0
        _ShadowColorType ("Shadow Color Type", Int) = 0
        _ShadowColor ("Shadow Color", Color) = (0.82,0.76,0.85,1)
        [NoScaleOffset] _ShadowColorTex ("Shadow Color Texture", 2D) = "black" {}
        _ShadowNormalStrength ("Normal Strength", Range(0,1)) = 1
        _ShadowBorder ("Border", Range(0,1)) = 0.5
        _ShadowBlur ("Blur", Range(0,1)) = 0.1
        _ShadowReceive ("Receive Shadow", Range(0,1)) = 1
        _Shadow2ndColor ("2nd Color", Color) = (0.68,0.66,0.79,1)
        [NoScaleOffset] _Shadow2ndColorTex ("2nd Color Texture", 2D) = "black" {}
        _Shadow2ndNormalStrength ("2nd Normal Strength", Range(0,1)) = 1
        _Shadow2ndBorder ("2nd Border", Range(0,1)) = 0.15
        _Shadow2ndBlur ("2nd Blur", Range(0,1)) = 0.1
        _Shadow2ndReceive ("2nd Receive Shadow", Range(0,1)) = 1
        _Shadow3rdColor ("3rd Color", Color) = (0,0,0,0)
        [NoScaleOffset] _Shadow3rdColorTex ("3rd Color Texture", 2D) = "black" {}
        _Shadow3rdNormalStrength ("3rd Normal Strength", Range(0,1)) = 1
        _Shadow3rdBorder ("3rd Border", Range(0,1)) = 0.25
        _Shadow3rdBlur ("3rd Blur", Range(0,1)) = 0.1
        _Shadow3rdReceive ("3rd Receive Shadow", Range(0,1)) = 1
        _ShadowBorderColor ("Border Color", Color) = (1,0.1,0,1)
        _ShadowBorderRange ("Border Range", Range(0,1)) = 0.08
        _ShadowMainStrength ("Main Color Power", Range(0,1)) = 0
        _ShadowEnvStrength ("Environment Strength", Range(0,1)) = 0
        _ShadowMaskType ("Mask Type", Int) = 0
        _ShadowFlatBorder ("Flat Border", Range(-2,2)) = 1
        _ShadowFlatBlur ("Flat Blur", Range(0.001,2)) = 1

        // Rim Shade
        _UseRimShade ("Rim Shade", Int) = 0
        _RimShadeColor ("Rim Shade Color", Color) = (0.5,0.5,0.5,1)
        [NoScaleOffset] _RimShadeMask ("Rim Shade Mask", 2D) = "white" {}
        _RimShadeNormalStrength ("Normal Strength", Range(0,1)) = 1
        _RimShadeBorder ("Border", Range(0,1)) = 0.5
        _RimShadeBlur ("Blur", Range(0,1)) = 1
        _RimShadeFresnelPower ("Fresnel Power", Range(0.01,50)) = 1

        // Reflection / Specular
        _UseReflection ("Reflection", Int) = 1
        _Smoothness ("Smoothness", Range(0,1)) = 0.9
        [NoScaleOffset] _SmoothnessTex ("Smoothness Texture", 2D) = "white" {}
        [Gamma] _Metallic ("Metallic", Range(0,1)) = 0
        [NoScaleOffset] _MetallicGlossMap ("Metallic Texture", 2D) = "white" {}
        [Gamma] _Reflectance ("Reflectance", Range(0,1)) = 0.04
        _GSAAStrength ("GSAA", Range(0,1)) = 0
        _ApplySpecular ("Apply Specular", Int) = 1
        _ApplySpecularFA ("Multi Light Specular", Int) = 1
        _SpecularToon ("Specular Toon", Int) = 0
        _SpecularNormalStrength ("Specular Normal Strength", Range(0,1)) = 1
        _SpecularBorder ("Specular Border", Range(0,1)) = 0.5
        _SpecularBlur ("Specular Blur", Range(0,1)) = 0
        _ApplyReflection ("Apply Environment Reflection", Int) = 1
        _ReflectionNormalStrength ("Reflection Normal Strength", Range(0,1)) = 1
        [HDR] _ReflectionColor ("Reflection Color", Color) = (1,1,1,1)
        [NoScaleOffset] _ReflectionColorTex ("Reflection Color Texture", 2D) = "white" {}
        _ReflectionApplyTransparency ("Apply Transparency", Int) = 1
        [NoScaleOffset] _ReflectionCubeTex ("Cubemap Fallback", Cube) = "black" {}
        [HDR] _ReflectionCubeColor ("Fallback Color", Color) = (0,0,0,1)
        _ReflectionCubeOverride ("Override Reflection Probe", Int) = 0
        _ReflectionCubeEnableLighting ("Fallback Enable Lighting", Range(0,1)) = 1
        _ReflectionBlendMode ("Blend Mode", Int) = 1

        // MatCap
        _UseMatCap ("MatCap", Int) = 0
        [HDR] _MatCapColor ("Color", Color) = (1,1,1,1)
        _MatCapTex ("Texture", 2D) = "white" {}
        [NoScaleOffset] _MatCapBlendMask ("Blend Mask", 2D) = "white" {}
        _MatCapBlend ("Blend", Range(0,1)) = 1
        _MatCapBlendMode ("Blend Mode", Int) = 1
        _MatCapEnableLighting ("Enable Lighting", Range(0,1)) = 1
        _MatCapShadowMask ("Shadow Mask", Range(0,1)) = 0
        _MatCapBackfaceMask ("Backface Mask", Int) = 1
        _MatCapLod ("Blur", Range(0,10)) = 0
        _MatCapApplyTransparency ("Apply Transparency", Int) = 1
        _MatCapNormalStrength ("Normal Strength", Range(0,1)) = 1
        _MatCapCustomNormal ("Custom Normal", Int) = 0
        _MatCapMainStrength ("Main Color Power", Range(0,1)) = 0
        _MatCapPerspective ("Perspective", Int) = 1
        _MatCapZRotCancel ("Z Rotation Cancellation", Int) = 1
        _MatCapVRParallaxStrength ("VR Parallax Strength", Range(0,1)) = 1
        [Normal] _MatCapBumpMap ("Normal Map", 2D) = "bump" {}
        _MatCapBumpScale ("Normal Scale", Range(-10,10)) = 1
        _MatCapBlendUV1 ("Blend UV1", Vector) = (0,0,0,0)

        // MatCap 2nd
        _UseMatCap2nd ("MatCap 2nd", Int) = 0
        [HDR] _MatCap2ndColor ("Color", Color) = (1,1,1,1)
        _MatCap2ndTex ("Texture", 2D) = "white" {}
        [NoScaleOffset] _MatCap2ndBlendMask ("Blend Mask", 2D) = "white" {}
        _MatCap2ndBlend ("Blend", Range(0,1)) = 1
        _MatCap2ndBlendMode ("Blend Mode", Int) = 1
        _MatCap2ndEnableLighting ("Enable Lighting", Range(0,1)) = 1
        _MatCap2ndShadowMask ("Shadow Mask", Range(0,1)) = 0
        _MatCap2ndBackfaceMask ("Backface Mask", Int) = 1
        _MatCap2ndLod ("Blur", Range(0,10)) = 0
        _MatCap2ndApplyTransparency ("Apply Transparency", Int) = 1
        _MatCap2ndNormalStrength ("Normal Strength", Range(0,1)) = 1
        _MatCap2ndCustomNormal ("Custom Normal", Int) = 0
        _MatCap2ndMainStrength ("Main Color Power", Range(0,1)) = 0
        _MatCap2ndPerspective ("Perspective", Int) = 1
        _MatCap2ndZRotCancel ("Z Rotation Cancellation", Int) = 1
        _MatCap2ndVRParallaxStrength ("VR Parallax Strength", Range(0,1)) = 1
        [Normal] _MatCap2ndBumpMap ("Normal Map", 2D) = "bump" {}
        _MatCap2ndBumpScale ("Normal Scale", Range(-10,10)) = 1
        _MatCap2ndBlendUV1 ("Blend UV1", Vector) = (0,0,0,0)

        // Rim
        _UseRim ("Rim", Int) = 0
        [HDR] _RimColor ("Color", Color) = (0.66,0.5,0.48,1)
        [NoScaleOffset] _RimColorTex ("Color Texture", 2D) = "white" {}
        _RimMainStrength ("Main Color Power", Range(0,1)) = 0
        _RimNormalStrength ("Normal Strength", Range(0,1)) = 1
        [HDR] _RimIndirColor ("Indirect Color", Color) = (1,1,1,1)
        _RimBorder ("Border", Range(0,1)) = 0.5
        _RimBlur ("Blur", Range(0,1)) = 0.65
        _RimFresnelPower ("Fresnel Power", Range(0.01,50)) = 3.5
        _RimShadowMask ("Shadow Mask", Range(0,1)) = 0.5
        _RimBackfaceMask ("Backface Mask", Int) = 1
        _RimVRParallaxStrength ("VR Parallax Strength", Range(0,1)) = 1
        _RimApplyTransparency ("Apply Transparency", Int) = 1
        _RimEnableLighting ("Enable Lighting", Range(0,1)) = 1
        _RimBlendMode ("Blend Mode", Int) = 1
        _RimDirStrength ("Direction Strength", Range(0,1)) = 0
        _RimDirRange ("Direction Range", Range(-1,1)) = 0
        _RimIndirRange ("Indirect Range", Range(-1,1)) = 0
        _RimIndirBorder ("Indirect Border", Range(0,1)) = 0.5
        _RimIndirBlur ("Indirect Blur", Range(0,1)) = 0.1

        // Overlay Rendering
        [Enum(UnityEngine.Rendering.CullMode)] _Cull ("Cull", Float) = 0
        _ZWrite ("ZWrite On", Range(0,1)) = 0
    }

    SubShader
    {
        Tags
        {
            "Queue" = "Transparent+50"
            "RenderType" = "Transparent"
            "IgnoreProjector" = "True"
        }
        LOD 300

        Pass
        {
            Name "FORWARD"
            Tags { "LightMode" = "ForwardBase" }

            Cull [_Cull]
            ZWrite [_ZWrite]
            ZTest LEqual
            Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha

            CGPROGRAM
            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase
            #pragma multi_compile_fog
            #pragma multi_compile_instancing
            #define LTSKKS_RENDER_TRANSPARENT 1
            #include "Includes/LTSKKSLiquidOverlay.cginc"
            ENDCG
        }

        Pass
        {
            Name "FORWARD_ADD"
            Tags { "LightMode" = "ForwardAdd" }

            Cull [_Cull]
            ZWrite Off
            ZTest LEqual
            Blend One One, Zero One
            Fog { Color (0,0,0,0) }

            CGPROGRAM
            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdadd_fullshadows
            #pragma multi_compile_fog
            #pragma multi_compile_instancing
            #define LTSKKS_RENDER_TRANSPARENT 1
            #define LTSKKS_PASS_FORWARDADD 1
            #include "Includes/LTSKKSLiquidOverlay.cginc"
            ENDCG
        }
    }

    Fallback Off
}
