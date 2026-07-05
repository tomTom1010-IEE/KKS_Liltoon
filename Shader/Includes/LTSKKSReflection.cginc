#ifndef LTSKKS_REFLECTION_INCLUDED
#define LTSKKS_REFLECTION_INCLUDED

void LTSKKS_GSAAForSmoothness(inout float smoothness, float3 normalWS, float strength)
{
    float3 dx = ddx(normalWS);
    float3 dy = ddy(normalWS);
    float dxy = max(dot(dx, dx), dot(dy, dy));
    float roughnessGSAA = dxy / (dxy * 5.0 + 0.002) * saturate(strength);
    smoothness = min(smoothness, saturate(1.0 - roughnessGSAA));
}

float3 LTSKKS_FresnelTerm(float3 specularColor, float lh)
{
    float t = pow(1.0 - saturate(lh), 5.0);
    return specularColor + (1.0 - specularColor) * t;
}

float3 LTSKKS_FresnelLerp(float3 specularColor, float grazingTerm, float nv)
{
    float t = pow(1.0 - saturate(nv), 5.0);
    return lerp(specularColor, float3(grazingTerm, grazingTerm, grazingTerm), t);
}

float3 LTSKKS_CalcSpecular(inout LTSKKSFragData fd, float3 lightDir, float3 specularColor, float attenuation)
{
    float3 n = normalize(lerp(fd.origN, fd.N, saturate(_SpecularNormalStrength)));
    float3 h = normalize(fd.V + lightDir);
    float nh = saturate(dot(n, h));

    if(_SpecularToon > 0.5)
    {
        float toonSpec = pow(nh, 1.0 / max(fd.roughness, 0.002));
        float toonMask = LTSKKS_TooningAAScale(toonSpec, _SpecularBorder, _SpecularBlur);
        return toonMask * attenuation;
    }

    float nv = saturate(dot(n, fd.V));
    float nl = saturate(dot(n, lightDir));
    float lh = saturate(dot(lightDir, h));
    float roughness = max(fd.roughness, 0.002);
    float lambdaV = nl * (nv * (1.0 - roughness) + roughness);
    float lambdaL = nv * (nl * (1.0 - roughness) + roughness);
    float sjggx = 0.5 / (lambdaV + lambdaL + 1e-5);
    float r2 = roughness * roughness;
    float d = (nh * r2 - nh) * nh + 1.0;
    float ggx = r2 / (d * d + 1e-7);
    float specularTerm = sjggx * ggx;
    #if defined(UNITY_COLORSPACE_GAMMA)
        specularTerm = sqrt(max(1e-4, specularTerm));
    #endif
    specularTerm *= nl * attenuation;
    return specularTerm * LTSKKS_FresnelTerm(specularColor, lh);
}

float3 LTSKKS_SampleFallbackReflection(float3 reflDir, float perceptualRoughness)
{
    float mip = perceptualRoughness * (10.2 - 4.2 * perceptualRoughness);
    float4 fallback = texCUBElod(_ReflectionCubeTex, float4(reflDir, mip));
    return DecodeHDR(fallback, _ReflectionCubeTex_HDR) * _ReflectionCubeColor.rgb;
}

float3 LTSKKS_SampleUnityReflection(float3 reflDir, float perceptualRoughness)
{
    Unity_GlossyEnvironmentData glossIn;
    glossIn.roughness = perceptualRoughness;
    glossIn.reflUVW = reflDir;
    return Unity_GlossyEnvironment(UNITY_PASS_TEXCUBE(unity_SpecCube0), unity_SpecCube0_HDR, glossIn);
}

void LTSKKS_ApplyReflection(inout LTSKKSFragData fd)
{
    #if defined(LTSKKS_PASS_FORWARDADD)
        if(_UseReflection < 0.5 || _ApplySpecular < 0.5 || _ApplySpecularFA < 0.5) return;
    #else
        if(_UseReflection < 0.5) return;
    #endif

    fd.smoothness = saturate(_Smoothness * LTSKKS_SAMPLE_TEX(_SmoothnessTex, fd.uvMain).r);
    LTSKKS_GSAAForSmoothness(fd.smoothness, fd.N, _GSAAStrength);
    fd.perceptualRoughness = saturate(1.0 - fd.smoothness);
    fd.roughness = max(fd.perceptualRoughness * fd.perceptualRoughness, 0.002);

    float metallic = saturate(_Metallic * LTSKKS_SAMPLE_TEX(_MetallicGlossMap, fd.uvMain).r);
    fd.col.rgb -= metallic * fd.col.rgb;
    float3 specularColor = lerp(float3(_Reflectance, _Reflectance, _Reflectance), fd.albedo, metallic);

    float4 reflectionColor = _ReflectionColor * LTSKKS_SAMPLE_TEX(_ReflectionColorTex, fd.uvMain);
    reflectionColor.a *= lerp(1.0, fd.col.a, saturate(_ReflectionApplyTransparency));

    if(_ApplySpecular > 0.5)
    {
        float attenuation = 1.0;
        #if defined(LTSKKS_PASS_FORWARDADD)
            attenuation = fd.shadowmix * fd.attenuation;
        #elif defined(SHADOWS_SCREEN)
            attenuation = fd.shadowmix;
        #else
            attenuation = 1.0;
        #endif
        float3 spec = LTSKKS_CalcSpecular(fd, fd.L, specularColor, attenuation);
        float3 specCol = reflectionColor.rgb * fd.lightColor;
        fd.col.rgb = LTSKKS_BlendColorMask(fd.col.rgb, specCol, spec * reflectionColor.a, _ReflectionBlendMode);
    }

    #if !defined(LTSKKS_PASS_FORWARDADD)
        if(_ApplyReflection > 0.5)
        {
            float3 n = normalize(lerp(fd.origN, fd.N, saturate(_ReflectionNormalStrength)));
            float3 reflDir = reflect(-fd.V, n);
            float3 env = LTSKKS_SampleUnityReflection(reflDir, fd.perceptualRoughness);
            float3 fallbackEnv = LTSKKS_SampleFallbackReflection(reflDir, fd.perceptualRoughness);
            env = lerp(env, fallbackEnv * lerp(1.0, fd.lightColor, saturate(_ReflectionCubeEnableLighting)), saturate(_ReflectionCubeOverride));

            float oneMinusReflectivity = 0.96 - metallic * 0.96;
            float grazingTerm = saturate(fd.smoothness + (1.0 - oneMinusReflectivity));
            #if defined(UNITY_COLORSPACE_GAMMA)
                float surfaceReduction = 1.0 - 0.28 * fd.roughness * fd.perceptualRoughness;
            #else
                float surfaceReduction = 1.0 / (fd.roughness * fd.roughness + 1.0);
            #endif
            float3 reflectCol = surfaceReduction * env * LTSKKS_FresnelLerp(specularColor, grazingTerm, fd.nv);
            #if defined(LTSKKS_RENDER_TRANSPARENT) || defined(LTSKKS_RENDER_ONEPASS_TRANSPARENT) || defined(LTSKKS_RENDER_TWOPASS_TRANSPARENT)
                reflectCol *= lerp(1.0, fd.col.a, saturate(_ReflectionApplyTransparency));
            #endif
            fd.col.rgb = LTSKKS_BlendColor(fd.col.rgb, reflectionColor.rgb, reflectCol * reflectionColor.a, _ReflectionBlendMode);
        }
    #endif
}

#endif
