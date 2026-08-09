#ifndef LTSKKS_LIQUID_OVERLAY_INCLUDED
#define LTSKKS_LIQUID_OVERLAY_INCLUDED

#include "UnityCG.cginc"
#include "Lighting.cginc"
#include "AutoLight.cginc"
#include "UnityPBSLighting.cginc"
#include "LTSKKSCommon.cginc"
#include "LTSKKSInput.cginc"
#include "LTSKKSData.cginc"
#include "LTSKKSPipeline.cginc"
#include "LTSKKSLiquidCore.cginc"
#include "LTSKKSShadow.cginc"
#include "LTSKKSReflection.cginc"
#include "LTSKKSMatCap.cginc"
#include "LTSKKSRim.cginc"

sampler2D _Texture2;
sampler2D _Texture3;
sampler2D _liquidmask;
sampler2D _BaseNormalMap;

float4 _Texture2_ST;
float4 _Texture3_ST;
float4 _liquidmask_ST;
float4 _BaseNormalMap_ST;

float4 _LiquidTiling;
float _liquidftop;
float _liquidfbot;
float _liquidbtop;
float _liquidbbot;
float _liquidface;

float4 _LiquidColor;
float _LiquidOpacity;
float _LiquidNormalScale;
float _LiquidCutoff;

float _UseBaseNormalMap;
float _BaseNormalScale;
float _LTSKKSInternalSamplerKeepAlive;

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
    o.tangentWS = float4(
        UnityObjectToWorldDir(v.tangent.xyz),
        v.tangent.w * unity_WorldTransformParams.w);
    o.bitangentWS =
        cross(normalize(o.normalWS), normalize(o.tangentWS.xyz)) *
        o.tangentWS.w;
    o.uv01 = float4(v.texcoord.xy, v.texcoord1.xy);
    o.uv23 = float4(v.texcoord2.xy, v.texcoord3.xy);
    o.color = v.color;
    o.vertexLightColor = LTSKKS_GetVertexLightColor(o.posWS);

    TRANSFER_SHADOW(o);
    UNITY_TRANSFER_FOG(o, o.pos);
    return o;
}

LTSKKSLiquidSample LTSKKS_SampleLiquid(float2 uv)
{
    float2 liquidUV = uv * _LiquidTiling.zw + _LiquidTiling.xy;
    float4 liquidPattern = tex2D(_Texture2, LTSKKS_CalcUV(liquidUV, _Texture2_ST));
    float4 regionSample = tex2D(_liquidmask, LTSKKS_CalcUV(uv, _liquidmask_ST));
    float4 packedNormal = tex2D(_Texture3, LTSKKS_CalcUV(liquidUV, _Texture3_ST));

    return LTSKKS_EvaluateLiquidSample(
        liquidPattern,
        regionSample,
        packedNormal,
        _LiquidNormalScale,
        _liquidftop,
        _liquidfbot,
        _liquidbtop,
        _liquidbbot,
        _liquidface);
}

float3 LTSKKS_GetLiquidNormal(
    LTSKKSFragData fd,
    LTSKKSLiquidSample liquid,
    out float3 normalTS)
{
    normalTS = float3(0.0, 0.0, 1.0);

    if(_UseBaseNormalMap > 0.5)
    {
        float4 packedBaseNormal =
            tex2D(_BaseNormalMap, LTSKKS_CalcUV(fd.uvMain, _BaseNormalMap_ST));
        normalTS = LTSKKS_UnpackNormalScale(packedBaseNormal, _BaseNormalScale);
    }

    float3 maskedLiquidNormal = normalize(lerp(
        float3(0.0, 0.0, 1.0),
        liquid.normalTS,
        liquid.mask));
    normalTS = LTSKKS_BlendNormal(normalTS, maskedLiquidNormal);
    float3x3 tbn = float3x3(fd.T, fd.B, fd.origN);
    float3 normalWS = normalize(mul(normalTS, tbn));
    return (fd.facing < (_FlipNormal - 1.0)) ? -normalWS : normalWS;
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
    fd.uvMain = fd.uv0;
    fd.uvMat = fd.uv0;
    fd.ddxMain = abs(ddx(fd.uvMain));
    fd.ddyMain = abs(ddy(fd.uvMain));
    fd.posWS = i.posWS;
    fd.depth = length(_WorldSpaceCameraPos.xyz - i.posWS);
    fd.facing = facing;

    LTSKKS_PrepareSurfaceBasis(fd, i);

    LTSKKSLiquidSample liquid = LTSKKS_SampleLiquid(fd.uv0);
    clip(liquid.mask - max(_LiquidCutoff, 0.000001));

    // Keep the shared _MainTex sampler bound for the main-series mask modules.
    float internalMainAlpha = LTSKKS_SAMPLE_MAIN_TEX(fd.uvMain).a;
    float coverage = saturate(
        liquid.mask *
        _LiquidColor.a *
        _LiquidOpacity *
        lerp(
            1.0,
            internalMainAlpha,
            saturate(_LTSKKSInternalSamplerKeepAlive)));

    float3 normalTS;
    fd.N = LTSKKS_GetLiquidNormal(fd, liquid, normalTS);
    fd.reflectionN = fd.N;
    fd.matcapN = fd.N;
    fd.matcap2ndN = fd.N;
    fd.uvMat = LTSKKS_MatCapUV(fd.N).xy;

    LTSKKS_PrepareLighting(fd, i);

    fd.col = float4(_LiquidColor.rgb, coverage);
    fd.albedo = fd.col.rgb;

    LTSKKS_ApplyShadow(fd);
    LTSKKS_ApplyRimShade(fd);
    LTSKKS_ApplyReflection(fd);
    LTSKKS_ApplyMatCap(fd);
    LTSKKS_ApplyRim(fd);

    fd.col.rgb = min(fd.col.rgb, _BeforeExposureLimit.xxx);

    #if defined(LTSKKS_PASS_FORWARDADD)
        fd.col.rgb *= coverage;
        fd.col.a = 0.0;
        UNITY_APPLY_FOG_COLOR(
            i.fogCoord,
            fd.col,
            float4(0.0, 0.0, 0.0, 0.0));
    #else
        UNITY_APPLY_FOG(i.fogCoord, fd.col);
    #endif
    return fd.col;
}

#endif
