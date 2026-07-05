#ifndef LTSKKS_SHADOW_INCLUDED
#define LTSKKS_SHADOW_INCLUDED

float LTSKKS_TooningNoSaturateAAScale(float value, float border, float blur)
{
    float aa = fwidth(value) * saturate(_AAStrength);
    return LTSKKS_TooningNoSaturate(value, border, max(blur, aa));
}

float LTSKKS_TooningNoSaturateAAScaleCustomAA(float value, float border, float blur, float aaStrength)
{
    float aa = fwidth(value) * saturate(aaStrength);
    return LTSKKS_TooningNoSaturate(value, border, max(blur, aa));
}

float LTSKKS_TooningNoSaturateAAScale(float value, float border, float blur, float borderRange)
{
    float borderMix = LTSKKS_TooningNoSaturateAAScale(value, border, blur);
    float edge = saturate(abs(value - border) / max(borderRange, 0.0001));
    return borderMix * edge;
}

float LTSKKS_TooningNoSaturateAAScaleCustomAA(float value, float border, float blur, float borderRange, float aaStrength)
{
    float borderMix = LTSKKS_TooningNoSaturateAAScaleCustomAA(value, border, blur, aaStrength);
    float edge = saturate(abs(value - border) / max(borderRange, 0.0001));
    return borderMix * edge;
}

float LTSKKS_TooningAAScale(float value, float border, float blur)
{
    return saturate(LTSKKS_TooningNoSaturateAAScale(value, border, blur));
}

float LTSKKS_TooningAAScale(float value, float border, float blur, float borderRange)
{
    return saturate(LTSKKS_TooningNoSaturateAAScale(value, border, blur, borderRange));
}

float3 LTSKKS_GetShadowColor(float3 albedo, float4 colorTex, float4 shadowColor)
{
    return lerp(albedo, colorTex.rgb, colorTex.a) * shadowColor.rgb;
}

void LTSKKS_GetShadowLUTUV(float3 albedo, out float4 uv, out float factor)
{
    #if !defined(UNITY_COLORSPACE_GAMMA)
        albedo = LinearToGammaSpace(albedo);
    #endif
    float3 res = float3(16.0, 1.0, 16.0);
    float3 resInv = float3(1.0, -1.0, 1.0) / res;
    float3 col = (albedo - albedo * resInv.z) + 0.5 * resInv.z;
    float4 slice = saturate(col.b + resInv.z * float2(-0.5, 0.5)).xxyy * res.zyzy;
    float4 sliceFloor = floor(slice);
    uv = float4(0.0, 1.0, 0.0, 1.0) + (col.rgrg + sliceFloor) * resInv.xyxy;
    factor = abs(slice.x - sliceFloor.x);
}

float4 LTSKKS_SampleShadowColorTex1st(float3 albedo, float2 uvMain)
{
    float4 lutUV = 0.0;
    float factor = 0.0;
    LTSKKS_GetShadowLUTUV(albedo, lutUV, factor);
    float4 normalColor = LTSKKS_SAMPLE_TEX(_ShadowColorTex, uvMain);
    float4 lutColor = lerp(LTSKKS_SAMPLE_TEX(_ShadowColorTex, lutUV.xy), LTSKKS_SAMPLE_TEX(_ShadowColorTex, lutUV.zw), factor);
    return lerp(normalColor, lutColor, step(0.5, _ShadowColorType) * step(_ShadowColorType, 1.5));
}

float4 LTSKKS_SampleShadowColorTex2nd(float3 albedo, float2 uvMain)
{
    float4 lutUV = 0.0;
    float factor = 0.0;
    LTSKKS_GetShadowLUTUV(albedo, lutUV, factor);
    float4 normalColor = LTSKKS_SAMPLE_TEX(_Shadow2ndColorTex, uvMain);
    float4 lutColor = lerp(LTSKKS_SAMPLE_TEX(_Shadow2ndColorTex, lutUV.xy), LTSKKS_SAMPLE_TEX(_Shadow2ndColorTex, lutUV.zw), factor);
    return lerp(normalColor, lutColor, step(0.5, _ShadowColorType) * step(_ShadowColorType, 1.5));
}

float4 LTSKKS_SampleShadowColorTex3rd(float3 albedo, float2 uvMain)
{
    float4 lutUV = 0.0;
    float factor = 0.0;
    LTSKKS_GetShadowLUTUV(albedo, lutUV, factor);
    float4 normalColor = LTSKKS_SAMPLE_TEX(_Shadow3rdColorTex, uvMain);
    float4 lutColor = lerp(LTSKKS_SAMPLE_TEX(_Shadow3rdColorTex, lutUV.xy), LTSKKS_SAMPLE_TEX(_Shadow3rdColorTex, lutUV.zw), factor);
    return lerp(normalColor, lutColor, step(0.5, _ShadowColorType) * step(_ShadowColorType, 1.5));
}

void LTSKKS_ApplyShadow(inout LTSKKSFragData fd)
{
    if(_UseShadow < 0.5)
    {
        fd.col.rgb *= fd.lightColor;
        fd.shadowmix = 1.0;
        return;
    }

    float3 n1 = normalize(lerp(fd.origN, fd.N, saturate(_ShadowNormalStrength)));
    float3 n2 = normalize(lerp(fd.origN, fd.N, saturate(_Shadow2ndNormalStrength)));
    float3 n3 = normalize(lerp(fd.origN, fd.N, saturate(_Shadow3rdNormalStrength)));

    float4 strengthMask = LTSKKS_SAMPLE_TEX(_ShadowStrengthMask, fd.uvMain);
    float4 borderMask = LTSKKS_SAMPLE_TEX(_ShadowBorderMask, fd.uvMain);
    float4 blurMask = LTSKKS_SAMPLE_TEX(_ShadowBlurMask, fd.uvMain);
    float shadowAAStrength = saturate(_AAStrength);

    float4 lns = 1.0;
    lns.x = saturate(dot(fd.L, n1) * 0.5 + 0.5);
    lns.y = saturate(dot(fd.L, n2) * 0.5 + 0.5);
    lns.z = saturate(dot(fd.L, n3) * 0.5 + 0.5);

    if(_ShadowMaskType >= 1.5 && _ShadowMaskType < 2.5)
    {
        float3 faceR = mul((float3x3)unity_ObjectToWorld, float3(-1.0, 0.0, 0.0));
        float sdf = (dot(fd.L.xz, faceR.xz) < 0.0) ? strengthMask.g : strengthMask.r;

        float3 faceF = mul((float3x3)unity_ObjectToWorld, float3(0.0, 0.0, 1.0));
        faceF.y *= _ShadowFlatBlur;
        faceF = (dot(faceF, faceF) < LTSKKS_EPS) ? 0.0 : normalize(faceF);
        float3 faceL = fd.L;
        faceL.y *= _ShadowFlatBlur;
        faceL = (dot(faceL, faceL) < LTSKKS_EPS) ? 0.0 : normalize(faceL);

        float lnSDF = dot(faceL, faceF);
        float sdfMix = saturate(lnSDF * 0.5 + sdf * 0.5 + 0.25);
        lns = lerp(float4(sdfMix, sdfMix, sdfMix, sdfMix), lns, strengthMask.b);
        shadowAAStrength = 0.0;
        strengthMask.r = strengthMask.a;
    }

    float calculatedShadow = saturate(fd.attenuation);
    lns.x *= lerp(1.0, calculatedShadow, saturate(_ShadowReceive));
    lns.y *= lerp(1.0, calculatedShadow, saturate(_Shadow2ndReceive));
    lns.z *= lerp(1.0, calculatedShadow, saturate(_Shadow3rdReceive));

    borderMask.r = saturate(borderMask.r * _ShadowAOShift.x + _ShadowAOShift.y);
    borderMask.g = saturate(borderMask.g * _ShadowAOShift.z + _ShadowAOShift.w);
    borderMask.b = saturate(borderMask.b * _ShadowAOShift2.x + _ShadowAOShift2.y);
    float4 aoMask = float4(borderMask.rgb, borderMask.r);

    if(_ShadowPostAO < 0.5)
    {
        lns.xyz *= aoMask.rgb;
    }

    float shadowBlur = max(_ShadowBlur * blurMask.r, 0.0001);
    float shadow2ndBlur = max(_Shadow2ndBlur * blurMask.g, 0.0001);
    float shadow3rdBlur = max(_Shadow3rdBlur * blurMask.b, 0.0001);

    lns.w = lns.x;
    lns.x = LTSKKS_TooningNoSaturateAAScaleCustomAA(lns.x, _ShadowBorder, shadowBlur, shadowAAStrength);
    lns.y = LTSKKS_TooningNoSaturateAAScaleCustomAA(lns.y, _Shadow2ndBorder, shadow2ndBlur, shadowAAStrength);
    lns.z = LTSKKS_TooningNoSaturateAAScaleCustomAA(lns.z, _Shadow3rdBorder, shadow3rdBlur, shadowAAStrength);
    lns.w = LTSKKS_TooningNoSaturateAAScaleCustomAA(lns.w, _ShadowBorder, shadowBlur, _ShadowBorderRange, shadowAAStrength);

    if(_ShadowPostAO > 0.5)
    {
        lns *= aoMask.rgbr;
    }
    lns = saturate(lns);

    float bfshadow = (fd.facing < 0.0) ? 1.0 - saturate(_BackfaceForceShadow) : 1.0;
    lns *= bfshadow;

    float shadowStrength = saturate(_ShadowStrength);
    #if defined(UNITY_COLORSPACE_GAMMA)
        shadowStrength = pow(max(shadowStrength, 0.0), 2.2);
    #endif
    if(_ShadowMaskType > 0.5 && _ShadowMaskType < 1.5)
    {
        float3 flatN = normalize(mul((float3x3)unity_ObjectToWorld, float3(0.0, 0.25, 1.0)));
        float lnFlat = saturate((dot(flatN, fd.L) + _ShadowFlatBorder) / max(_ShadowFlatBlur, 0.0001));
        lnFlat *= lerp(1.0, calculatedShadow, saturate(_ShadowReceive));
        lns = lerp(float4(lnFlat, lnFlat, lnFlat, lnFlat), lns, strengthMask.r);
    }
    else shadowStrength *= strengthMask.r;
    lns.x = lerp(1.0, lns.x, shadowStrength);

    fd.shadowmix = lns.x;

    float4 shadowColorTex = LTSKKS_SampleShadowColorTex1st(fd.albedo, fd.uvMain);
    float4 shadow2ndColorTex = LTSKKS_SampleShadowColorTex2nd(fd.albedo, fd.uvMain);
    float4 shadow3rdColorTex = LTSKKS_SampleShadowColorTex3rd(fd.albedo, fd.uvMain);

    float3 indirectCol = LTSKKS_GetShadowColor(fd.albedo, shadowColorTex, _ShadowColor);

    float3 shadow2 = LTSKKS_GetShadowColor(fd.albedo, shadow2ndColorTex, _Shadow2ndColor);
    float shadow2Weight = saturate(_Shadow2ndColor.a - lns.y * _Shadow2ndColor.a);
    indirectCol = lerp(indirectCol, shadow2, shadow2Weight);

    float3 shadow3 = LTSKKS_GetShadowColor(fd.albedo, shadow3rdColorTex, _Shadow3rdColor);
    float shadow3Weight = saturate(_Shadow3rdColor.a - lns.z * _Shadow3rdColor.a);
    indirectCol = lerp(indirectCol, shadow3, shadow3Weight);

    indirectCol = lerp(indirectCol, indirectCol * fd.albedo, saturate(_ShadowMainStrength));

    float3 directCol = fd.albedo * fd.lightColor;
    indirectCol *= fd.lightColor;

    #if !defined(LTSKKS_PASS_FORWARDADD)
        indirectCol = lerp(indirectCol, fd.albedo, saturate(fd.indLightColor * _ShadowEnvStrength));
    #endif

    indirectCol = min(indirectCol, directCol);
    indirectCol = lerp(indirectCol, directCol, saturate(lns.w) * _ShadowBorderColor.rgb);
    fd.col.rgb = lerp(indirectCol, directCol, saturate(lns.x));
}

void LTSKKS_ApplyRimShade(inout LTSKKSFragData fd)
{
    if(_UseRimShade < 0.5) return;
    float3 rimN = normalize(lerp(fd.origN, fd.N, saturate(_RimShadeNormalStrength)));
    float nvabs = abs(dot(rimN, fd.V));
    float rim = pow(saturate(1.0 - nvabs), max(_RimShadeFresnelPower, 0.01));
    rim = LTSKKS_TooningAAScale(rim, _RimShadeBorder, _RimShadeBlur);
    rim *= LTSKKS_SAMPLE_TEX(_RimShadeMask, fd.uvMain).r;
    fd.col.rgb = lerp(fd.col.rgb, fd.col.rgb * _RimShadeColor.rgb, rim * _RimShadeColor.a);
}

void LTSKKS_ApplyBacklight(inout LTSKKSFragData fd)
{
    if(_UseBacklight < 0.5) return;
    float3 backN = normalize(lerp(fd.origN, fd.N, saturate(_BacklightNormalStrength)));
    float back = saturate(dot(-fd.L, backN) * 0.5 + 0.5);
    back = LTSKKS_TooningAAScale(back, _BacklightBorder, _BacklightBlur);
    float3 color = _BacklightColor.rgb * LTSKKS_SAMPLE_TEX(_BacklightColorTex, fd.uvMain).rgb;
    float receive = lerp(1.0, fd.shadowmix, _BacklightReceiveShadow);
    fd.col.rgb += back * _BacklightColor.a * color * fd.lightColor * receive;
}

#endif
