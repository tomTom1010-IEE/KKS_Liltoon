#ifndef LTSKKS_EMISSION_INCLUDED
#define LTSKKS_EMISSION_INCLUDED

float LTSKKS_Blink(float4 blink)
{
    float strength = blink.x;
    float speed = blink.y;
    float offset = blink.z;
    float mix = blink.w;
    float wave = sin((_Time.y + offset) * max(speed, 0.0)) * 0.5 + 0.5;
    return lerp(1.0, lerp(1.0 - strength, 1.0 + strength, wave), saturate(mix));
}

float2 LTSKKS_GetEmissionUV(LTSKKSFragData fd, float uvMode)
{
    if(uvMode > 0.5 && uvMode < 1.5) return fd.uv1;
    if(uvMode >= 1.5 && uvMode < 2.5) return fd.uv2;
    if(uvMode >= 2.5 && uvMode < 3.5) return fd.uv3;
    if(uvMode >= 3.5 && uvMode < 4.5) return float2(fd.nvabs, fd.nvabs);
    return fd.uv0;
}

float LTSKKS_GetEmissionTransparency(LTSKKSFragData fd)
{
#if defined(LTSKKS_RENDER_TRANSPARENT) || defined(LTSKKS_RENDER_ONEPASS_TRANSPARENT) || defined(LTSKKS_RENDER_TWOPASS_TRANSPARENT)
    return fd.col.a;
#else
    return 1.0;
#endif
}

void LTSKKS_ApplyEmission(inout LTSKKSFragData fd)
{
    float transparency = LTSKKS_GetEmissionTransparency(fd);

    if(_UseEmission > 0.5)
    {
        float2 uv = LTSKKS_GetEmissionUV(fd, _EmissionMap_UVMode);
        uv += _EmissionParallaxDepth * fd.parallaxOffset;
        uv = LTSKKS_CalcUV(uv, _EmissionMap_ST, _EmissionMap_ScrollRotate);
        #if defined(LTSKKS_KKS_SKIN)
            float4 emission = LTSKKS_SAMPLE_KKS_SKIN(_EmissionMask, LTSKKS_CalcUV(fd.uv0, _EmissionMask_ST)) * _EmissionColor * _EmissionIntensity;
        #else
            float4 emission = LTSKKS_SAMPLE_TEX(_EmissionMap, uv) * _EmissionColor;
        #endif
        float2 maskUV = LTSKKS_CalcUV(fd.uvMain, _EmissionBlendMask_ST, _EmissionBlendMask_ScrollRotate);
        emission *= LTSKKS_SAMPLE_TEX(_EmissionBlendMask, maskUV);
        float2 gradUV = float2(frac(_EmissionGradSpeed * _Time.y), 0.5);
        emission *= lerp(1.0, LTSKKS_SAMPLE_TEX(_EmissionGradTex, gradUV), saturate(_EmissionUseGrad));
        emission.rgb = lerp(emission.rgb, emission.rgb * fd.invLighting, saturate(_EmissionFluorescence));
        emission.rgb = lerp(emission.rgb, emission.rgb * fd.albedo, saturate(_EmissionMainStrength));
        float alpha = _EmissionBlend * LTSKKS_Blink(_EmissionBlink) * emission.a * transparency;
        #if defined(LTSKKS_KKS_SKIN)
            float3 overlayedEmission = lerp(fd.col.rgb, emission.rgb, alpha);
            float3 maskedEmission = fd.col.rgb + fd.col.rgb * emission.rgb * alpha;
            fd.col.rgb = lerp(overlayedEmission, maskedEmission, saturate(_EmissionMaskMode));
        #else
            fd.col.rgb = LTSKKS_BlendColor(fd.col.rgb, emission.rgb, alpha, _EmissionBlendMode);
        #endif
        fd.emissionColor += emission.rgb * alpha;
    }

    if(_UseEmission2nd > 0.5)
    {
        float2 uv = LTSKKS_GetEmissionUV(fd, _Emission2ndMap_UVMode);
        uv += _Emission2ndParallaxDepth * fd.parallaxOffset;
        uv = LTSKKS_CalcUV(uv, _Emission2ndMap_ST, _Emission2ndMap_ScrollRotate);
        float4 emission = LTSKKS_SAMPLE_TEX(_Emission2ndMap, uv) * _Emission2ndColor;
        float2 maskUV = LTSKKS_CalcUV(fd.uvMain, _Emission2ndBlendMask_ST, _Emission2ndBlendMask_ScrollRotate);
        emission *= LTSKKS_SAMPLE_TEX(_Emission2ndBlendMask, maskUV);
        float2 gradUV = float2(frac(_Emission2ndGradSpeed * _Time.y), 0.5);
        emission *= lerp(1.0, LTSKKS_SAMPLE_TEX(_Emission2ndGradTex, gradUV), saturate(_Emission2ndUseGrad));
        emission.rgb = lerp(emission.rgb, emission.rgb * fd.invLighting, saturate(_Emission2ndFluorescence));
        emission.rgb = lerp(emission.rgb, emission.rgb * fd.albedo, saturate(_Emission2ndMainStrength));
        float alpha = _Emission2ndBlend * LTSKKS_Blink(_Emission2ndBlink) * emission.a * transparency;
        fd.col.rgb = LTSKKS_BlendColor(fd.col.rgb, emission.rgb, alpha, _Emission2ndBlendMode);
        fd.emissionColor += emission.rgb * alpha;
    }
}

#endif
