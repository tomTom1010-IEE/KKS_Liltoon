#ifndef LTSKKS_KKS_SKIN_INCLUDED
#define LTSKKS_KKS_SKIN_INCLUDED

float3 LTSKKS_ApplyKKSSkinMainColor(LTSKKSFragData fd, float3 mainColor)
{
    float2 colorUV = LTSKKS_CalcUV(fd.uv0, _ColMask_ST);
    float4 colorMask = UNITY_SAMPLE_TEX2D(_ColMask, colorUV);
    float3 color0 = max(_Col0.rgb, 1e-6);
    float3 color1 = max(_Col1.rgb, 1e-6);
    float3 color2 = max(_Col2.rgb, 1e-6);
    float3 color3 = max(_Col3.rgb, 1e-6);
    float3 skinTint = lerp(color0, color1, colorMask.r);
    skinTint = lerp(skinTint, color2, colorMask.g);
    skinTint = lerp(skinTint, color3, colorMask.b);
    mainColor *= skinTint;

    // Preserve the KKS body/face UV conventions used by SkinPlus.
    float2 centeredUV1 = fd.uv1 - 0.5;
    float uvLength = saturate(length(centeredUV1) * 16.6666698 - 1.0);
    float2 nippleScale = _nipsize * float2(-1.4, 0.7) + float2(2.0, -0.5);
    float2 nippleUV = fd.uv1 * nippleScale.xx + nippleScale.yy;
    nippleUV = uvLength * (nippleUV - fd.uv1) + fd.uv1;
    float2 nippleMaskUV = fd.uv1 * fd.vertexColor.x;
    nippleUV = nippleUV * fd.vertexColor.x - nippleMaskUV;
    float2 over1UV = LTSKKS_CalcUV(_nip * nippleUV + nippleMaskUV, _overtex1_ST);
    float4 over1 = UNITY_SAMPLE_TEX2D(_overtex1, over1UV);
    float4 over1Color = over1 * _overcolor1;
    float3 over1SpecColor = over1.g * _nip_specular * 0.33 + _overcolor1.rgb;
    float3 over1Adjusted = over1.r * over1SpecColor - over1Color.rgb;
    over1Adjusted = saturate(_tex1mask) * over1Adjusted + over1Color.rgb;
    float3 result = lerp(mainColor, over1Adjusted, over1Color.a);

    float2 over2UV = LTSKKS_CalcUV(fd.uv2 * fd.vertexColor.b, _overtex2_ST);
    float4 over2 = UNITY_SAMPLE_TEX2D(_overtex2, over2UV);
    result = lerp(result, over2.rgb * _overcolor2.rgb, over2.a * _overcolor2.a);

    float2 over3UV = LTSKKS_CalcUV(fd.uv3, _overtex3_ST);
    float4 over3 = UNITY_SAMPLE_TEX2D(_overtex3, over3UV);
    result = lerp(result, over3.rgb * _overcolor3.rgb, over3.a * _overcolor3.a);
    return result;
}

#endif
