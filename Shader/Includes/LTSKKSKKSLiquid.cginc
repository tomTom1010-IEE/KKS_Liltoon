#ifndef LTSKKS_KKS_LIQUID_INCLUDED
#define LTSKKS_KKS_LIQUID_INCLUDED

#if defined(LTSKKS_KKS_SKIN)

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

    float liquidFrontTop = max(
        saturate(_liquidftop - 1.0) * liquidPattern.g,
        saturate(_liquidftop) * liquidPattern.r);

    float2 regionUV = LTSKKS_CalcUV(uv, _liquidmask_ST);
    float4 regionSample = UNITY_SAMPLE_TEX2D_SAMPLER(_liquidmask, _Texture2, regionUV);
    float3 exclusiveRegions = max(regionSample.bbg, regionSample.grr);
    exclusiveRegions = regionSample.rgb - exclusiveRegions;

    float2 overlapRegions = min(regionSample.gb, regionSample.rg);
    overlapRegions = overlapRegions * 1.11111104 - 0.111111097;
    liquidFrontTop = min(liquidFrontTop, exclusiveRegions.r);

    float4 controls = float4(_liquidfbot, _liquidbtop, _liquidbbot, _liquidface);
    float4 liquidUpperBand = saturate(controls - 1.0) * liquidPattern.g;
    float4 liquidLowerBand = saturate(controls) * liquidPattern.r;
    float4 liquidAmounts = max(liquidUpperBand, liquidLowerBand);

    float2 backAndFrontBottom = min(exclusiveRegions.gb, liquidAmounts.xy);
    float2 bottomAndFace = min(overlapRegions, liquidAmounts.zw);

    mask = max(liquidFrontTop, backAndFrontBottom.x);
    mask = max(mask, backAndFrontBottom.y);
    mask = max(mask, bottomAndFace.x);
    mask = saturate(max(mask, bottomAndFace.y));

    float4 gameNormal = UNITY_SAMPLE_TEX2D_SAMPLER(_Texture3, _Texture2, gameNormalUV);
    float4 customNormal = UNITY_SAMPLE_TEX2D_SAMPLER(_LiquidNormalMap, _Texture2, customNormalUV);
    float4 packedNormal = lerp(gameNormal, customNormal, useCustomTextures);
    normalTS = LTSKKS_UnpackNormalScale(packedNormal, _LiquidNormalScale);
}

void LTSKKS_ApplyKKSLiquidColor(inout LTSKKSFragData fd)
{
    float liquidAlpha = saturate(fd.liquidMask * _LiquidColor.a);
    fd.col.rgb = lerp(fd.col.rgb, _LiquidColor.rgb, liquidAlpha);
}

#endif

#endif
