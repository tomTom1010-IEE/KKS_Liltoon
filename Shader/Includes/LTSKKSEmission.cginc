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

void LTSKKS_ApplyEmission(inout LTSKKSFragData fd)
{
    if(_UseEmission > 0.5)
    {
        float2 uv = LTSKKS_CalcUV(fd.uv0, _EmissionMap_ST, _EmissionMap_ScrollRotate);
        float4 emission = LTSKKS_SAMPLE_TEX(_EmissionMap, uv) * _EmissionColor * LTSKKS_Blink(_EmissionBlink);
        float mask = LTSKKS_SAMPLE_TEX(_EmissionBlendMask, fd.uv0).r;
        float alpha = _EmissionBlend * mask * emission.a;
        fd.col.rgb = LTSKKS_BlendColor(fd.col.rgb, emission.rgb, alpha, _EmissionBlendMode);
        fd.emissionColor += emission.rgb * alpha;
    }

    if(_UseEmission2nd > 0.5)
    {
        float2 uv = LTSKKS_CalcUV(fd.uv0, _Emission2ndMap_ST, _Emission2ndMap_ScrollRotate);
        float4 emission = LTSKKS_SAMPLE_TEX(_Emission2ndMap, uv) * _Emission2ndColor * LTSKKS_Blink(_Emission2ndBlink);
        float mask = LTSKKS_SAMPLE_TEX(_Emission2ndBlendMask, fd.uv0).r;
        float alpha = _Emission2ndBlend * mask * emission.a;
        fd.col.rgb = LTSKKS_BlendColor(fd.col.rgb, emission.rgb, alpha, _Emission2ndBlendMode);
        fd.emissionColor += emission.rgb * alpha;
    }
}

#endif