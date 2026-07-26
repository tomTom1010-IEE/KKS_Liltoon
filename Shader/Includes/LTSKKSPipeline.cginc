#ifndef LTSKKS_PIPELINE_INCLUDED
#define LTSKKS_PIPELINE_INCLUDED

#include "LTSKKSOpenLit.cginc"

float3 LTSKKS_GetVertexLightColor(float3 posWS)
{
    #if !defined(LTSKKS_PASS_FORWARDADD) && UNITY_SHOULD_SAMPLE_SH
        return LTSKKS_OpenLitComputeAdditionalLights(posWS) * saturate(_VertexLightStrength);
    #else
        return 0.0;
    #endif
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
    UNITY_LIGHT_ATTENUATION(attenuation, i, fd.posWS);
    fd.attenuation = attenuation;
    fd.addLightColor = 0.0;

    #if defined(LTSKKS_PASS_FORWARDADD)
        fd.origL = normalize(UnityWorldSpaceLightDir(fd.posWS));
        fd.L = fd.origL;
        fd.lightColor = LTSKKS_OpenLitCorrectAdditionalLight(
            _LightColor0.rgb * attenuation,
            _LightMaxLimit,
            _MonochromeLighting,
            _AsUnlit);
        fd.indLightColor = 0.0;
    #else
        LTSKKSOpenLitLightData lightData;
        LTSKKS_OpenLitComputeLights(
            lightData,
            _LightDirectionOverride,
            fd.posWS,
            _lilDirectionalLightStrength);
        lightData.directLight += i.vertexLightColor;
        LTSKKS_OpenLitCorrectBaseLights(
            lightData,
            _LightMinLimit,
            _LightMaxLimit,
            _MonochromeLighting,
            _AsUnlit);

        fd.origL = normalize(UnityWorldSpaceLightDir(fd.posWS));
        fd.L = lightData.lightDirection;
        fd.lightColor = lightData.directLight;
        fd.indLightColor = lightData.indirectLight;
    #endif

    fd.H = normalize(fd.L + fd.V);
    fd.ln = dot(fd.N, fd.L);
    fd.nv = saturate(dot(fd.N, fd.V));
    fd.nvabs = abs(dot(fd.N, fd.V));
    fd.invLighting = saturate((1.0 - fd.lightColor) * sqrt(max(fd.lightColor, 0.0)));
}

#endif
