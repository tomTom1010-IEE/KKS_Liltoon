#ifndef LTSKKS_RIM_INCLUDED
#define LTSKKS_RIM_INCLUDED

void LTSKKS_ApplyRim(inout LTSKKSFragData fd)
{
    if(_UseRim < 0.5) return;
    float rim = pow(saturate(1.0 - fd.nvabs), max(_RimFresnelPower, 0.01));
    rim = LTSKKS_Tooning(rim, _RimBorder, _RimBlur);
    rim *= lerp(1.0, fd.shadowmix, saturate(_RimShadowMask));
    float4 rimColor = _RimColor * LTSKKS_SAMPLE_TEX(_RimColorTex, fd.uvMain);
    float3 rimLight = lerp(float3(1.0, 1.0, 1.0), fd.lightColor, saturate(_RimEnableLighting));
    fd.col.rgb = LTSKKS_BlendColor(fd.col.rgb, rimColor.rgb * rimLight, rim * rimColor.a, _RimBlendMode);
}

#endif

