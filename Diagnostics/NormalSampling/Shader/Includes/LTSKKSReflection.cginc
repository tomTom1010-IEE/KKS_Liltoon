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
    float3 n = normalize(lerp(fd.origN, fd.reflectionN, saturate(_SpecularNormalStrength)));
    float3 h = normalize(fd.V + lightDir);
    float nh = saturate(dot(n, h));
    bool isAnisotropy = _UseAnisotropy > 0.5 && _Anisotropy2Reflection > 0.5;

    if(_SpecularToon > 0.5 && !isAnisotropy)
    {
        float toonSpec = pow(nh, 1.0 / max(fd.roughness, 0.002));
        return LTSKKS_TooningAAScale(toonSpec, _SpecularBorder, _SpecularBlur);
    }

    float nv = saturate(dot(n, fd.V));
    float nl = saturate(dot(n, lightDir));
    float lh = saturate(dot(lightDir, h));
    float roughness = max(fd.roughness, 0.002);
    float lambdaV = 0.0;
    float lambdaL = 0.0;
    float ggx = 0.0;

    if(isAnisotropy)
    {
        float roughnessT = max(roughness * (1.0 + fd.anisotropy), 0.002);
        float roughnessB = max(roughness * (1.0 - fd.anisotropy), 0.002);

        float tv = dot(fd.T, fd.V);
        float bv = dot(fd.B, fd.V);
        float tl = dot(fd.T, lightDir);
        float bl = dot(fd.B, lightDir);
        lambdaV = nl * length(float3(roughnessT * tv, roughnessB * bv, nv));
        lambdaL = nv * length(float3(roughnessT * tl, roughnessB * bl, nl));

        float roughnessT1 = roughnessT * _AnisotropyTangentWidth;
        float roughnessB1 = roughnessB * _AnisotropyBitangentWidth;
        float roughnessT2 = roughnessT * _Anisotropy2ndTangentWidth;
        float roughnessB2 = roughnessB * _Anisotropy2ndBitangentWidth;

        float anisotropyShiftNoise = LTSKKS_SAMPLE_TEX(_AnisotropyShiftNoiseMask, LTSKKS_CalcUV(fd.uvMain, _AnisotropyShiftNoiseMask_ST)).r - 0.5;
        float anisotropyShift = anisotropyShiftNoise * _AnisotropyShiftNoiseScale + _AnisotropyShift;
        float anisotropy2ndShift = anisotropyShiftNoise * _Anisotropy2ndShiftNoiseScale + _Anisotropy2ndShift;
        float3 t1 = normalize(fd.T - n * anisotropyShift);
        float3 b1 = normalize(fd.B - n * anisotropyShift);
        float3 t2 = normalize(fd.T - n * anisotropy2ndShift);
        float3 b2 = normalize(fd.B - n * anisotropy2ndShift);

        float th1 = dot(t1, h);
        float bh1 = dot(b1, h);
        float th2 = dot(t2, h);
        float bh2 = dot(b2, h);

        float r1 = roughnessT1 * roughnessB1;
        float r2 = roughnessT2 * roughnessB2;
        float3 v1 = float3(th1 * roughnessB1, bh1 * roughnessT1, nh * r1);
        float3 v2 = float3(th2 * roughnessB2, bh2 * roughnessT2, nh * r2);
        float w1 = r1 / max(dot(v1, v1), 1e-7);
        float w2 = r2 / max(dot(v2, v2), 1e-7);
        ggx = r1 * w1 * w1 * _AnisotropySpecularStrength + r2 * w2 * w2 * _Anisotropy2ndSpecularStrength;
    }
    else
    {
        lambdaV = nl * (nv * (1.0 - roughness) + roughness);
        lambdaL = nv * (nl * (1.0 - roughness) + roughness);
        float r2 = roughness * roughness;
        float d = (nh * r2 - nh) * nh + 1.0;
        ggx = r2 / (d * d + 1e-7);
    }

    float sjggx = 0.5 / (lambdaV + lambdaL + 1e-5);
    float specularTerm = sjggx * ggx;
    #if defined(UNITY_COLORSPACE_GAMMA)
        specularTerm = sqrt(max(1e-4, specularTerm));
    #endif
    specularTerm *= nl * attenuation;

    if(_SpecularToon > 0.5) return LTSKKS_TooningAAScale(specularTerm, 0.5, 0.0);
    return specularTerm * LTSKKS_FresnelTerm(specularColor, lh);
}

float3 LTSKKS_SampleFallbackReflection(float3 reflDir, float perceptualRoughness)
{
    float mip = perceptualRoughness * (10.2 - 4.2 * perceptualRoughness);
    float4 fallback = texCUBElod(_ReflectionCubeTex, float4(reflDir, mip));
    return DecodeHDR(fallback, _ReflectionCubeTex_HDR) * _ReflectionCubeColor.rgb;
}

UnityGIInput LTSKKS_SetupGIInput(float3 positionWS)
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

float3 LTSKKS_SampleUnityReflection(float3 viewDirection, float3 normalDirection, float perceptualRoughness, float3 positionWS)
{
    UnityGIInput data = LTSKKS_SetupGIInput(positionWS);
    Unity_GlossyEnvironmentData glossIn;
    glossIn.roughness = perceptualRoughness;
    glossIn.reflUVW = reflect(-viewDirection, normalDirection);
    return UnityGI_IndirectSpecular(data, 1.0, glossIn);
}

bool LTSKKS_ShouldUseFallbackReflection()
{
    // BRP uses a zero HDR decode scale when no usable reflection probe is bound.
    return _ReflectionCubeOverride > 0.5 || unity_SpecCube0_HDR.x == 0.0;
}

void LTSKKS_ApplyReflection(inout LTSKKSFragData fd)
{
    #if defined(LTSKKS_PASS_FORWARDADD)
        if(_UseReflection < 0.5 || _ApplySpecular < 0.5 || _ApplySpecularFA < 0.5) return;
    #else
        if(_UseReflection < 0.5) return;
    #endif

    fd.smoothness = saturate(_Smoothness * LTSKKS_SAMPLE_TEX(_SmoothnessTex, fd.uvMain).r);
    #if defined(LTSKKS_KKS_SKIN)
        float2 detailMaskUV = LTSKKS_CalcUV(fd.uv0, _DetailMask_ST);
        fd.smoothness *= LTSKKS_SAMPLE_KKS_SKIN(_DetailMask, detailMaskUV).a;
        fd.smoothness = lerp(fd.smoothness, max(fd.smoothness, saturate(_LiquidSmoothness)), fd.liquidMask);
    #endif
    LTSKKS_GSAAForSmoothness(fd.smoothness, fd.N, _GSAAStrength);
    fd.perceptualRoughness = saturate(fd.perceptualRoughness - fd.smoothness * fd.perceptualRoughness);
    fd.roughness = max(fd.perceptualRoughness * fd.perceptualRoughness, 0.002);

    float metallic = saturate(_Metallic * LTSKKS_SAMPLE_TEX(_MetallicGlossMap, fd.uvMain).r);
    fd.col.rgb -= metallic * fd.col.rgb;
    float3 specularColor = lerp(float3(_Reflectance, _Reflectance, _Reflectance), fd.albedo, metallic);

    float4 reflectionColor = _ReflectionColor * LTSKKS_SAMPLE_TEX(_ReflectionColorTex, fd.uvMain);
    #if !defined(LTSKKS_REFRACTION)
        reflectionColor.a *= lerp(1.0, fd.col.a, saturate(_ReflectionApplyTransparency));
    #endif

    if(_ApplySpecular > 0.5)
    {
        float attenuation = 1.0;
        #if defined(LTSKKS_PASS_FORWARDADD)
            attenuation = fd.shadowmix;
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
            float3 n = normalize(lerp(fd.origN, fd.reflectionN, saturate(_ReflectionNormalStrength)));
            float3 reflDir = reflect(-fd.V, n);
            float3 env;
            if(LTSKKS_ShouldUseFallbackReflection())
            {
                env = LTSKKS_SampleFallbackReflection(reflDir, fd.perceptualRoughness);
                env *= lerp(1.0, fd.lightColor, saturate(_ReflectionCubeEnableLighting));
            }
            else
            {
                env = LTSKKS_SampleUnityReflection(fd.V, n, fd.perceptualRoughness, fd.posWS);
            }

            float oneMinusReflectivity = 0.96 - metallic * 0.96;
            float grazingTerm = saturate(fd.smoothness + (1.0 - oneMinusReflectivity));
            #if defined(UNITY_COLORSPACE_GAMMA)
                float surfaceReduction = 1.0 - 0.28 * fd.roughness * fd.perceptualRoughness;
            #else
                float surfaceReduction = 1.0 / (fd.roughness * fd.roughness + 1.0);
            #endif
            float3 reflectCol = surfaceReduction * env * LTSKKS_FresnelLerp(specularColor, grazingTerm, fd.nv);
            #if defined(LTSKKS_REFRACTION)
                float refractionBlend = fd.col.a + (1.0 - fd.col.a) * pow(fd.nvabs, abs(_RefractionStrength) * 0.5 + 0.25);
                fd.col.rgb = lerp(env, fd.col.rgb, refractionBlend);
                reflectCol *= fd.col.a;
                fd.col.a = 1.0;
            #endif
            fd.col.rgb = LTSKKS_BlendColor(fd.col.rgb, reflectionColor.rgb, reflectCol * reflectionColor.a, _ReflectionBlendMode);
        }
    #endif
}

#endif
