#ifndef LTSKKS_OPENLIT_INCLUDED
#define LTSKKS_OPENLIT_INCLUDED

// OpenLit-compatible lighting preparation for Unity's built-in render pipeline.
// The source algorithm is OpenLit 1.0.2 (CC0 1.0 Universal).

struct LTSKKSOpenLitLightData
{
    float3 lightDirection;
    float3 directLight;
    float3 indirectLight;
};

static float4 ltskksOpenLitSHAr = 0.0;
static float4 ltskksOpenLitSHAg = 0.0;
static float4 ltskksOpenLitSHAb = 0.0;
static float4 ltskksOpenLitSHBr = 0.0;
static float4 ltskksOpenLitSHBg = 0.0;
static float4 ltskksOpenLitSHBb = 0.0;
static float4 ltskksOpenLitSHC = 0.0;

float LTSKKS_OpenLitLuminance(float3 rgb)
{
    #if defined(UNITY_COLORSPACE_GAMMA)
        return dot(rgb, float3(0.22, 0.707, 0.071));
    #else
        return dot(rgb, float3(0.0396819152, 0.458021790, 0.00609653955));
    #endif
}

float LTSKKS_OpenLitGray(float3 rgb)
{
    return dot(rgb, float3(1.0 / 3.0, 1.0 / 3.0, 1.0 / 3.0));
}

void LTSKKS_OpenLitInitializeSH(float3 positionWS)
{
    ltskksOpenLitSHAr = unity_SHAr;
    ltskksOpenLitSHAg = unity_SHAg;
    ltskksOpenLitSHAb = unity_SHAb;
    ltskksOpenLitSHBr = unity_SHBr;
    ltskksOpenLitSHBg = unity_SHBg;
    ltskksOpenLitSHBb = unity_SHBb;
    ltskksOpenLitSHC = unity_SHC;
}

float3 LTSKKS_OpenLitCustomLightDirection(float4 lightDirectionOverride)
{
    float directionLength = length(lightDirectionOverride.xyz);
    float3 directionOS = mul((float3x3)unity_ObjectToWorld, lightDirectionOverride.xyz);
    float3 objectDirection = (dot(directionOS, directionOS) > 0.000001)
        ? normalize(directionOS) * directionLength
        : 0.0;
    return (lightDirectionOverride.w > 0.5) ? objectDirection : lightDirectionOverride.xyz;
}

void LTSKKS_OpenLitShadeSH9ToonDouble(float3 direction, out float3 shMax, out float3 shMin)
{
    #if !defined(LIGHTMAP_ON) && UNITY_SHOULD_SAMPLE_SH
        float3 n = direction;
        float4 vB = n.xyzz * n.yzzx;

        float3 res = float3(ltskksOpenLitSHAr.w, ltskksOpenLitSHAg.w, ltskksOpenLitSHAb.w);
        res.r += dot(ltskksOpenLitSHBr, vB);
        res.g += dot(ltskksOpenLitSHBg, vB);
        res.b += dot(ltskksOpenLitSHBb, vB);
        res += ltskksOpenLitSHC.rgb * (n.x * n.x - n.y * n.y);

        float3 l1;
        l1.r = dot(ltskksOpenLitSHAr.rgb, n);
        l1.g = dot(ltskksOpenLitSHAg.rgb, n);
        l1.b = dot(ltskksOpenLitSHAb.rgb, n);
        shMax = res + l1;

        float3 shDirection = ltskksOpenLitSHAr.rgb + ltskksOpenLitSHAg.rgb + ltskksOpenLitSHAb.rgb;
        n = (dot(shDirection, shDirection) > 0.000001) ? normalize(shDirection) : 0.0;
        l1.r = dot(ltskksOpenLitSHAr.rgb, n);
        l1.g = dot(ltskksOpenLitSHAg.rgb, n);
        l1.b = dot(ltskksOpenLitSHAb.rgb, n);
        shMin = res + l1;

        #if defined(UNITY_COLORSPACE_GAMMA)
            shMax = LinearToGammaSpace(shMax);
            shMin = LinearToGammaSpace(shMin);
        #endif
    #else
        shMax = 0.0;
        shMin = 0.0;
    #endif
}

void LTSKKS_OpenLitComputeLights(
    out LTSKKSOpenLitLightData lightData,
    float4 lightDirectionOverride,
    float3 positionWS,
    float directionalLightStrength)
{
    LTSKKS_OpenLitInitializeSH(positionWS);

    float3 mainLightColor = _LightColor0.rgb * directionalLightStrength;
    float3 mainDirection = _WorldSpaceLightPos0.xyz * LTSKKS_OpenLitLuminance(mainLightColor);

    #if !defined(LIGHTMAP_ON) && UNITY_SHOULD_SAMPLE_SH
        float3 shDirection = (ltskksOpenLitSHAr.xyz + ltskksOpenLitSHAg.xyz + ltskksOpenLitSHAb.xyz) * (1.0 / 3.0);
        float3 shDirectionAbs = float3(shDirection.x, abs(shDirection.y), shDirection.z);
    #else
        float3 shDirectionAbs = 0.0;
    #endif

    float3 combinedDirection = shDirectionAbs + mainDirection + LTSKKS_OpenLitCustomLightDirection(lightDirectionOverride);
    lightData.lightDirection = (dot(combinedDirection, combinedDirection) > 0.000001)
        ? normalize(combinedDirection)
        : float3(0.0, 1.0, 0.0);

    LTSKKS_OpenLitShadeSH9ToonDouble(lightData.lightDirection, lightData.directLight, lightData.indirectLight);
    lightData.directLight += mainLightColor;
}

void LTSKKS_OpenLitCorrectBaseLights(
    inout LTSKKSOpenLitLightData lightData,
    float lightMinLimit,
    float lightMaxLimit,
    float monochromeLighting,
    float asUnlit)
{
    lightData.directLight = clamp(lightData.directLight, lightMinLimit, lightMaxLimit);
    float directGray = LTSKKS_OpenLitGray(lightData.directLight);
    lightData.directLight = lerp(lightData.directLight, float3(directGray, directGray, directGray), saturate(monochromeLighting));
    lightData.directLight = lerp(lightData.directLight, 1.0, saturate(asUnlit));
    lightData.indirectLight = clamp(lightData.indirectLight, 0.0, lightMaxLimit);
}

float3 LTSKKS_OpenLitCorrectAdditionalLight(float3 lightColor, float lightMaxLimit, float monochromeLighting, float asUnlit)
{
    lightColor = min(lightColor, lightMaxLimit);
    float lightGray = LTSKKS_OpenLitGray(lightColor);
    lightColor = lerp(lightColor, float3(lightGray, lightGray, lightGray), saturate(monochromeLighting));
    return lerp(lightColor, 0.0, saturate(asUnlit));
}

float3 LTSKKS_OpenLitComputeAdditionalLights(float3 positionWS)
{
    float4 toLightX = unity_4LightPosX0 - positionWS.x;
    float4 toLightY = unity_4LightPosY0 - positionWS.y;
    float4 toLightZ = unity_4LightPosZ0 - positionWS.z;

    float4 lengthSq = toLightX * toLightX + 0.000001;
    lengthSq += toLightY * toLightY;
    lengthSq += toLightZ * toLightZ;

    float4 attenuation = saturate(
        saturate((25.0 - lengthSq * unity_4LightAtten0) * 0.111375) /
        (0.987725 + lengthSq * unity_4LightAtten0));

    float3 additionalLight = unity_LightColor[0].rgb * attenuation.x;
    additionalLight += unity_LightColor[1].rgb * attenuation.y;
    additionalLight += unity_LightColor[2].rgb * attenuation.z;
    additionalLight += unity_LightColor[3].rgb * attenuation.w;
    return additionalLight;
}

#endif
