#ifndef LTSKKS_ALPHA_INCLUDED
#define LTSKKS_ALPHA_INCLUDED

#include "LTSKKSDissolve.cginc"

#if defined(LTSKKS_KKS_SKIN)
    float LTSKKS_GetKKSSkinBodyMask(float2 uv)
    {
        float4 mask = UNITY_SAMPLE_TEX2D(_AlphaMask, LTSKKS_CalcUV(uv, _AlphaMask_ST));
        float maskR = max(1.0 - _alpha_a, mask.r);
        float maskG = max(1.0 - _alpha_b, mask.g);
        return min(maskR, maskG);
    }

    void LTSKKS_ClipKKSSkinBodyMask(float2 uv)
    {
        clip(LTSKKS_GetKKSSkinBodyMask(uv) - 0.5);
    }
#endif

float LTSKKS_SampleAlphaMask(float2 uv)
{
    #if defined(LTSKKS_KKS_SKIN)
        return UNITY_SAMPLE_TEX2D(_AlphaMask, LTSKKS_CalcUV(uv, _AlphaMask_ST)).r;
    #else
        return LTSKKS_SAMPLE_TEX(_AlphaMask, LTSKKS_CalcUV(uv, _AlphaMask_ST)).r;
    #endif
}

float LTSKKS_ApplyAlphaMaskValue(float alpha, float2 uv)
{
    float mask = LTSKKS_SampleAlphaMask(uv);
    float processed = saturate(mask * _AlphaMaskScale + _AlphaMaskValue);
    if(_AlphaMaskMode > 0.5 && _AlphaMaskMode < 1.5)
    {
        alpha = processed;
    }
    else if(_AlphaMaskMode >= 1.5 && _AlphaMaskMode < 2.5)
    {
        alpha *= processed;
    }
    else if(_AlphaMaskMode >= 2.5 && _AlphaMaskMode < 3.5)
    {
        alpha = saturate(alpha + processed);
    }
    else if(_AlphaMaskMode >= 3.5 && _AlphaMaskMode < 4.5)
    {
        alpha = saturate(alpha - processed);
    }
    return alpha;
}

float LTSKKS_GetProcessedAlpha(float2 uv, float2 uvMain)
{
    #if defined(LTSKKS_KKS_SKIN)
        float alpha = LTSKKS_SAMPLE_MAIN_TEX(uvMain).a;
    #else
        float alpha = LTSKKS_SAMPLE_MAIN_TEX(uvMain).a * _Color.a;
    #endif
    return LTSKKS_ApplyAlphaMaskValue(alpha, uvMain);
}

float2 LTSKKS_SelectAlphaLayerUV(float2 uv0, float2 uv1, float2 uv2, float2 uv3, float2 uvMat, float uvMode)
{
    if(uvMode > 3.5) return uvMat;
    if(uvMode > 2.5) return uv3;
    if(uvMode > 1.5) return uv2;
    if(uvMode > 0.5) return uv1;
    return uv0;
}

float2 LTSKKS_GetMain2ndAlphaUV(float2 uv0, float2 uv1, float2 uv2, float2 uv3, float2 uvMat)
{
    float2 uv = LTSKKS_SelectAlphaLayerUV(uv0, uv1, uv2, uv3, uvMat, _Main2ndTex_UVMode);
    float4 scrollRotate = float4(_Main2ndTex_ScrollRotate.xy, _Main2ndTexAngle + _Main2ndTex_ScrollRotate.z, _Main2ndTex_ScrollRotate.w);
    float2 regularUV = LTSKKS_CalcUV(uv, _Main2ndTex_ST, scrollRotate);
    float2 decalUV = LTSKKS_CalcDecalUV(uv, _Main2ndTex_ST, scrollRotate, _Main2ndTexIsLeftOnly, _Main2ndTexIsRightOnly, _Main2ndTexShouldCopy, _Main2ndTexShouldFlipMirror, _Main2ndTexShouldFlipCopy);
    return (_Main2ndTexIsDecal > 0.5) ? decalUV : regularUV;
}

float2 LTSKKS_GetMain3rdAlphaUV(float2 uv0, float2 uv1, float2 uv2, float2 uv3, float2 uvMat)
{
    float2 uv = LTSKKS_SelectAlphaLayerUV(uv0, uv1, uv2, uv3, uvMat, _Main3rdTex_UVMode);
    float4 scrollRotate = float4(_Main3rdTex_ScrollRotate.xy, _Main3rdTexAngle + _Main3rdTex_ScrollRotate.z, _Main3rdTex_ScrollRotate.w);
    float2 regularUV = LTSKKS_CalcUV(uv, _Main3rdTex_ST, scrollRotate);
    float2 decalUV = LTSKKS_CalcDecalUV(uv, _Main3rdTex_ST, scrollRotate, _Main3rdTexIsLeftOnly, _Main3rdTexIsRightOnly, _Main3rdTexShouldCopy, _Main3rdTexShouldFlipMirror, _Main3rdTexShouldFlipCopy);
    return (_Main3rdTexIsDecal > 0.5) ? decalUV : regularUV;
}

float LTSKKS_BlendAlphaForMode(float baseAlpha, float layerAlpha, float alphaMode)
{
    if(alphaMode > 0.5 && alphaMode < 1.5) return layerAlpha;
    if(alphaMode >= 1.5 && alphaMode < 2.5) return baseAlpha * layerAlpha;
    if(alphaMode >= 2.5 && alphaMode < 3.5) return saturate(baseAlpha + layerAlpha);
    if(alphaMode >= 3.5 && alphaMode < 4.5) return saturate(baseAlpha - layerAlpha);
    return baseAlpha;
}

float LTSKKS_ApplyMain2ndAlpha(float alpha, float2 uv0, float2 uv1, float2 uv2, float2 uv3, float2 uvMat, float2 uvMain, float3 posWS, float facing, float depth)
{
    if(_UseMain2ndTex < 0.5 || _Main2ndTexAlphaMode < 0.5) return alpha;
    if(_Main2ndTex_Cull > 0.5 && _Main2ndTex_Cull < 1.5 && facing > 0.0) return alpha;
    if(_Main2ndTex_Cull >= 1.5 && _Main2ndTex_Cull < 2.5 && facing < 0.0) return alpha;
    float2 uv = LTSKKS_GetMain2ndAlphaUV(uv0, uv1, uv2, uv3, uvMat);
    float2 sampleUV = (_Main2ndTexIsDecal > 0.5) ? LTSKKS_CalcAtlasAnimationUV(uv, _Main2ndTexDecalAnimation, _Main2ndTexDecalSubParam) : uv;
    float4 layerColor = LTSKKS_ApplyMSDF(LTSKKS_SAMPLE_TEX(_Main2ndTex, sampleUV), _Main2ndTexIsMSDF) * _Color2nd;
    float layerAlpha = layerColor.a;
    layerAlpha *= LTSKKS_DecalUVAlpha(uv, _Main2ndTexIsDecal);
    layerAlpha *= LTSKKS_SAMPLE_TEX(_Main2ndBlendMask, uvMain).r;
    float dissolveAlpha = 0.0;
    LTSKKS_ApplyDissolve(layerAlpha, dissolveAlpha, uv0, posWS, 1);
    layerAlpha = LTSKKS_ApplyLayerDistanceFade(layerAlpha, depth, _Main2ndDistanceFade);
    return LTSKKS_BlendAlphaForMode(alpha, layerAlpha, _Main2ndTexAlphaMode);
}

float LTSKKS_ApplyMain3rdAlpha(float alpha, float2 uv0, float2 uv1, float2 uv2, float2 uv3, float2 uvMat, float2 uvMain, float3 posWS, float facing, float depth)
{
    if(_UseMain3rdTex < 0.5 || _Main3rdTexAlphaMode < 0.5) return alpha;
    if(_Main3rdTex_Cull > 0.5 && _Main3rdTex_Cull < 1.5 && facing > 0.0) return alpha;
    if(_Main3rdTex_Cull >= 1.5 && _Main3rdTex_Cull < 2.5 && facing < 0.0) return alpha;
    float2 uv = LTSKKS_GetMain3rdAlphaUV(uv0, uv1, uv2, uv3, uvMat);
    float2 sampleUV = (_Main3rdTexIsDecal > 0.5) ? LTSKKS_CalcAtlasAnimationUV(uv, _Main3rdTexDecalAnimation, _Main3rdTexDecalSubParam) : uv;
    float4 layerColor = LTSKKS_ApplyMSDF(LTSKKS_SAMPLE_TEX(_Main3rdTex, sampleUV), _Main3rdTexIsMSDF) * _Color3rd;
    float layerAlpha = layerColor.a;
    layerAlpha *= LTSKKS_DecalUVAlpha(uv, _Main3rdTexIsDecal);
    layerAlpha *= LTSKKS_SAMPLE_TEX(_Main3rdBlendMask, uvMain).r;
    float dissolveAlpha = 0.0;
    LTSKKS_ApplyDissolve(layerAlpha, dissolveAlpha, uv0, posWS, 2);
    layerAlpha = LTSKKS_ApplyLayerDistanceFade(layerAlpha, depth, _Main3rdDistanceFade);
    return LTSKKS_BlendAlphaForMode(alpha, layerAlpha, _Main3rdTexAlphaMode);
}

float LTSKKS_GetLayeredProcessedAlphaGrad(float2 uv0, float2 uv1, float2 uv2, float2 uv3, float2 uvMat, float2 uvMain, float2 ddxMain, float2 ddyMain, float3 posWS, float facing, float depth)
{
    #if defined(LTSKKS_KKS_SKIN)
        float alpha = LTSKKS_SampleMainTexAfterParallax(uvMain, ddxMain, ddyMain).a;
    #else
        float alpha = LTSKKS_SampleMainTexAfterParallax(uvMain, ddxMain, ddyMain).a * _Color.a;
    #endif
    alpha = LTSKKS_ApplyMain2ndAlpha(alpha, uv0, uv1, uv2, uv3, uvMat, uvMain, posWS, facing, depth);
    alpha = LTSKKS_ApplyMain3rdAlpha(alpha, uv0, uv1, uv2, uv3, uvMat, uvMain, posWS, facing, depth);
    alpha = LTSKKS_ApplyAlphaMaskValue(alpha, uvMain);
    float dissolveAlpha = 0.0;
    LTSKKS_ApplyDissolve(alpha, dissolveAlpha, uv0, posWS, 0);
    return alpha;
}

float LTSKKS_GetLayeredProcessedAlpha(float2 uv0, float2 uv1, float2 uv2, float2 uv3, float2 uvMat, float2 uvMain, float3 posWS, float facing, float depth)
{
    return LTSKKS_GetLayeredProcessedAlphaGrad(uv0, uv1, uv2, uv3, uvMat, uvMain, abs(ddx(uvMain)), abs(ddy(uvMain)), posWS, facing, depth);
}

void LTSKKS_ClipAlpha(float alpha, float cutoff)
{
    clip(alpha - cutoff);
}

float LTSKKS_GetDitherThreshold(float4 screenPos)
{
    float2 ditherSize = max(_DitherTex_TexelSize.zw, float2(1.0, 1.0));
    float2 ditherPixel = fmod(floor(screenPos.xy), ditherSize);
    float2 ditherUV = (ditherPixel + 0.5) / ditherSize;
    float dither = LTSKKS_SAMPLE_TEX(_DitherTex, ditherUV).r;
    return (dither * 255.0 + 1.0) / max(_DitherMaxValue + 2.0, 1.0);
}

float LTSKKS_GetDitheredAlpha(float alpha, float4 screenPos)
{
    return step(LTSKKS_GetDitherThreshold(screenPos), saturate(alpha));
}

float LTSKKS_GetSubpassDitherAlpha(float alpha, float4 screenPos)
{
    float2 ditherPixel = fmod(floor(screenPos.xy), 4.0);
    float3 ditherUV = float3((ditherPixel + 0.5) * 0.25, saturate(alpha) * 0.9375);
    return tex3D(_DitherMaskLOD, ditherUV).a;
}

float LTSKKS_ApplyDitherToAlpha(float alpha, float4 screenPos)
{
    return (_UseDither > 0.5) ? LTSKKS_GetDitheredAlpha(alpha, screenPos) : alpha;
}

void LTSKKS_ClipSubpassAlpha(float alpha, float4 screenPos)
{
    #if defined(LTSKKS_RENDER_TRANSPARENT) || defined(LTSKKS_RENDER_ONEPASS_TRANSPARENT) || defined(LTSKKS_RENDER_TWOPASS_TRANSPARENT)
        LTSKKS_ClipAlpha(LTSKKS_GetSubpassDitherAlpha(alpha, screenPos), _SubpassCutoff);
    #endif
}

void LTSKKS_ClipTransparentPrepassAlpha(float alpha, float4 screenPos)
{
    #if defined(LTSKKS_RENDER_TRANSPARENT) || defined(LTSKKS_RENDER_ONEPASS_TRANSPARENT) || defined(LTSKKS_RENDER_TWOPASS_TRANSPARENT)
        float prepassAlpha = alpha * _PreColor.a;
        LTSKKS_ClipAlpha(prepassAlpha, _PreCutoff);
        LTSKKS_ClipSubpassAlpha(prepassAlpha, screenPos);
    #endif
}

float4 LTSKKS_PremultiplyTransparentColor(float4 color)
{
    #if defined(LTSKKS_REFRACTION)
        color.rgb *= saturate(color.a);
    #elif defined(LTSKKS_RENDER_TRANSPARENT) || defined(LTSKKS_RENDER_ONEPASS_TRANSPARENT) || defined(LTSKKS_RENDER_TWOPASS_TRANSPARENT)
        #if defined(LTSKKS_PASS_FORWARDADD)
            color.rgb *= saturate(color.a * _AlphaBoostFA);
        #else
            color.rgb *= saturate(color.a);
        #endif
    #endif
    return color;
}

#if defined(LTSKKS_ALPHA_WITH_FRAGDATA)

void LTSKKS_ApplyAlphaMask(inout LTSKKSFragData fd)
{
    fd.col.a = LTSKKS_ApplyAlphaMaskValue(fd.col.a, fd.uvMain);
}

void LTSKKS_ApplyOpaqueAlpha(inout LTSKKSFragData fd)
{
    fd.col.a = 1.0;
}

void LTSKKS_ApplyCutoutAlpha(inout LTSKKSFragData fd, float4 screenPos)
{
    LTSKKS_ApplyAlphaMask(fd);
    LTSKKS_ApplyGlobalDissolve(fd);
    fd.col.a = LTSKKS_ApplyDitherToAlpha(fd.col.a, screenPos);
    LTSKKS_ClipAlpha(fd.col.a, _Cutoff);
}

void LTSKKS_ApplyTransparentAlpha(inout LTSKKSFragData fd, float4 screenPos)
{
    LTSKKS_ApplyAlphaMask(fd);
    LTSKKS_ApplyGlobalDissolve(fd);
    #if defined(LTSKKS_TRANSPARENT_PRE)
        fd.col *= _PreColor;
        LTSKKS_ClipAlpha(fd.col.a, _PreCutoff);
    #else
        LTSKKS_ClipAlpha(fd.col.a, _Cutoff);
    #endif
}

void LTSKKS_ApplyRenderAlpha(inout LTSKKSFragData fd, float4 screenPos)
{
    #if defined(LTSKKS_KKS_SKIN)
        LTSKKS_ClipKKSSkinBodyMask(fd.uv0);
    #endif
    #if defined(LTSKKS_RENDER_CUTOUT)
        LTSKKS_ApplyCutoutAlpha(fd, screenPos);
    #elif defined(LTSKKS_REFRACTION) || defined(LTSKKS_GEM)
        LTSKKS_ApplyAlphaMask(fd);
        LTSKKS_ApplyGlobalDissolve(fd);
    #elif defined(LTSKKS_RENDER_TRANSPARENT) || defined(LTSKKS_RENDER_ONEPASS_TRANSPARENT) || defined(LTSKKS_RENDER_TWOPASS_TRANSPARENT)
        LTSKKS_ApplyTransparentAlpha(fd, screenPos);
    #else
        LTSKKS_ApplyOpaqueAlpha(fd);
    #endif
}

#endif

void LTSKKS_ClipShadowAlpha(float alpha, float4 screenPos)
{
    #if defined(LTSKKS_RENDER_CUTOUT)
        alpha = LTSKKS_ApplyDitherToAlpha(alpha, screenPos);
        LTSKKS_ClipAlpha(alpha, _Cutoff);
    #elif defined(LTSKKS_RENDER_TRANSPARENT) || defined(LTSKKS_RENDER_ONEPASS_TRANSPARENT) || defined(LTSKKS_RENDER_TWOPASS_TRANSPARENT)
        LTSKKS_ClipAlpha(alpha, _Cutoff);
        LTSKKS_ClipSubpassAlpha(alpha, screenPos);
    #endif
}

#endif
