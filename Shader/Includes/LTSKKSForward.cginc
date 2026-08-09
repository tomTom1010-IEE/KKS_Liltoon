#ifndef LTSKKS_FORWARD_INCLUDED
#define LTSKKS_FORWARD_INCLUDED

#include "UnityCG.cginc"
#include "Lighting.cginc"
#include "AutoLight.cginc"
#include "UnityPBSLighting.cginc"
#include "LTSKKSCommon.cginc"
#include "LTSKKSInput.cginc"
#include "LTSKKSData.cginc"
#define LTSKKS_DISSOLVE_WITH_FRAGDATA 1
#include "LTSKKSDissolve.cginc"
#include "LTSKKSPipeline.cginc"
#define LTSKKS_PARALLAX_WITH_FRAGDATA 1
#include "LTSKKSParallax.cginc"
#if defined(LTSKKS_KKS_SKIN)
    #include "LTSKKSKKSSkin.cginc"
#endif
#include "LTSKKSMain.cginc"
#define LTSKKS_ALPHA_WITH_FRAGDATA 1
#include "LTSKKSAlpha.cginc"
#include "LTSKKSNormal.cginc"
#include "LTSKKSAnisotropy.cginc"
#include "LTSKKSShadow.cginc"
#include "LTSKKSReflection.cginc"
#include "LTSKKSMatCap.cginc"
#include "LTSKKSRim.cginc"
#include "LTSKKSGlitter.cginc"
#include "LTSKKSEmission.cginc"
#include "LTSKKSRefraction.cginc"
#include "LTSKKSGem.cginc"

LTSKKSV2F vert(LTSKKSAppData v)
{
    LTSKKSV2F o;
    UNITY_SETUP_INSTANCE_ID(v);
    UNITY_INITIALIZE_OUTPUT(LTSKKSV2F, o);
    UNITY_TRANSFER_INSTANCE_ID(v, o);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

    o.pos = UnityObjectToClipPos(v.vertex);
    o.posWS = mul(unity_ObjectToWorld, v.vertex).xyz;
    o.normalWS = UnityObjectToWorldNormal(v.normal);
    o.tangentWS = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w * unity_WorldTransformParams.w);
    o.bitangentWS = cross(normalize(o.normalWS), normalize(o.tangentWS.xyz)) * o.tangentWS.w;
    o.uv01 = float4(v.texcoord.xy, v.texcoord1.xy);
    o.uv23 = float4(v.texcoord2.xy, v.texcoord3.xy);
    o.color = v.color;
    #if defined(LTSKKS_PASS_FUR)
        o.furLayer = -2.0;
    #elif defined(LTSKKS_REFRACTION) || defined(LTSKKS_GEM)
        o.grabPos = ComputeGrabScreenPos(o.pos);
    #endif
    o.vertexLightColor = LTSKKS_GetVertexLightColor(o.posWS);
    TRANSFER_SHADOW(o);
    UNITY_TRANSFER_FOG(o, o.pos);
    return o;
}

float4 frag(LTSKKSV2F i, fixed facing : VFACE) : SV_Target
{
    UNITY_SETUP_INSTANCE_ID(i);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

    LTSKKSFragData fd = LTSKKS_InitFragData();
    fd.uv0 = i.uv01.xy;
    fd.uv1 = i.uv01.zw;
    fd.uv2 = i.uv23.xy;
    fd.uv3 = i.uv23.zw;
    fd.posWS = i.posWS;
    fd.depth = length(_WorldSpaceCameraPos.xyz - i.posWS);
    fd.facing = facing;
    #if defined(LTSKKS_KKS_SKIN)
        fd.vertexColor = i.color;
    #endif

    if(_Invisible > 0.5) discard;

    #if defined(LTSKKS_GEM) && defined(LTSKKS_PASS_FORWARDADD)
        return 0.0;
    #endif

    LTSKKS_PrepareSurfaceBasis(fd, i);
    LTSKKS_ApplyMain(fd);
    LTSKKS_ApplyNormal(fd, i);
    #if defined(LTSKKS_GEM)
        LTSKKS_PrepareGemNormal(fd);
    #endif
    LTSKKS_PrepareLighting(fd, i);
    LTSKKS_ApplyAnisotropy(fd);
    LTSKKS_ApplyMainLayers(fd);
    #if defined(LTSKKS_KKS_SKIN)
        LTSKKS_ApplyKKSLiquidColor(fd);
    #endif
    LTSKKS_ApplyRenderAlpha(fd, i.pos);

    #if defined(LTSKKS_KKS_HAIR_FRONT_EYE)
        fd.col.a *= saturate(_KKSFrontHairOpacity);
    #endif

    #if defined(LTSKKS_TRANSPARENT_PRE)
        if(_PreOutType > 0.5)
        {
            return LTSKKS_PremultiplyTransparentColor((_PreOutType > 1.5) ? _PreColor : fd.col);
        }
    #endif

    #if defined(LTSKKS_GEM)
        LTSKKS_ApplyMainLayersAfterLighting(fd);
        fd.albedo = fd.col.rgb;
        LTSKKS_ApplyGem(fd, i.grabPos);
    #else
        fd.albedo = fd.col.rgb;
        LTSKKS_ApplyShadow(fd);
        LTSKKS_ApplyMainLayersAfterLighting(fd);
        LTSKKS_ApplyRimShade(fd);
        #if !defined(LTSKKS_PASS_FORWARDADD)
            LTSKKS_ApplyBacklight(fd);
        #endif
        #if defined(LTSKKS_REFRACTION) && !defined(LTSKKS_PASS_FORWARDADD)
            LTSKKS_ApplyRefraction(fd, i.grabPos);
        #endif
        LTSKKS_ApplyReflection(fd);
    #endif
    LTSKKS_ApplyMatCap(fd);
    LTSKKS_ApplyRim(fd);
    LTSKKS_ApplyGlitter(fd);
    #if !defined(LTSKKS_PASS_FORWARDADD)
        LTSKKS_ApplyEmission(fd);
    #endif
    LTSKKS_ApplyDissolveEmission(fd);

    #if !defined(LTSKKS_GEM)
        fd.col.rgb = (fd.facing < 0.0) ? lerp(fd.col.rgb, _BackfaceColor.rgb * fd.lightColor, _BackfaceColor.a) : fd.col.rgb;
    #endif
    fd.col.rgb = min(fd.col.rgb, float3(_BeforeExposureLimit, _BeforeExposureLimit, _BeforeExposureLimit));
    fd.col = LTSKKS_PremultiplyTransparentColor(fd.col);
    #if defined(LTSKKS_GEM)
        UNITY_APPLY_FOG_COLOR(i.fogCoord, fd.col, float4(0.0, 0.0, 0.0, 0.0));
    #else
        UNITY_APPLY_FOG(i.fogCoord, fd.col);
    #endif
    return fd.col;
}

#endif
