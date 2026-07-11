#ifndef LTSKKS_MATCAP_INCLUDED
#define LTSKKS_MATCAP_INCLUDED

float3 LTSKKS_GetMatCapNormal(LTSKKSFragData fd, float3 matcapBaseNormal, float normalStrength, float customNormal, float bumpScale, float4 bumpMapST, int secondMap)
{
    float3 n = normalize(lerp(fd.origN, matcapBaseNormal, saturate(normalStrength)));
    if(customNormal > 0.5)
    {
        float2 uv = LTSKKS_CalcUV(fd.uvMain, bumpMapST);
        float4 packed = secondMap == 0 ? LTSKKS_SAMPLE_TEX(_MatCapBumpMap, uv) : LTSKKS_SAMPLE_TEX(_MatCap2ndBumpMap, uv);
        float3 normalTS = LTSKKS_UnpackNormalScale(packed, bumpScale);
        float3x3 tbn = float3x3(fd.T, fd.B, fd.origN);
        n = normalize(mul(normalTS, tbn));
        n = (fd.facing < (_FlipNormal - 1.0)) ? -n : n;
    }
    return normalize(n);
}

void LTSKKS_ApplyMatCapLayer(inout LTSKKSFragData fd, int secondLayer)
{
    if(secondLayer == 0)
    {
        float3 n = LTSKKS_GetMatCapNormal(fd, fd.matcapN, _MatCapNormalStrength, _MatCapCustomNormal, _MatCapBumpScale, _MatCapBumpMap_ST, 0);
        float2 uv = LTSKKS_CalcMatCapUV(fd.uv1, n, fd.V, _MatCapTex_ST, _MatCapBlendUV1.xy, _MatCapZRotCancel, _MatCapPerspective, _MatCapVRParallaxStrength);
        float4 matCapColor = _MatCapColor * tex2Dlod(_MatCapTex, float4(uv, 0.0, max(_MatCapLod, 0.0)));

        #if defined(LTSKKS_PASS_FORWARDADD)
            if(_MatCapBlendMode < 3.0) matCapColor.rgb *= fd.lightColor * saturate(_MatCapEnableLighting);
            matCapColor.a = lerp(matCapColor.a, matCapColor.a * fd.shadowmix, saturate(_MatCapShadowMask));
        #else
            matCapColor.rgb = lerp(matCapColor.rgb, matCapColor.rgb * fd.lightColor, saturate(_MatCapEnableLighting));
            matCapColor.a = lerp(matCapColor.a, matCapColor.a * fd.shadowmix, saturate(_MatCapShadowMask));
        #endif

        #if defined(LTSKKS_RENDER_TRANSPARENT) || defined(LTSKKS_RENDER_ONEPASS_TRANSPARENT) || defined(LTSKKS_RENDER_TWOPASS_TRANSPARENT)
            if(_MatCapApplyTransparency > 0.5) matCapColor.a *= fd.col.a;
        #endif
        matCapColor.a = fd.facing < (_MatCapBackfaceMask - 1.0) ? 0.0 : matCapColor.a;
        float3 mask = LTSKKS_SAMPLE_TEX(_MatCapBlendMask, LTSKKS_CalcUV(fd.uvMain, _MatCapBlendMask_ST)).rgb;
        matCapColor.rgb = lerp(matCapColor.rgb, matCapColor.rgb * fd.albedo, saturate(_MatCapMainStrength));
        fd.col.rgb = LTSKKS_BlendColorMask(fd.col.rgb, matCapColor.rgb, _MatCapBlend * matCapColor.a * mask, _MatCapBlendMode);
    }
    else
    {
        float3 n = LTSKKS_GetMatCapNormal(fd, fd.matcap2ndN, _MatCap2ndNormalStrength, _MatCap2ndCustomNormal, _MatCap2ndBumpScale, _MatCap2ndBumpMap_ST, 1);
        float2 uv = LTSKKS_CalcMatCapUV(fd.uv1, n, fd.V, _MatCap2ndTex_ST, _MatCap2ndBlendUV1.xy, _MatCap2ndZRotCancel, _MatCap2ndPerspective, _MatCap2ndVRParallaxStrength);
        float4 matCapColor = _MatCap2ndColor * tex2Dlod(_MatCap2ndTex, float4(uv, 0.0, max(_MatCap2ndLod, 0.0)));

        #if defined(LTSKKS_PASS_FORWARDADD)
            if(_MatCap2ndBlendMode < 3.0) matCapColor.rgb *= fd.lightColor * saturate(_MatCap2ndEnableLighting);
            matCapColor.a = lerp(matCapColor.a, matCapColor.a * fd.shadowmix, saturate(_MatCap2ndShadowMask));
        #else
            matCapColor.rgb = lerp(matCapColor.rgb, matCapColor.rgb * fd.lightColor, saturate(_MatCap2ndEnableLighting));
            matCapColor.a = lerp(matCapColor.a, matCapColor.a * fd.shadowmix, saturate(_MatCap2ndShadowMask));
        #endif

        #if defined(LTSKKS_RENDER_TRANSPARENT) || defined(LTSKKS_RENDER_ONEPASS_TRANSPARENT) || defined(LTSKKS_RENDER_TWOPASS_TRANSPARENT)
            if(_MatCap2ndApplyTransparency > 0.5) matCapColor.a *= fd.col.a;
        #endif
        matCapColor.a = fd.facing < (_MatCap2ndBackfaceMask - 1.0) ? 0.0 : matCapColor.a;
        float3 mask = LTSKKS_SAMPLE_TEX(_MatCap2ndBlendMask, LTSKKS_CalcUV(fd.uvMain, _MatCap2ndBlendMask_ST)).rgb;
        matCapColor.rgb = lerp(matCapColor.rgb, matCapColor.rgb * fd.albedo, saturate(_MatCap2ndMainStrength));
        fd.col.rgb = LTSKKS_BlendColorMask(fd.col.rgb, matCapColor.rgb, _MatCap2ndBlend * matCapColor.a * mask, _MatCap2ndBlendMode);
    }
}

void LTSKKS_ApplyMatCap(inout LTSKKSFragData fd)
{
    if(_UseMatCap > 0.5)
    {
        LTSKKS_ApplyMatCapLayer(fd, 0);
    }

    if(_UseMatCap2nd > 0.5)
    {
        LTSKKS_ApplyMatCapLayer(fd, 1);
    }
}

#endif
