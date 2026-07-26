#ifndef LTSKKS_NORMAL_INCLUDED
#define LTSKKS_NORMAL_INCLUDED

#if defined(LTSKKS_KKS_SKIN)
    #include "LTSKKSKKSLiquid.cginc"
#endif

void LTSKKS_ApplyNormal(inout LTSKKSFragData fd, LTSKKSV2F i)
{
    fd.origN = normalize(i.normalWS);
    fd.T = normalize(i.tangentWS.xyz);
    fd.B = normalize(i.bitangentWS);
    float3x3 tbn = float3x3(fd.T, fd.B, fd.origN);

    float3 normalTS = float3(0.0, 0.0, 1.0);
    #if defined(LTSKKS_KKS_SKIN)
        if(_UseBumpMap > 0.5)
        {
            float2 skinUV = LTSKKS_CalcUV(fd.uv0, _NormalMap_ST);
            normalTS = LTSKKS_UnpackNormalScale(LTSKKS_SAMPLE_KKS_SKIN(_NormalMap, skinUV), _NormalMapScale);
        }
        if(_UseBump2ndMap > 0.5)
        {
            float2 detailUV = LTSKKS_CalcUV(fd.uv0, _NormalMapDetail_ST);
            float3 detailNormal = LTSKKS_UnpackNormalScale(LTSKKS_SAMPLE_KKS_SKIN(_NormalMapDetail, detailUV), _DetailNormalMapScale);
            normalTS = LTSKKS_BlendNormal(normalTS, detailNormal);
        }

        float3 liquidNormal;
        LTSKKS_GetKKSLiquid(fd.uv0, fd.liquidMask, liquidNormal);
        float3 maskedLiquidNormal = normalize(lerp(float3(0.0, 0.0, 1.0), liquidNormal, fd.liquidMask));
        normalTS = LTSKKS_BlendNormal(normalTS, maskedLiquidNormal);
    #else
    if(_UseBumpMap > 0.5)
    {
        float2 uv = LTSKKS_CalcUV(fd.uvMain, _BumpMap_ST);
        normalTS = LTSKKS_UnpackNormalScale(LTSKKS_SAMPLE_TEX(_BumpMap, uv), _BumpScale);
    }
    if(_UseBump2ndMap > 0.5)
    {
        float2 uv2 = LTSKKS_SelectUV(fd, _Bump2ndMap_UVMode);
        uv2 = LTSKKS_CalcUV(uv2, _Bump2ndMap_ST);
        float2 scaleMaskUV = LTSKKS_CalcUV(fd.uvMain, _Bump2ndScaleMask_ST);
        float scaleMask = LTSKKS_SAMPLE_TEX(_Bump2ndScaleMask, scaleMaskUV).r;
        float3 normal2 = LTSKKS_UnpackNormalScale(LTSKKS_SAMPLE_TEX(_Bump2ndMap, uv2), _Bump2ndScale * scaleMask);
        normalTS = LTSKKS_BlendNormal(normalTS, normal2);
    }
    #endif

    fd.N = normalize(mul(normalTS, tbn));
    fd.N = (fd.facing < (_FlipNormal - 1.0)) ? -fd.N : fd.N;
    fd.reflectionN = fd.N;
    fd.matcapN = fd.N;
    fd.matcap2ndN = fd.N;
    fd.uvMat = LTSKKS_MatCapUV(fd.N).xy;
}

#endif
