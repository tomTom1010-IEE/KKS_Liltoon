#ifndef LTSKKS_DISSOLVE_INCLUDED
#define LTSKKS_DISSOLVE_INCLUDED

void LTSKKS_CalcDissolve(
    inout float alpha,
    out float dissolveAlpha,
    float2 uv,
    float3 positionWS,
    float4 dissolveParams,
    float4 dissolvePos,
    float dissolveMask,
    float dissolveNoise)
{
    float mode = round(dissolveParams.x);
    float shape = round(dissolveParams.y);
    dissolveAlpha = 0.0;
    if(mode < 0.5) return;

    float threshold = dissolveParams.z;
    float edgeWidth = max(abs(dissolveParams.w), LTSKKS_EPS);
    float dissolveValue = dissolveMask + dissolveNoise;

    if(mode > 1.5 && mode < 2.5)
    {
        float2 direction = normalize(dissolvePos.xy + float2(LTSKKS_EPS, 0.0));
        dissolveValue = (shape > 0.5 ? dot(uv, direction) : distance(uv, dissolvePos.xy)) + dissolveNoise;
    }
    else if(mode > 2.5 && mode < 3.5)
    {
        float3 positionOS = mul(unity_WorldToObject, float4(positionWS, 1.0)).xyz;
        float3 direction = normalize(dissolvePos.xyz + float3(LTSKKS_EPS, 0.0, 0.0));
        dissolveValue = (shape > 0.5 ? dot(positionOS, direction) : distance(positionOS, dissolvePos.xyz)) + dissolveNoise;
    }

    dissolveAlpha = 1.0 - saturate(abs(dissolveValue - threshold) / edgeWidth);
    alpha *= dissolveValue > threshold ? 1.0 : 0.0;
}

float LTSKKS_SampleDissolveNoise(
    float2 uv,
    float4 noiseST,
    float4 noiseScrollRotate,
    float noiseStrength,
    int layer)
{
    float2 noiseUV = LTSKKS_CalcUV(uv, noiseST, noiseScrollRotate);
    float noise = 0.5;
    if(layer == 1) noise = LTSKKS_SAMPLE_TEX(_Main2ndDissolveNoiseMask, noiseUV).r;
    else if(layer == 2) noise = LTSKKS_SAMPLE_TEX(_Main3rdDissolveNoiseMask, noiseUV).r;
    else noise = LTSKKS_SAMPLE_TEX(_DissolveNoiseMask, noiseUV).r;
    return (noise - 0.5) * noiseStrength;
}

void LTSKKS_ApplyDissolve(
    inout float alpha,
    out float dissolveAlpha,
    float2 uv,
    float3 positionWS,
    int layer)
{
    float4 dissolveParams = _DissolveParams;
    float4 dissolvePos = _DissolvePos;
    float dissolveMask = LTSKKS_SAMPLE_TEX(_DissolveMask, LTSKKS_CalcUV(uv, _DissolveMask_ST)).r;
    float dissolveNoise = LTSKKS_SampleDissolveNoise(
        uv,
        _DissolveNoiseMask_ST,
        _DissolveNoiseMask_ScrollRotate,
        _DissolveNoiseStrength,
        0);

    if(layer == 1)
    {
        dissolveParams = _Main2ndDissolveParams;
        dissolvePos = _Main2ndDissolvePos;
        dissolveMask = LTSKKS_SAMPLE_TEX(_Main2ndDissolveMask, LTSKKS_CalcUV(uv, _Main2ndDissolveMask_ST)).r;
        dissolveNoise = LTSKKS_SampleDissolveNoise(
            uv,
            _Main2ndDissolveNoiseMask_ST,
            _Main2ndDissolveNoiseMask_ScrollRotate,
            _Main2ndDissolveNoiseStrength,
            1);
    }
    else if(layer == 2)
    {
        dissolveParams = _Main3rdDissolveParams;
        dissolvePos = _Main3rdDissolvePos;
        dissolveMask = LTSKKS_SAMPLE_TEX(_Main3rdDissolveMask, LTSKKS_CalcUV(uv, _Main3rdDissolveMask_ST)).r;
        dissolveNoise = LTSKKS_SampleDissolveNoise(
            uv,
            _Main3rdDissolveNoiseMask_ST,
            _Main3rdDissolveNoiseMask_ScrollRotate,
            _Main3rdDissolveNoiseStrength,
            2);
    }

    LTSKKS_CalcDissolve(alpha, dissolveAlpha, uv, positionWS, dissolveParams, dissolvePos, dissolveMask, dissolveNoise);
}

#if defined(LTSKKS_DISSOLVE_WITH_FRAGDATA)

void LTSKKS_ApplyGlobalDissolve(inout LTSKKSFragData fd)
{
    LTSKKS_ApplyDissolve(fd.col.a, fd.dissolveAlpha, fd.uv0, fd.posWS, 0);
}

void LTSKKS_ApplyDissolveEmission(inout LTSKKSFragData fd)
{
    #if !defined(LTSKKS_PASS_FORWARDADD)
        float3 dissolveEmission =
            _DissolveColor.rgb * fd.dissolveAlpha +
            _Main2ndDissolveColor.rgb * fd.main2ndDissolveAlpha +
            _Main3rdDissolveColor.rgb * fd.main3rdDissolveAlpha;
        fd.col.rgb += dissolveEmission;
        fd.emissionColor += dissolveEmission;
    #endif
}

#endif

#endif
