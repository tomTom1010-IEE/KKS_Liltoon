#ifndef LTSKKS_MAIN_INCLUDED
#define LTSKKS_MAIN_INCLUDED

float2 LTSKKS_SelectUV(LTSKKSFragData fd, float uvMode)
{
    if(uvMode > 3.5) return fd.uvMat;
    if(uvMode > 2.5) return fd.uv3;
    if(uvMode > 1.5) return fd.uv2;
    if(uvMode > 0.5) return fd.uv1;
    return fd.uv0;
}

float2 LTSKKS_GetMain2ndUV(LTSKKSFragData fd)
{
    float2 uv = LTSKKS_SelectUV(fd, _Main2ndTex_UVMode);
    float4 scrollRotate = float4(_Main2ndTex_ScrollRotate.xy, _Main2ndTexAngle + _Main2ndTex_ScrollRotate.z, _Main2ndTex_ScrollRotate.w);
    float2 regularUV = LTSKKS_CalcUV(uv, _Main2ndTex_ST, scrollRotate);
    float2 decalUV = LTSKKS_CalcDecalUV(uv, _Main2ndTex_ST, scrollRotate, _Main2ndTexIsLeftOnly, _Main2ndTexIsRightOnly, _Main2ndTexShouldCopy, _Main2ndTexShouldFlipMirror, _Main2ndTexShouldFlipCopy);
    return (_Main2ndTexIsDecal > 0.5) ? decalUV : regularUV;
}

float2 LTSKKS_GetMain3rdUV(LTSKKSFragData fd)
{
    float2 uv = LTSKKS_SelectUV(fd, _Main3rdTex_UVMode);
    float4 scrollRotate = float4(_Main3rdTex_ScrollRotate.xy, _Main3rdTexAngle + _Main3rdTex_ScrollRotate.z, _Main3rdTex_ScrollRotate.w);
    float2 regularUV = LTSKKS_CalcUV(uv, _Main3rdTex_ST, scrollRotate);
    float2 decalUV = LTSKKS_CalcDecalUV(uv, _Main3rdTex_ST, scrollRotate, _Main3rdTexIsLeftOnly, _Main3rdTexIsRightOnly, _Main3rdTexShouldCopy, _Main3rdTexShouldFlipMirror, _Main3rdTexShouldFlipCopy);
    return (_Main3rdTexIsDecal > 0.5) ? decalUV : regularUV;
}

void LTSKKS_ApplyMain(inout LTSKKSFragData fd)
{
    fd.uvMain = LTSKKS_CalcUV(fd.uv0, _MainTex_ST, _MainTex_ScrollRotate);
    fd.ddxMain = abs(ddx(fd.uvMain));
    fd.ddyMain = abs(ddy(fd.uvMain));
    LTSKKS_ApplyMainParallax(fd);
    float4 mainTex = LTSKKS_SampleMainTexAfterParallax(fd.uvMain, fd.ddxMain, fd.ddyMain);
    float3 beforeToneCorrection = mainTex.rgb;
    float colorAdjustMask = LTSKKS_SAMPLE_TEX(_MainColorAdjustMask, fd.uvMain).r;
    mainTex.rgb = LTSKKS_ToneCorrection(mainTex.rgb, _MainTexHSVG);

    float3 grad = LTSKKS_SAMPLE_TEX(_MainGradationTex, float2(saturate(dot(mainTex.rgb, float3(0.3333,0.3333,0.3333))), 0.5)).rgb;
    mainTex.rgb = lerp(mainTex.rgb, grad, saturate(_MainGradationStrength));
    mainTex.rgb = lerp(beforeToneCorrection, mainTex.rgb, saturate(colorAdjustMask));

    fd.col = mainTex * _Color;
}

bool LTSKKS_IsLayerVisibleForFace(float cullMode, float facing)
{
    if(cullMode > 0.5 && cullMode < 1.5 && facing > 0.0) return false;
    if(cullMode >= 1.5 && cullMode < 2.5 && facing < 0.0) return false;
    return true;
}

float LTSKKS_BlendLayerAlpha(float baseAlpha, float layerAlpha, float alphaMode)
{
    if(alphaMode > 0.5 && alphaMode < 1.5)
    {
        return layerAlpha;
    }
    if(alphaMode >= 1.5 && alphaMode < 2.5)
    {
        return baseAlpha * layerAlpha;
    }
    if(alphaMode >= 2.5 && alphaMode < 3.5)
    {
        return saturate(baseAlpha + layerAlpha);
    }
    if(alphaMode >= 3.5 && alphaMode < 4.5)
    {
        return saturate(baseAlpha - layerAlpha);
    }
    return baseAlpha;
}

void LTSKKS_ApplyMain2ndLayer(inout LTSKKSFragData fd)
{
    fd.main2ndLayer = 0.0;
    if(_UseMain2ndTex < 0.5) return;
    if(!LTSKKS_IsLayerVisibleForFace(_Main2ndTex_Cull, fd.facing)) return;
    float2 uv = LTSKKS_GetMain2ndUV(fd);
    float2 sampleUV = (_Main2ndTexIsDecal > 0.5) ? LTSKKS_CalcAtlasAnimationUV(uv, _Main2ndTexDecalAnimation, _Main2ndTexDecalSubParam) : uv;
    float4 layer = LTSKKS_ApplyMSDF(LTSKKS_SAMPLE_TEX(_Main2ndTex, sampleUV), _Main2ndTexIsMSDF) * _Color2nd;
    layer.a *= LTSKKS_DecalUVAlpha(uv, _Main2ndTexIsDecal);
    float mask = LTSKKS_SAMPLE_TEX(_Main2ndBlendMask, fd.uvMain).r;
    layer.a *= mask;
    layer.a = LTSKKS_ApplyLayerDistanceFade(layer.a, fd.depth, _Main2ndDistanceFade);
    float layerBlendAlpha = layer.a;
    if(_Main2ndTexAlphaMode > 0.5)
    {
        fd.col.a = LTSKKS_BlendLayerAlpha(fd.col.a, layer.a, _Main2ndTexAlphaMode);
        layer.a = 1.0;
        layerBlendAlpha = 1.0;
    }
    fd.main2ndLayer = layer;
    fd.col.rgb = LTSKKS_BlendColor(fd.col.rgb, layer.rgb, layerBlendAlpha * saturate(_Main2ndEnableLighting), _Main2ndTexBlendMode);
}

void LTSKKS_ApplyMain3rdLayer(inout LTSKKSFragData fd)
{
    fd.main3rdLayer = 0.0;
    if(_UseMain3rdTex < 0.5) return;
    if(!LTSKKS_IsLayerVisibleForFace(_Main3rdTex_Cull, fd.facing)) return;
    float2 uv = LTSKKS_GetMain3rdUV(fd);
    float2 sampleUV = (_Main3rdTexIsDecal > 0.5) ? LTSKKS_CalcAtlasAnimationUV(uv, _Main3rdTexDecalAnimation, _Main3rdTexDecalSubParam) : uv;
    float4 layer = LTSKKS_ApplyMSDF(LTSKKS_SAMPLE_TEX(_Main3rdTex, sampleUV), _Main3rdTexIsMSDF) * _Color3rd;
    layer.a *= LTSKKS_DecalUVAlpha(uv, _Main3rdTexIsDecal);
    float mask = LTSKKS_SAMPLE_TEX(_Main3rdBlendMask, fd.uvMain).r;
    layer.a *= mask;
    layer.a = LTSKKS_ApplyLayerDistanceFade(layer.a, fd.depth, _Main3rdDistanceFade);
    float layerBlendAlpha = layer.a;
    if(_Main3rdTexAlphaMode > 0.5)
    {
        fd.col.a = LTSKKS_BlendLayerAlpha(fd.col.a, layer.a, _Main3rdTexAlphaMode);
        layer.a = 1.0;
        layerBlendAlpha = 1.0;
    }
    fd.main3rdLayer = layer;
    fd.col.rgb = LTSKKS_BlendColor(fd.col.rgb, layer.rgb, layerBlendAlpha * saturate(_Main3rdEnableLighting), _Main3rdTexBlendMode);
}

void LTSKKS_ApplyMainLayers(inout LTSKKSFragData fd)
{
    LTSKKS_ApplyMain2ndLayer(fd);
    LTSKKS_ApplyMain3rdLayer(fd);
}

void LTSKKS_ApplyMainLayersAfterLighting(inout LTSKKSFragData fd)
{
    float main2ndUnlitAlpha = fd.main2ndLayer.a * (1.0 - saturate(_Main2ndEnableLighting));
    float main3rdUnlitAlpha = fd.main3rdLayer.a * (1.0 - saturate(_Main3rdEnableLighting));

    #if defined(LTSKKS_PASS_FORWARDADD)
        fd.col.rgb = lerp(fd.col.rgb, 0.0, main2ndUnlitAlpha);
        fd.col.rgb = lerp(fd.col.rgb, 0.0, main3rdUnlitAlpha);
    #else
        fd.col.rgb = LTSKKS_BlendColor(fd.col.rgb, fd.main2ndLayer.rgb, main2ndUnlitAlpha, _Main2ndTexBlendMode);
        fd.col.rgb = LTSKKS_BlendColor(fd.col.rgb, fd.main3rdLayer.rgb, main3rdUnlitAlpha, _Main3rdTexBlendMode);
    #endif
}

#endif
