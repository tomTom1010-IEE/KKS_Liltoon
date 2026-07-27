#ifndef LTSKKS_LIQUID_OVERLAY_INCLUDED
#define LTSKKS_LIQUID_OVERLAY_INCLUDED

#include "UnityCG.cginc"
#include "Lighting.cginc"
#include "AutoLight.cginc"
#include "UnityPBSLighting.cginc"
#include "LTSKKSCommon.cginc"
#include "LTSKKSOpenLit.cginc"
#include "LTSKKSLiquidCore.cginc"

sampler2D _Texture2;
sampler2D _Texture3;
sampler2D _liquidmask;
sampler2D _BaseNormalMap;
samplerCUBE _LiquidReflectionCubeTex;

float4 _Texture2_ST;
float4 _Texture3_ST;
float4 _liquidmask_ST;
float4 _BaseNormalMap_ST;
float4 _LiquidReflectionCubeTex_HDR;

float4 _LiquidTiling;
float _liquidftop;
float _liquidfbot;
float _liquidbtop;
float _liquidbbot;
float _liquidface;

float4 _LiquidColor;
float _LiquidOpacity;
float _LiquidNormalScale;
float _LiquidSmoothness;
float _LiquidReflectance;
float _LiquidSpecularStrength;
float _LiquidReflectionStrength;
float _LiquidFresnelStrength;
float _LiquidFresnelPower;
float _LiquidReceiveShadow;
float _LiquidEnableLighting;
float _LiquidCutoff;
float _LiquidApplySpecularFA;

float _UseBaseNormalMap;
float _BaseNormalScale;

float4 _LiquidReflectionCubeColor;
float _LiquidReflectionCubeOverride;
float _LiquidReflectionCubeEnableLighting;

float _AsUnlit;
float _VertexLightStrength;
float _LightMinLimit;
float _LightMaxLimit;
float _MonochromeLighting;
float _lilDirectionalLightStrength;
float4 _LightDirectionOverride;
float _BeforeExposureLimit;

struct LTSKKSLiquidAppData
{
    float4 vertex : POSITION;
    float3 normal : NORMAL;
    float4 tangent : TANGENT;
    float4 texcoord : TEXCOORD0;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct LTSKKSLiquidV2F
{
    float4 pos : SV_POSITION;
    float2 uv : TEXCOORD0;
    float3 posWS : TEXCOORD1;
    float3 normalWS : TEXCOORD2;
    float4 tangentWS : TEXCOORD3;
    float3 vertexLightColor : TEXCOORD4;
    SHADOW_COORDS(5)
    UNITY_FOG_COORDS(6)
    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

LTSKKSLiquidV2F vert(LTSKKSLiquidAppData v)
{
    LTSKKSLiquidV2F o;
    UNITY_SETUP_INSTANCE_ID(v);
    UNITY_INITIALIZE_OUTPUT(LTSKKSLiquidV2F, o);
    UNITY_TRANSFER_INSTANCE_ID(v, o);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

    o.pos = UnityObjectToClipPos(v.vertex);
    o.posWS = mul(unity_ObjectToWorld, v.vertex).xyz;
    o.normalWS = UnityObjectToWorldNormal(v.normal);
    o.tangentWS = float4(
        UnityObjectToWorldDir(v.tangent.xyz),
        v.tangent.w * unity_WorldTransformParams.w);
    o.uv = v.texcoord.xy;
    o.vertexLightColor = 0.0;

    #if !defined(LTSKKS_LIQUID_FORWARDADD) && UNITY_SHOULD_SAMPLE_SH
        o.vertexLightColor =
            LTSKKS_OpenLitComputeAdditionalLights(o.posWS) *
            saturate(_VertexLightStrength);
    #endif

    TRANSFER_SHADOW(o);
    UNITY_TRANSFER_FOG(o, o.pos);
    return o;
}

LTSKKSLiquidSample LTSKKS_SampleLiquid(float2 uv)
{
    float2 liquidUV = uv * _LiquidTiling.zw + _LiquidTiling.xy;
    float4 liquidPattern = tex2D(_Texture2, LTSKKS_CalcUV(liquidUV, _Texture2_ST));
    float4 regionSample = tex2D(_liquidmask, LTSKKS_CalcUV(uv, _liquidmask_ST));
    float4 packedNormal = tex2D(_Texture3, LTSKKS_CalcUV(liquidUV, _Texture3_ST));

    return LTSKKS_EvaluateLiquidSample(
        liquidPattern,
        regionSample,
        packedNormal,
        _LiquidNormalScale,
        _liquidftop,
        _liquidfbot,
        _liquidbtop,
        _liquidbbot,
        _liquidface);
}

float3 LTSKKS_GetLiquidNormal(
    LTSKKSLiquidV2F i,
    float facing,
    LTSKKSLiquidSample liquid,
    out float3 originalNormal)
{
    originalNormal = normalize(i.normalWS);
    originalNormal = (facing < 0.0) ? -originalNormal : originalNormal;

    float3 tangent = normalize(i.tangentWS.xyz);
    float3 bitangent = normalize(cross(originalNormal, tangent) * i.tangentWS.w);
    float3 normalTS = float3(0.0, 0.0, 1.0);

    if(_UseBaseNormalMap > 0.5)
    {
        float4 packedBaseNormal =
            tex2D(_BaseNormalMap, LTSKKS_CalcUV(i.uv, _BaseNormalMap_ST));
        normalTS = LTSKKS_UnpackNormalScale(packedBaseNormal, _BaseNormalScale);
    }

    float3 maskedLiquidNormal = normalize(lerp(
        float3(0.0, 0.0, 1.0),
        liquid.normalTS,
        liquid.mask));
    normalTS = LTSKKS_BlendNormal(normalTS, maskedLiquidNormal);
    return normalize(mul(normalTS, float3x3(tangent, bitangent, originalNormal)));
}

float3 LTSKKS_LiquidFresnel(float3 specularColor, float lh)
{
    float t = pow(1.0 - saturate(lh), 5.0);
    return specularColor + (1.0 - specularColor) * t;
}

float3 LTSKKS_LiquidFresnelLerp(float3 specularColor, float grazingTerm, float nv)
{
    float t = pow(1.0 - saturate(nv), 5.0);
    return lerp(specularColor, float3(grazingTerm, grazingTerm, grazingTerm), t);
}

float3 LTSKKS_CalcLiquidSpecular(
    float3 normalDirection,
    float3 viewDirection,
    float3 lightDirection,
    float smoothness,
    float3 specularColor)
{
    float3 halfDirection = normalize(viewDirection + lightDirection);
    float nv = saturate(dot(normalDirection, viewDirection));
    float nl = saturate(dot(normalDirection, lightDirection));
    float nh = saturate(dot(normalDirection, halfDirection));
    float lh = saturate(dot(lightDirection, halfDirection));
    float perceptualRoughness = saturate(1.0 - smoothness);
    float roughness = max(perceptualRoughness * perceptualRoughness, 0.002);

    float lambdaV = nl * (nv * (1.0 - roughness) + roughness);
    float lambdaL = nv * (nl * (1.0 - roughness) + roughness);
    float roughness2 = roughness * roughness;
    float d = (nh * roughness2 - nh) * nh + 1.0;
    float ggx = roughness2 / (d * d + 1e-7);
    float specularTerm = 0.5 * ggx / (lambdaV + lambdaL + 1e-5);

    #if defined(UNITY_COLORSPACE_GAMMA)
        specularTerm = sqrt(max(1e-4, specularTerm));
    #endif

    return specularTerm * nl * LTSKKS_LiquidFresnel(specularColor, lh);
}

UnityGIInput LTSKKS_SetupLiquidGIInput(float3 positionWS)
{
    UnityGIInput data;
    UNITY_INITIALIZE_OUTPUT(UnityGIInput, data);
    data.worldPos = positionWS;
    data.probeHDR[0] = unity_SpecCube0_HDR;
    data.probeHDR[1] = unity_SpecCube1_HDR;

    #if defined(UNITY_SPECCUBE_BLENDING) || defined(UNITY_SPECCUBE_BOX_PROJECTION)
        data.boxMin[0] = unity_SpecCube0_BoxMin;
    #endif
    #if defined(UNITY_SPECCUBE_BOX_PROJECTION)
        data.boxMax[0] = unity_SpecCube0_BoxMax;
        data.probePosition[0] = unity_SpecCube0_ProbePosition;
        data.boxMax[1] = unity_SpecCube1_BoxMax;
        data.boxMin[1] = unity_SpecCube1_BoxMin;
        data.probePosition[1] = unity_SpecCube1_ProbePosition;
    #endif
    return data;
}

float3 LTSKKS_SampleLiquidReflection(
    float3 viewDirection,
    float3 normalDirection,
    float perceptualRoughness,
    float3 positionWS,
    float3 lightColor)
{
    float3 reflectionDirection = reflect(-viewDirection, normalDirection);
    float3 reflection = 0.0;

    if(_LiquidReflectionCubeOverride > 0.5 || unity_SpecCube0_HDR.x == 0.0)
    {
        float mip = perceptualRoughness * (10.2 - 4.2 * perceptualRoughness);
        float4 encoded = texCUBElod(
            _LiquidReflectionCubeTex,
            float4(reflectionDirection, mip));
        reflection = DecodeHDR(encoded, _LiquidReflectionCubeTex_HDR);
        reflection *= _LiquidReflectionCubeColor.rgb;
        reflection *= lerp(
            1.0,
            lightColor,
            saturate(_LiquidReflectionCubeEnableLighting));
    }
    else
    {
        UnityGIInput data = LTSKKS_SetupLiquidGIInput(positionWS);
        Unity_GlossyEnvironmentData glossIn;
        UNITY_INITIALIZE_OUTPUT(Unity_GlossyEnvironmentData, glossIn);
        glossIn.roughness = perceptualRoughness;
        glossIn.reflUVW = reflectionDirection;
        reflection = UnityGI_IndirectSpecular(data, 1.0, glossIn);
    }
    return reflection;
}

float4 frag(LTSKKSLiquidV2F i, fixed facing : VFACE) : SV_Target
{
    UNITY_SETUP_INSTANCE_ID(i);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

    LTSKKSLiquidSample liquid = LTSKKS_SampleLiquid(i.uv);
    clip(liquid.mask - max(_LiquidCutoff, 0.000001));

    float3 originalNormal;
    float3 normalDirection =
        LTSKKS_GetLiquidNormal(i, facing, liquid, originalNormal);
    float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.posWS);
    float3 lightDirection;
    float3 lightColor;
    float3 indirectLight = 0.0;
    float shadowMix = 1.0;
    UNITY_LIGHT_ATTENUATION(attenuation, i, i.posWS);

    #if defined(LTSKKS_LIQUID_FORWARDADD)
        lightDirection = normalize(UnityWorldSpaceLightDir(i.posWS));
        lightColor = LTSKKS_OpenLitCorrectAdditionalLight(
            _LightColor0.rgb * attenuation,
            _LightMaxLimit,
            _MonochromeLighting,
            _AsUnlit);
    #else
        LTSKKSOpenLitLightData lightData;
        LTSKKS_OpenLitComputeLights(
            lightData,
            _LightDirectionOverride,
            i.posWS,
            _lilDirectionalLightStrength);
        lightData.directLight += i.vertexLightColor;
        LTSKKS_OpenLitCorrectBaseLights(
            lightData,
            _LightMinLimit,
            _LightMaxLimit,
            _MonochromeLighting,
            _AsUnlit);

        float3 originalLightDirection =
            normalize(UnityWorldSpaceLightDir(i.posWS));
        lightDirection = lightData.lightDirection;
        lightColor = lightData.directLight;
        indirectLight = lightData.indirectLight;
        shadowMix = saturate(
            attenuation + distance(lightDirection, originalLightDirection));
    #endif

    float3 specularColor = float3(
        _LiquidReflectance,
        _LiquidReflectance,
        _LiquidReflectance);
    float receiveShadow = lerp(
        1.0,
        shadowMix,
        saturate(_LiquidReceiveShadow));
    float3 directSpecular = LTSKKS_CalcLiquidSpecular(
        normalDirection,
        viewDirection,
        lightDirection,
        saturate(_LiquidSmoothness),
        specularColor);
    directSpecular *=
        lightColor *
        receiveShadow *
        liquid.mask *
        _LiquidSpecularStrength;

    #if defined(LTSKKS_LIQUID_FORWARDADD)
        if(_LiquidApplySpecularFA < 0.5) return 0.0;
        float4 addColor = float4(directSpecular, 0.0);
        addColor.rgb = min(
            addColor.rgb,
            float3(
                _BeforeExposureLimit,
                _BeforeExposureLimit,
                _BeforeExposureLimit));
        UNITY_APPLY_FOG_COLOR(
            i.fogCoord,
            addColor,
            float4(0.0, 0.0, 0.0, 0.0));
        return addColor;
    #else
        float coverage = saturate(
            liquid.mask *
            _LiquidColor.a *
            _LiquidOpacity);
        float3 surfaceLighting = saturate(lightColor * receiveShadow + indirectLight);
        float3 tint = _LiquidColor.rgb * coverage;
        tint *= lerp(
            1.0,
            surfaceLighting,
            saturate(_LiquidEnableLighting));

        float perceptualRoughness = saturate(1.0 - _LiquidSmoothness);
        float roughness = max(
            perceptualRoughness * perceptualRoughness,
            0.002);
        float nv = saturate(dot(normalDirection, viewDirection));
        float grazingTerm = saturate(_LiquidSmoothness + _LiquidReflectance);
        float3 reflection = LTSKKS_SampleLiquidReflection(
            viewDirection,
            normalDirection,
            perceptualRoughness,
            i.posWS,
            lightColor);
        reflection *= LTSKKS_LiquidFresnelLerp(
            specularColor,
            grazingTerm,
            nv);
        reflection *=
            liquid.mask *
            _LiquidReflectionStrength *
            (1.0 - 0.28 * roughness * perceptualRoughness);

        float fresnel = pow(
            1.0 - nv,
            max(_LiquidFresnelPower, 0.01));
        reflection *= lerp(
            1.0,
            1.0 + fresnel,
            saturate(_LiquidFresnelStrength));

        float4 outputColor = float4(
            tint + directSpecular + reflection,
            coverage);
        outputColor.rgb = min(
            outputColor.rgb,
            float3(
                _BeforeExposureLimit,
                _BeforeExposureLimit,
                _BeforeExposureLimit));
        UNITY_APPLY_FOG(i.fogCoord, outputColor);
        return outputColor;
    #endif
}

#endif
