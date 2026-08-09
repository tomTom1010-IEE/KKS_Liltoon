#ifndef LTSKKS_KKS_LIQUID_INCLUDED
#define LTSKKS_KKS_LIQUID_INCLUDED

#if defined(LTSKKS_KKS_SKIN)

#include "LTSKKSLiquidCore.cginc"

void LTSKKS_GetKKSLiquid(float2 uv, out float mask, out float3 normalTS)
{
    float2 liquidUV = uv * _LiquidUVTransform.zw + _LiquidUVTransform.xy;
    float2 gameNormalUV = LTSKKS_CalcUV(liquidUV, _Texture3_ST);
    float2 gamePatternUV = LTSKKS_CalcUV(liquidUV, _Texture2_ST);
    float2 customNormalUV = LTSKKS_CalcUV(liquidUV, _LiquidNormalMap_ST);
    float2 customPatternUV = LTSKKS_CalcUV(liquidUV, _LiquidPatternTex_ST);
    float useCustomTextures = saturate(_UseLiquidCustomTextures);

    float4 gamePattern = UNITY_SAMPLE_TEX2D(_Texture2, gamePatternUV);
    float4 customPattern = UNITY_SAMPLE_TEX2D_SAMPLER(_LiquidPatternTex, _Texture2, customPatternUV);
    float4 liquidPattern = lerp(gamePattern, customPattern, useCustomTextures);

    float2 regionUV = LTSKKS_CalcUV(uv, _liquidmask_ST);
    float4 regionSample = UNITY_SAMPLE_TEX2D_SAMPLER(_liquidmask, _Texture2, regionUV);

    float4 gameNormal = UNITY_SAMPLE_TEX2D_SAMPLER(_Texture3, _Texture2, gameNormalUV);
    float4 customNormal = UNITY_SAMPLE_TEX2D_SAMPLER(_LiquidNormalMap, _Texture2, customNormalUV);
    float4 packedNormal = lerp(gameNormal, customNormal, useCustomTextures);
    LTSKKSLiquidSample liquid = LTSKKS_EvaluateLiquidSample(
        liquidPattern,
        regionSample,
        packedNormal,
        _LiquidNormalScale,
        _liquidftop,
        _liquidfbot,
        _liquidbtop,
        _liquidbbot,
        _liquidface);
    mask = liquid.mask;
    normalTS = liquid.normalTS;
}

void LTSKKS_ApplyKKSLiquidColor(inout LTSKKSFragData fd)
{
    float liquidAlpha = saturate(fd.liquidMask * _LiquidColor.a);
    fd.col.rgb = lerp(fd.col.rgb, _LiquidColor.rgb, liquidAlpha);
}

#endif

#endif
