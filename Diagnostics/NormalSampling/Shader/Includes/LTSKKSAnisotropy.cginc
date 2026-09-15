#ifndef LTSKKS_ANISOTROPY_INCLUDED
#define LTSKKS_ANISOTROPY_INCLUDED

float3 LTSKKS_GetAnisotropyNormalWS(float3 normalWS, float3 anisoTangentWS, float3 anisoBitangentWS, float3 viewDirection, float anisotropy)
{
    float3 anisoDirectionWS = anisotropy > 0.0 ? anisoBitangentWS : anisoTangentWS;
    anisoDirectionWS = LTSKKS_OrthoNormalize(viewDirection, anisoDirectionWS);
    return normalize(lerp(normalWS, anisoDirectionWS, abs(anisotropy)));
}

void LTSKKS_ApplyAnisotropy(inout LTSKKSFragData fd)
{
    if(_UseAnisotropy < 0.5) return;

    float2 uv = LTSKKS_CalcUV(fd.uvMain, _AnisotropyTangentMap_ST);
    float3 tangentTS = LTSKKS_UnpackNormalScale(LTSKKS_SAMPLE_TEX(_AnisotropyTangentMap, uv), 1.0);
    float3x3 tbn = float3x3(fd.T, fd.B, fd.origN);
    fd.T = LTSKKS_OrthoNormalize(normalize(mul(tangentTS, tbn)), fd.N);
    fd.B = normalize(cross(fd.N, fd.T));

    float scaleMask = LTSKKS_SAMPLE_TEX(_AnisotropyScaleMask, LTSKKS_CalcUV(fd.uvMain, _AnisotropyScaleMask_ST)).r;
    fd.anisotropy = saturate(abs(_AnisotropyScale * scaleMask)) * sign(_AnisotropyScale * scaleMask);
    float3 anisoNormalWS = LTSKKS_GetAnisotropyNormalWS(fd.N, fd.T, fd.B, fd.V, fd.anisotropy);

    if(_Anisotropy2Reflection > 0.5)
    {
        fd.reflectionN = anisoNormalWS;
        fd.perceptualRoughness = saturate(1.2 - abs(fd.anisotropy));
    }
    if(_Anisotropy2MatCap > 0.5) fd.matcapN = anisoNormalWS;
    if(_Anisotropy2MatCap2nd > 0.5) fd.matcap2ndN = anisoNormalWS;
}

#endif
