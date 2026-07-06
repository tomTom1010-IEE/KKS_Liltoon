#ifndef LTSKKS_PIPELINE_INCLUDED
#define LTSKKS_PIPELINE_INCLUDED

float3 LTSKKS_GetLightDirection(float3 posWS)
{
    float3 lightVector = _WorldSpaceLightPos0.xyz - posWS * _WorldSpaceLightPos0.w;
    return normalize(lightVector);
}

float3 LTSKKS_GetLightColor(float attenuation)
{
    float3 lightColor = _LightColor0.rgb * attenuation * _lilDirectionalLightStrength;
    lightColor = min(max(lightColor, float3(_LightMinLimit, _LightMinLimit, _LightMinLimit)), float3(_LightMaxLimit, _LightMaxLimit, _LightMaxLimit));
    float gray = dot(lightColor, float3(0.299, 0.587, 0.114));
    lightColor = lerp(lightColor, float3(gray, gray, gray), saturate(_MonochromeLighting));
    return lerp(lightColor, 1.0, saturate(_AsUnlit));
}

float3 LTSKKS_GetIndirectLight(float3 normalWS)
{
    float3 sh = ShadeSH9(float4(normalWS, 1.0));
    return max(sh, 0.0);
}

void LTSKKS_PrepareLighting(inout LTSKKSFragData fd, LTSKKSV2F i)
{
    fd.V = normalize(_WorldSpaceCameraPos.xyz - fd.posWS);
    fd.L = LTSKKS_GetLightDirection(fd.posWS);
    fd.origL = fd.L;
    fd.H = normalize(fd.L + fd.V);
    fd.ln = dot(fd.N, fd.L);
    fd.nv = saturate(dot(fd.N, fd.V));
    fd.nvabs = abs(dot(fd.N, fd.V));

    UNITY_LIGHT_ATTENUATION(attenuation, i, fd.posWS);
    fd.attenuation = attenuation;
    fd.lightColor = LTSKKS_GetLightColor(attenuation);
    fd.indLightColor = LTSKKS_GetIndirectLight(fd.N);
    fd.addLightColor = 0.0;

    #if defined(LTSKKS_PASS_FORWARDADD)
        fd.indLightColor = 0.0;
    #endif
}

#endif
