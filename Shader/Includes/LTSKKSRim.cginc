#ifndef LTSKKS_RIM_INCLUDED
#define LTSKKS_RIM_INCLUDED

void LTSKKS_ApplyRim(inout LTSKKSFragData fd)
{
    if(_UseRim < 0.5) return;

    float4 rimTex = LTSKKS_SAMPLE_TEX(_RimColorTex, fd.uvMain);
    float4 rimColor = _RimColor * rimTex;
    float4 rimIndirColor = _RimIndirColor * rimTex;
    rimColor.rgb = lerp(rimColor.rgb, rimColor.rgb * fd.albedo, saturate(_RimMainStrength));
    rimIndirColor.rgb = lerp(rimColor.rgb, rimIndirColor.rgb, saturate(_RimIndirColorStrength));

    float3 n = normalize(lerp(fd.origN, fd.N, saturate(_RimNormalStrength)));
    float nvabs = abs(dot(n, fd.V));
    float lnRaw = dot(fd.L, n) * 0.5 + 0.5;
    float lnDir = saturate((lnRaw + _RimDirRange) / max(1.0 + _RimDirRange, 0.0001));
    float lnIndir = saturate((1.0 - lnRaw + _RimIndirRange) / max(1.0 + _RimIndirRange, 0.0001));

    float rim = pow(saturate(1.0 - nvabs), max(_RimFresnelPower, 0.01));
    rim = fd.facing < (_RimBackfaceMask - 1.0) ? 0.0 : rim;
    float rimDir = lerp(rim, rim * lnDir, saturate(_RimDirStrength));
    float rimIndir = rim * lnIndir * saturate(_RimDirStrength);

    rimDir = LTSKKS_TooningAAScale(rimDir, _RimBorder, _RimBlur);
    rimIndir = LTSKKS_TooningAAScale(rimIndir, _RimIndirBorder, _RimIndirBlur);
    rimDir = lerp(rimDir, rimDir * fd.shadowmix, saturate(_RimShadowMask));
    rimIndir = lerp(rimIndir, rimIndir * fd.shadowmix, saturate(_RimShadowMask));

    #if defined(LTSKKS_RENDER_TRANSPARENT) || defined(LTSKKS_RENDER_ONEPASS_TRANSPARENT) || defined(LTSKKS_RENDER_TWOPASS_TRANSPARENT)
        if(_RimApplyTransparency > 0.5)
        {
            rimDir *= fd.col.a;
            rimIndir *= fd.col.a;
        }
    #endif

    #if defined(LTSKKS_PASS_FORWARDADD)
        float3 rimLight = (_RimBlendMode < 3.0) ? fd.lightColor * saturate(_RimEnableLighting) : float3(1.0, 1.0, 1.0);
    #else
        float3 rimLight = lerp(float3(1.0, 1.0, 1.0), fd.lightColor, saturate(_RimEnableLighting));
    #endif

    fd.col.rgb = LTSKKS_BlendColor(fd.col.rgb, rimColor.rgb * rimLight, rimDir * rimColor.a, _RimBlendMode);
    fd.col.rgb = LTSKKS_BlendColor(fd.col.rgb, rimIndirColor.rgb * rimLight, rimIndir * rimIndirColor.a, _RimBlendMode);
}

#endif

