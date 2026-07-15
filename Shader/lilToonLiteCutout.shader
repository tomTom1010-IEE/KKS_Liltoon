Shader "lilToonLiteCutout"
{
    Properties
    {
        // Base
        _Invisible ("Invisible", Int) = 0
        _AsUnlit ("As Unlit", Range(0,1)) = 0
        _Cutoff ("Cutoff", Range(-0.001,1.001)) = 0.5
        _SubpassCutoff ("Subpass Cutoff", Range(0,1)) = 0.5
        _FlipNormal ("Flip Backface Normal", Int) = 0
        _BackfaceForceShadow ("Backface Force Shadow", Range(0,1)) = 0
        _VertexLightStrength ("Vertex Light Strength", Range(0,1)) = 0
        _LightMinLimit ("Light Min Limit", Range(0,1)) = 0.05
        _LightMaxLimit ("Light Max Limit", Range(0,10)) = 1
        _BeforeExposureLimit ("Before Exposure Limit", Float) = 10000
        _MonochromeLighting ("Monochrome Lighting", Range(0,1)) = 0
        _AlphaBoostFA ("Alpha Boost FA", Range(1,100)) = 10
        _lilDirectionalLightStrength ("Directional Light Strength", Range(0,1)) = 1
        _AAStrength ("AA Strength", Range(0,1)) = 1

        // Main
        [HDR] [MainColor] _Color ("Color", Color) = (1,1,1,1)
        [MainTexture] _MainTex ("Main Texture", 2D) = "white" {}
        _MainTex_ScrollRotate ("Main Scroll Rotate", Vector) = (0,0,0,0)
        [NoScaleOffset] _TriMask ("Tri Mask (R:MatCap G:Rim B:Emission)", 2D) = "white" {}

        // Shadow
        _UseShadow ("Use Shadow", Int) = 0
        _ShadowBorder ("Shadow Border", Range(0,1)) = 0.5
        _ShadowBlur ("Shadow Blur", Range(0,1)) = 0.1
        [NoScaleOffset] _ShadowColorTex ("Shadow Color", 2D) = "black" {}
        _Shadow2ndBorder ("Shadow 2nd Border", Range(0,1)) = 0.5
        _Shadow2ndBlur ("Shadow 2nd Blur", Range(0,1)) = 0.3
        [NoScaleOffset] _Shadow2ndColorTex ("Shadow 2nd Color", 2D) = "black" {}
        _ShadowEnvStrength ("Shadow Environment Strength", Range(0,1)) = 0
        [HDR] _ShadowBorderColor ("Shadow Border Color", Color) = (1,0,0,1)
        _ShadowBorderRange ("Shadow Border Range", Range(0,1)) = 0

        // MatCap
        _UseMatCap ("Use MatCap", Int) = 0
        _MatCapTex ("MatCap", 2D) = "white" {}
        _MatCapBlendUV1 ("MatCap Blend UV1", Vector) = (0,0,0,0)
        _MatCapZRotCancel ("MatCap Z Rotation Cancel", Int) = 1
        _MatCapPerspective ("MatCap Perspective", Int) = 1
        _MatCapVRParallaxStrength ("MatCap Parallax Strength", Range(0,1)) = 1
        _MatCapMul ("MatCap Multiply", Int) = 0

        // Rim
        _UseRim ("Use Rim", Int) = 0
        [HDR] _RimColor ("Rim Color", Color) = (1,1,1,1)
        _RimBorder ("Rim Border", Range(0,1)) = 0.5
        _RimBlur ("Rim Blur", Range(0,1)) = 0.1
        _RimFresnelPower ("Rim Fresnel Power", Range(0.01,50)) = 3
        _RimShadowMask ("Rim Shadow Mask", Range(0,1)) = 0

        // Emission
        _UseEmission ("Use Emission", Int) = 0
        [HDR] _EmissionColor ("Emission Color", Color) = (1,1,1,1)
        _EmissionMap ("Emission Map", 2D) = "white" {}
        _EmissionMap_ScrollRotate ("Emission Scroll Rotate", Vector) = (0,0,0,0)
        _EmissionMap_UVMode ("Emission UV Mode", Int) = 0
        _EmissionBlink ("Emission Blink", Vector) = (0,0,3.141593,0)

        // Outline
        _UseOutline ("Use Outline", Int) = 0
        [HDR] _OutlineColor ("Outline Color", Color) = (0.8,0.85,0.9,1)
        _OutlineTex ("Outline Texture", 2D) = "white" {}
        _OutlineTex_ScrollRotate ("Outline Scroll Rotate", Vector) = (0,0,0,0)
        _OutlineWidth ("Outline Width", Range(0,1)) = 0.05
        [NoScaleOffset] _OutlineWidthMask ("Outline Width Mask", 2D) = "white" {}
        _OutlineFixWidth ("Outline Fix Width", Range(0,1)) = 1
        _OutlineVertexR2Width ("Outline Vertex R To Width", Int) = 0
        _OutlineDeleteMesh ("Outline Delete Mesh", Int) = 0
        _OutlineEnableLighting ("Outline Enable Lighting", Range(0,1)) = 1
        _OutlineZBias ("Outline Z Bias", Float) = 0
        _OutlineCull ("Outline Cull", Int) = 1
        _OutlineZWrite ("Outline ZWrite", Int) = 1
        _OutlineZTest ("Outline ZTest", Int) = 2

        // Rendering
        _Cull ("Cull", Int) = 2
        _ZWrite ("ZWrite", Int) = 1
        _ZTest ("ZTest", Int) = 4
        _PreCull ("Pre Cull", Int) = 2
        _PreZWrite ("Pre ZWrite", Int) = 0
    }

    SubShader
    {
        Tags { "RenderType"="TransparentCutout" "Queue"="AlphaTest" }
        LOD 150
        Pass
        {
            Name "OUTLINE"
            Tags { "LightMode" = "ForwardBase" }
            Cull [_OutlineCull]
            ZWrite [_OutlineZWrite]
            ZTest [_OutlineZTest]
            Blend One Zero
            CGPROGRAM
            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase
            #pragma multi_compile_fog
            #pragma multi_compile_instancing
            #define LTSKKS_LITE_CUTOUT 1
            #include "Includes/LTSKKSLiteOutline.cginc"
            ENDCG
        }
        Pass
        {
            Name "FORWARD"
            Tags { "LightMode" = "ForwardBase" }
            Cull [_Cull]
            ZWrite [_ZWrite]
            ZTest [_ZTest]
            Blend One Zero
            CGPROGRAM
            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase
            #pragma multi_compile_fog
            #pragma multi_compile_instancing
            #define LTSKKS_LITE_CUTOUT 1
            
            #include "Includes/LTSKKSLiteForward.cginc"
            ENDCG
        }
        Pass
        {
            Name "FORWARD_ADD"
            Tags { "LightMode" = "ForwardAdd" }
            Cull [_Cull]
            ZWrite Off
            ZTest [_ZTest]
            Blend One One, Zero One
            CGPROGRAM
            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdadd_fullshadows
            #pragma multi_compile_fog
            #pragma multi_compile_instancing
            #define LTSKKS_LITE_CUTOUT 1
            #define LTSKKS_LITE_FORWARDADD 1
            #include "Includes/LTSKKSLiteForward.cginc"
            ENDCG
        }
        Pass
        {
            Name "SHADOW_CASTER"
            Tags { "LightMode" = "ShadowCaster" }
            Cull [_Cull]
            ZWrite On
            ZTest LEqual
            CGPROGRAM
            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_shadowcaster
            #pragma multi_compile_instancing
            #define LTSKKS_LITE_CUTOUT 1
            #include "Includes/LTSKKSLiteShadowCaster.cginc"
            ENDCG
        }
    }
    Fallback "Unlit/Texture"
}

