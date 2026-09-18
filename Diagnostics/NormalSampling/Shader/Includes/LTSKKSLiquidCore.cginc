#ifndef LTSKKS_LIQUID_CORE_INCLUDED
#define LTSKKS_LIQUID_CORE_INCLUDED

struct LTSKKSLiquidSample
{
    float mask;
    float3 normalTS;
};

LTSKKSLiquidSample LTSKKS_EvaluateLiquidSample(
    float4 liquidPattern,
    float4 regionSample,
    float4 packedNormal,
    float normalScale,
    float liquidFrontTopControl,
    float liquidFrontBottomControl,
    float liquidBackTopControl,
    float liquidBackBottomControl,
    float liquidFaceControl)
{
    LTSKKSLiquidSample liquid;

    float liquidFrontTop = max(
        saturate(liquidFrontTopControl - 1.0) * liquidPattern.g,
        saturate(liquidFrontTopControl) * liquidPattern.r);

    float3 exclusiveRegions = max(regionSample.bbg, regionSample.grr);
    exclusiveRegions = regionSample.rgb - exclusiveRegions;

    float2 overlapRegions = min(regionSample.gb, regionSample.rg);
    overlapRegions = overlapRegions * 1.11111104 - 0.111111097;
    liquidFrontTop = min(liquidFrontTop, exclusiveRegions.r);

    float4 controls = float4(
        liquidFrontBottomControl,
        liquidBackTopControl,
        liquidBackBottomControl,
        liquidFaceControl);
    float4 liquidUpperBand = saturate(controls - 1.0) * liquidPattern.g;
    float4 liquidLowerBand = saturate(controls) * liquidPattern.r;
    float4 liquidAmounts = max(liquidUpperBand, liquidLowerBand);

    float2 backAndFrontBottom = min(exclusiveRegions.gb, liquidAmounts.xy);
    float2 bottomAndFace = min(overlapRegions, liquidAmounts.zw);

    liquid.mask = max(liquidFrontTop, backAndFrontBottom.x);
    liquid.mask = max(liquid.mask, backAndFrontBottom.y);
    liquid.mask = max(liquid.mask, bottomAndFace.x);
    liquid.mask = saturate(max(liquid.mask, bottomAndFace.y));
    liquid.normalTS = LTSKKS_UnpackNormalScale(packedNormal, normalScale);
    return liquid;
}

#endif
