#ifndef LTSKKS_COMMON_INCLUDED
#define LTSKKS_COMMON_INCLUDED

#define LTSKKS_PI 3.14159265359
#define LTSKKS_EPS 1e-5

float LTSKKS_TooningNoSaturate(float value, float border, float blur)
{
    float width = max(blur, 0.0001);
    float borderMin = saturate(border - width * 0.5);
    float borderMax = saturate(border + width * 0.5);
    return (value - borderMin) / max(borderMax - borderMin, 0.0001);
}

float LTSKKS_Tooning(float value, float border, float blur)
{
    return saturate(LTSKKS_TooningNoSaturate(value, border, blur));
}

float2 LTSKKS_RotateUV(float2 uv, float angle)
{
    float s = sin(angle);
    float c = cos(angle);
    uv -= 0.5;
    uv = float2(uv.x * c - uv.y * s, uv.x * s + uv.y * c);
    return uv + 0.5;
}

float2 LTSKKS_CalcUV(float2 uv, float4 st)
{
    return uv * st.xy + st.zw;
}

float2 LTSKKS_CalcUV(float2 uv, float4 st, float4 scrollRotate)
{
    float2 outUV = uv * st.xy + st.zw;
    outUV = LTSKKS_RotateUV(outUV, scrollRotate.z + scrollRotate.w * _Time.y);
    return outUV + frac(scrollRotate.xy * _Time.y);
}

float2 LTSKKS_CalcDoubleSideUV(float2 uv, float facing, float shiftBackfaceUV)
{
    return facing < (shiftBackfaceUV - 1.0) ? uv + float2(1.0, 0.0) : uv;
}

float2 LTSKKS_CalcMainUV(float2 uv0, float facing, float shiftBackfaceUV, float4 st, float4 scrollRotate)
{
    return LTSKKS_CalcUV(LTSKKS_CalcDoubleSideUV(uv0, facing, shiftBackfaceUV), st, scrollRotate);
}

float2 LTSKKS_CalcDecalUV(float2 uv, float4 st, float4 scrollRotate, float isLeftOnly, float isRightOnly, float shouldCopy, float shouldFlipMirror, float shouldFlipCopy)
{
    bool isRightHand = uv.x > 0.5;
    float2 outUV = uv;
    if(shouldCopy > 0.5) outUV.x = abs(outUV.x - 0.5) + 0.5;

    float4 animatedST = st + float4(0.0, 0.0, scrollRotate.xy) * _Time.y;
    outUV = outUV * animatedST.xy + animatedST.zw;

    if(shouldFlipCopy > 0.5 && uv.x < 0.5) outUV.x = 1.0 - outUV.x;
    if(shouldFlipMirror > 0.5 && isRightHand) outUV.x = 1.0 - outUV.x;
    if(isLeftOnly > 0.5 && isRightHand) outUV.x = -1.0;
    if(isRightOnly > 0.5 && !isRightHand) outUV.x = -1.0;

    float2 safeScale = lerp(animatedST.xy, float2(LTSKKS_EPS, LTSKKS_EPS), step(abs(animatedST.xy), float2(LTSKKS_EPS, LTSKKS_EPS)));
    outUV = (outUV - animatedST.zw) / safeScale;
    outUV = LTSKKS_RotateUV(outUV, scrollRotate.z + scrollRotate.w * _Time.y);
    return outUV * animatedST.xy + animatedST.zw;
}

float LTSKKS_DecalUVAlpha(float2 uv, float isDecal)
{
    float inRange = step(0.0, uv.x) * step(0.0, uv.y) * step(uv.x, 1.0) * step(uv.y, 1.0);
    return lerp(1.0, inRange, saturate(isDecal));
}

float LTSKKS_Median(float r, float g, float b)
{
    return max(min(r, g), min(max(r, g), b));
}

float LTSKKS_MSDF(float3 msd)
{
    float sd = LTSKKS_Median(msd.r, msd.g, msd.b);
    return saturate((sd - 0.5) / clamp(fwidth(sd), 0.01, 1.0));
}

float4 LTSKKS_ApplyMSDF(float4 color, float enabled)
{
    return (enabled > 0.5) ? float4(1.0, 1.0, 1.0, LTSKKS_MSDF(color.rgb)) : color;
}

float2 LTSKKS_CalcAtlasAnimationUV(float2 uv, float4 decalAnimation, float4 decalSubParam)
{
    float columns = max(decalAnimation.x, 1.0);
    float rows = max(decalAnimation.y, 1.0);
    float frameCount = max(decalAnimation.z, 1.0);
    float animTime = (abs(decalAnimation.w) < LTSKKS_EPS) ? decalAnimation.z : fmod(floor(_Time.y * decalAnimation.w), frameCount);
    float offsetX = fmod(animTime, columns);
    float offsetY = floor(animTime / columns);
    float2 outUV = lerp(float2(uv.x, 1.0 - uv.y), 0.5, decalSubParam.z);
    outUV = (outUV + float2(offsetX, offsetY)) * decalSubParam.xy / float2(columns, rows);
    outUV.y = 1.0 - outUV.y;
    return outUV;
}

float3 LTSKKS_BlendColor(float3 dst, float3 src, float alpha, float mode)
{
    alpha = saturate(alpha);
    float3 normal = lerp(dst, src, alpha);
    float3 add = dst + src * alpha;
    float3 screen = 1.0 - (1.0 - dst) * (1.0 - src * alpha);
    float3 multiply = lerp(dst, dst * src, alpha);
    float3 overlay = lerp(2.0 * dst * src, 1.0 - 2.0 * (1.0 - dst) * (1.0 - src), step(0.5, dst));
    overlay = lerp(dst, overlay, alpha);

    float3 outCol = normal;
    outCol = (mode > 0.5 && mode < 1.5) ? add : outCol;
    outCol = (mode >= 1.5 && mode < 2.5) ? screen : outCol;
    outCol = (mode >= 2.5 && mode < 3.5) ? multiply : outCol;
    outCol = (mode >= 3.5 && mode < 4.5) ? overlay : outCol;
    return outCol;
}

float3 LTSKKS_BlendColorMask(float3 dst, float3 src, float3 alpha, float mode)
{
    alpha = saturate(alpha);
    float3 normal = lerp(dst, src, alpha);
    float3 add = dst + src * alpha;
    float3 screen = 1.0 - (1.0 - dst) * (1.0 - src * alpha);
    float3 multiply = lerp(dst, dst * src, alpha);
    float3 overlay = lerp(2.0 * dst * src, 1.0 - 2.0 * (1.0 - dst) * (1.0 - src), step(0.5, dst));
    overlay = lerp(dst, overlay, alpha);

    float3 outCol = normal;
    outCol = (mode > 0.5 && mode < 1.5) ? add : outCol;
    outCol = (mode >= 1.5 && mode < 2.5) ? screen : outCol;
    outCol = (mode >= 2.5 && mode < 3.5) ? multiply : outCol;
    outCol = (mode >= 3.5 && mode < 4.5) ? overlay : outCol;
    return outCol;
}

float LTSKKS_ApplyLayerDistanceFade(float alpha, float depth, float4 distanceFade)
{
    float fade = saturate((depth - distanceFade.x) / max(distanceFade.y - distanceFade.x, LTSKKS_EPS));
    return lerp(alpha, alpha * fade, saturate(distanceFade.z));
}

float3 LTSKKS_RGBToHSV(float3 c)
{
    float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    float4 p = lerp(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
    float4 q = lerp(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));
    float d = q.x - min(q.w, q.y);
    return float3(abs(q.z + (q.w - q.y) / (6.0 * d + LTSKKS_EPS)), d / (q.x + LTSKKS_EPS), q.x);
}

float3 LTSKKS_HSVToRGB(float3 hsv)
{
    float3 rgb = saturate(abs(frac(hsv.x + float3(0.0, 2.0 / 3.0, 1.0 / 3.0)) * 6.0 - 3.0) - 1.0);
    return hsv.z * lerp(float3(1.0, 1.0, 1.0), rgb, hsv.y);
}

float3 LTSKKS_ToneCorrection(float3 color, float4 hsvg)
{
    float3 hsv = LTSKKS_RGBToHSV(color);
    hsv.x = frac(hsv.x + hsvg.x);
    hsv.y = saturate(hsv.y * hsvg.y);
    hsv.z = saturate(hsv.z * hsvg.z);
    return lerp(color, LTSKKS_HSVToRGB(hsv), saturate(hsvg.w));
}

float3 LTSKKS_UnpackNormalScale(float4 packedNormal, float scale)
{
    float3 normal = UnpackNormal(packedNormal);
    normal.xy *= scale;
    normal.z = sqrt(saturate(1.0 - dot(normal.xy, normal.xy)));
    return normal;
}

float3 LTSKKS_BlendNormal(float3 dstNormal, float3 srcNormal)
{
    return normalize(float3(dstNormal.xy + srcNormal.xy, dstNormal.z * srcNormal.z));
}

float3 LTSKKS_MatCapUV(float3 normalWS)
{
    float3 viewNormal = mul((float3x3)UNITY_MATRIX_V, normalWS);
    return viewNormal * 0.5 + 0.5;
}

float3 LTSKKS_OrthoNormalize(float3 tangent, float3 normal)
{
    return normalize(tangent - normal * dot(normal, tangent));
}

float2 LTSKKS_CalcMatCapUV(float2 uv1, float3 normalWS, float3 viewDirection, float4 matcapST, float2 matcapBlendUV1, float zRotCancel, float matcapPerspective, float matcapVRParallaxStrength)
{
    float3 normalVD = normalize(lerp(normalize(UNITY_MATRIX_V._m20_m21_m22), normalize(viewDirection), saturate(matcapPerspective * matcapVRParallaxStrength)));
    float3 bitangentVD = (zRotCancel > 0.5) ? float3(0.0, 1.0, 0.0) : normalize(UNITY_MATRIX_V._m10_m11_m12);
    bitangentVD = LTSKKS_OrthoNormalize(bitangentVD, normalVD);
    float3 tangentVD = normalize(cross(normalVD, bitangentVD));
    float3x3 tbnVD = float3x3(tangentVD, bitangentVD, normalVD);
    float2 uvMat = mul(tbnVD, normalWS).xy;
    uvMat = lerp(uvMat, saturate(uv1) * 2.0 - 1.0, matcapBlendUV1);
    uvMat = uvMat * matcapST.xy + matcapST.zw;
    return uvMat * 0.5 + 0.5;
}

#endif


