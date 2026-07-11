#ifndef LTSKKS_PIPELINE_INCLUDED
#define LTSKKS_PIPELINE_INCLUDED

float3 LTSKKS_GetLightDirection(float3 posWS)
{
    float3 lightVector = _WorldSpaceLightPos0.xyz - posWS * _WorldSpaceLightPos0.w;
    return normalize(lightVector);
}

float3 LTSKKS_ApplyLightColorOptions(float3 lightColor);

float3 LTSKKS_GetLightColor(float attenuation)
{
    float3 lightColor = _LightColor0.rgb * attenuation * _lilDirectionalLightStrength;
    return LTSKKS_ApplyLightColorOptions(lightColor);
}

float3 LTSKKS_ApplyLightColorOptions(float3 lightColor)
{
    lightColor = min(max(lightColor, float3(_LightMinLimit, _LightMinLimit, _LightMinLimit)), float3(_LightMaxLimit, _LightMaxLimit, _LightMaxLimit));
    float gray = dot(lightColor, float3(0.299, 0.587, 0.114));
    lightColor = lerp(lightColor, float3(gray, gray, gray), saturate(_MonochromeLighting));
    return lerp(lightColor, 1.0, saturate(_AsUnlit));
}

float3 LTSKKS_GetVertexLightColor(float3 posWS)
{
    float3 vertexLight = 0.0;
    #if defined(LIGHTPROBE_SH) && defined(VERTEXLIGHT_ON)
        float4 toLightX = unity_4LightPosX0 - posWS.x;
        float4 toLightY = unity_4LightPosY0 - posWS.y;
        float4 toLightZ = unity_4LightPosZ0 - posWS.z;
        float4 lengthSq = toLightX * toLightX + toLightY * toLightY + toLightZ * toLightZ + 0.000001;
        float4 atten = saturate(saturate((25.0 - lengthSq * unity_4LightAtten0) * 0.111375) / (0.987725 + lengthSq * unity_4LightAtten0)) * saturate(_VertexLightStrength);

        vertexLight += unity_LightColor[0].rgb * atten.x;
        vertexLight += unity_LightColor[1].rgb * atten.y;
        vertexLight += unity_LightColor[2].rgb * atten.z;
        vertexLight += unity_LightColor[3].rgb * atten.w;
    #endif
    return vertexLight;
}

float3 LTSKKS_GetIndirectLight(float3 normalWS)
{
    float3 sh = ShadeSH9(float4(normalWS, 1.0));
    return max(sh, 0.0);
}

void LTSKKS_PrepareSurfaceBasis(inout LTSKKSFragData fd, LTSKKSV2F i)
{
    fd.origN = normalize(i.normalWS);
    fd.T = normalize(i.tangentWS.xyz);
    fd.B = normalize(i.bitangentWS);
    fd.V = normalize(_WorldSpaceCameraPos.xyz - fd.posWS);
    fd.parallaxViewDirection = float3(dot(fd.T, fd.V), dot(fd.B, fd.V), dot(fd.origN, fd.V));
    fd.parallaxOffset = fd.parallaxViewDirection.xy / max(fd.parallaxViewDirection.z + 0.5, 0.0001);
}

void LTSKKS_PrepareLighting(inout LTSKKSFragData fd, LTSKKSV2F i)
{
    fd.L = LTSKKS_GetLightDirection(fd.posWS);
    fd.origL = fd.L;
    fd.H = normalize(fd.L + fd.V);
    fd.ln = dot(fd.N, fd.L);
    fd.nv = saturate(dot(fd.N, fd.V));
    fd.nvabs = abs(dot(fd.N, fd.V));

    UNITY_LIGHT_ATTENUATION(attenuation, i, fd.posWS);
    fd.attenuation = attenuation;
    float3 lightColor = _LightColor0.rgb * attenuation * _lilDirectionalLightStrength;
    #if !defined(LTSKKS_PASS_FORWARDADD)
        lightColor += i.vertexLightColor;
    #endif
    fd.lightColor = LTSKKS_ApplyLightColorOptions(lightColor);
    fd.indLightColor = LTSKKS_GetIndirectLight(fd.N);
    fd.addLightColor = 0.0;

    #if defined(LTSKKS_PASS_FORWARDADD)
        fd.indLightColor = 0.0;
    #endif
}

#endif
