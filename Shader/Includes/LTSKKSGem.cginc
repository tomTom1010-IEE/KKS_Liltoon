#ifndef LTSKKS_GEM_INCLUDED
#define LTSKKS_GEM_INCLUDED

float3 LTSKKS_GemContrast(float3 color)
{
    float contrast = max(_GemEnvContrast, LTSKKS_EPS);
    color = pow(saturate(color), contrast) * contrast;
    float luminance = dot(color, float3(1.0 / 3.0, 1.0 / 3.0, 1.0 / 3.0));
    return lerp(float3(luminance, luminance, luminance), color, saturate(1.0 / contrast));
}

void LTSKKS_PrepareGemNormal(inout LTSKKSFragData fd)
{
    if(fd.facing < 0.0) fd.N = normalize(-fd.N - fd.V * 0.2);
    fd.reflectionN = fd.N;
    fd.matcapN = fd.N;
    fd.matcap2ndN = fd.N;
    fd.uvMat = LTSKKS_MatCapUV(fd.N).xy;
}

float3 LTSKKS_SampleGemEnvironment(
    LTSKKSFragData fd,
    float3 normalDirection,
    float perceptualRoughness)
{
    float3 environment;
    if(LTSKKS_ShouldUseFallbackReflection())
    {
        float3 reflectionDirection = reflect(-fd.V, normalDirection);
        environment = LTSKKS_SampleFallbackReflection(reflectionDirection, perceptualRoughness);
        environment *= lerp(1.0, fd.lightColor, saturate(_ReflectionCubeEnableLighting));
    }
    else
    {
        environment = LTSKKS_SampleUnityReflection(fd.V, normalDirection, perceptualRoughness, fd.posWS);
    }
    return environment;
}

void LTSKKS_ApplyGem(inout LTSKKSFragData fd, float4 grabPos)
{
    float3 gemViewDirection = fd.V;
    float nv1 = abs(dot(fd.N, gemViewDirection));
    float nv2 = abs(dot(fd.N, gemViewDirection.yzx));
    float nv3 = abs(dot(fd.N, gemViewDirection.zxy));
    float invnv = 1.0 - nv1;

    fd.nv = nv1;
    fd.nvabs = nv1;
    fd.shadowmix = saturate(fd.ln);
    fd.lightColor = saturate(fd.lightColor + fd.indLightColor);

    fd.col.rgb *= fd.nv;
    float4 baseColor = fd.col;
    fd.col.rgb *= 0.75;

    float2 refractUV = LTSKKS_GetGrabUV(grabPos);
    float2 refractionDirection = mul((float3x3)UNITY_MATRIX_V, fd.N).xy;
    float refractionFresnel = pow(saturate(1.0 - fd.nv), max(_RefractionFresnelPower, LTSKKS_EPS));
    float3 refractColor;
    refractColor.r = tex2D(_lilBackgroundTexture, refractUV + refractionFresnel * _RefractionStrength * refractionDirection).r;
    refractColor.g = tex2D(_lilBackgroundTexture, refractUV + refractionFresnel * (_RefractionStrength + _GemChromaticAberration) * refractionDirection).g;
    refractColor.b = tex2D(_lilBackgroundTexture, refractUV + refractionFresnel * (_RefractionStrength + _GemChromaticAberration * 2.0) * refractionDirection).b;
    fd.col.rgb *= LTSKKS_GemContrast(refractColor);

    fd.smoothness = saturate(_Smoothness * LTSKKS_SAMPLE_TEX(_SmoothnessTex, fd.uvMain).r);
    LTSKKS_GSAAForSmoothness(fd.smoothness, fd.N, _GSAAStrength);
    fd.perceptualRoughness = saturate(1.0 - fd.smoothness);
    fd.roughness = max(fd.perceptualRoughness * fd.perceptualRoughness, 0.002);

    float3 normalDirectionR = fd.N;
    float3 normalDirectionG = fd.facing < 0.0
        ? normalize(fd.N + fd.V * invnv * _GemChromaticAberration)
        : fd.N;
    float3 normalDirectionB = fd.facing < 0.0
        ? normalize(fd.N + fd.V * invnv * _GemChromaticAberration * 2.0)
        : fd.N;

    float environmentR = LTSKKS_SampleGemEnvironment(fd, normalDirectionR, fd.perceptualRoughness).r;
    float environmentG = LTSKKS_SampleGemEnvironment(fd, normalDirectionG, fd.perceptualRoughness).g;
    float environmentB = LTSKKS_SampleGemEnvironment(fd, normalDirectionB, fd.perceptualRoughness).b;
    float3 environmentColor = LTSKKS_GemContrast(float3(environmentR, environmentG, environmentB)) * _GemEnvColor.rgb;
    if(fd.facing < 0.0) environmentColor *= baseColor.rgb;

    float particle =
        step(0.5, frac(nv1 * _GemParticleLoop)) *
        step(0.5, frac(nv2 * _GemParticleLoop)) *
        step(0.5, frac(nv3 * _GemParticleLoop));
    float3 particleColor = fd.facing < 0.0
        ? 1.0 + particle * _GemParticleColor.rgb
        : 1.0;

    float grazingTerm = saturate(fd.smoothness + 0.04);
    #if defined(UNITY_COLORSPACE_GAMMA)
        float surfaceReduction = 1.0 - 0.28 * fd.roughness * fd.perceptualRoughness;
    #else
        float surfaceReduction = 1.0 / (fd.roughness * fd.roughness + 1.0);
    #endif
    float3 gemFresnel = LTSKKS_FresnelLerp(
        float3(_Reflectance, _Reflectance, _Reflectance),
        grazingTerm,
        fd.nv);
    fd.col.rgb += (surfaceReduction * gemFresnel + 0.5) * 0.5 * particleColor * environmentColor;
}

#endif
