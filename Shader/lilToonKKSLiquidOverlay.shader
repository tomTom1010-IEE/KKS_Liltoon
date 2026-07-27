Shader "lilToonKKSLiquidOverlay"
{
    Properties
    {
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
        _LiquidSmoothness ("Liquid Smoothness", Range(0,1)) = 0.9
        [Gamma] _LiquidReflectance ("Liquid Reflectance", Range(0,1)) = 0.04
        _LiquidSpecularStrength ("Liquid Specular Strength", Range(0,4)) = 1
        _LiquidReflectionStrength ("Liquid Reflection Strength", Range(0,4)) = 0.35
        _LiquidFresnelStrength ("Liquid Fresnel Strength", Range(0,1)) = 1
        _LiquidFresnelPower ("Liquid Fresnel Power", Range(0.01,20)) = 5
        _LiquidReceiveShadow ("Liquid Receive Shadow", Range(0,1)) = 1
        _LiquidEnableLighting ("Liquid Enable Lighting", Range(0,1)) = 1
        _LiquidCutoff ("Liquid Mask Cutoff", Range(0,1)) = 0.001
        _LiquidApplySpecularFA ("Liquid Multi Light Specular", Range(0,1)) = 1

        // Optional Base Normal
        _UseBaseNormalMap ("Use Base Normal Map", Range(0,1)) = 0
        [Normal] _BaseNormalMap ("Base Normal Map", 2D) = "bump" {}
        _BaseNormalScale ("Base Normal Scale", Range(-10,10)) = 1

        // Environment Reflection
        [NoScaleOffset] _LiquidReflectionCubeTex ("Liquid Reflection Fallback", Cube) = "black" {}
        [HDR] _LiquidReflectionCubeColor ("Liquid Reflection Fallback Color", Color) = (0,0,0,1)
        _LiquidReflectionCubeOverride ("Override Reflection Probe", Range(0,1)) = 0
        _LiquidReflectionCubeEnableLighting ("Fallback Enable Lighting", Range(0,1)) = 1

        // OpenLit
        _AsUnlit ("As Unlit", Range(0,1)) = 0
        _VertexLightStrength ("Vertex Light Strength", Range(0,1)) = 0
        _LightMinLimit ("Light Min Limit", Range(0,1)) = 0.05
        _LightMaxLimit ("Light Max Limit", Range(0,10)) = 1
        _MonochromeLighting ("Monochrome Lighting", Range(0,1)) = 0
        _lilDirectionalLightStrength ("Directional Light Strength", Range(0,1)) = 1
        _LightDirectionOverride ("Light Direction Override", Vector) = (0.001,0.002,0.001,0)
        _BeforeExposureLimit ("Before Exposure Limit", Float) = 10000

        // Overlay Rendering
        [Enum(UnityEngine.Rendering.CullMode)] _Cull ("Cull", Float) = 0
        _OffsetFactor ("Offset Factor", Float) = -1
        _OffsetUnits ("Offset Units", Float) = -1
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
            ZWrite Off
            ZTest LEqual
            Offset [_OffsetFactor], [_OffsetUnits]
            Blend One OneMinusSrcAlpha, One OneMinusSrcAlpha

            CGPROGRAM
            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase
            #pragma multi_compile_fog
            #pragma multi_compile_instancing
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
            Offset [_OffsetFactor], [_OffsetUnits]
            Blend One One, Zero One
            Fog { Color (0,0,0,0) }

            CGPROGRAM
            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdadd_fullshadows
            #pragma multi_compile_fog
            #pragma multi_compile_instancing
            #define LTSKKS_LIQUID_FORWARDADD 1
            #include "Includes/LTSKKSLiquidOverlay.cginc"
            ENDCG
        }
    }

    Fallback Off
}
