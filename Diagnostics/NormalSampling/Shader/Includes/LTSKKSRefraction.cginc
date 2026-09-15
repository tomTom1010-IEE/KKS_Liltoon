#ifndef LTSKKS_REFRACTION_INCLUDED
#define LTSKKS_REFRACTION_INCLUDED

sampler2D _lilBackgroundTexture;
float4 _lilBackgroundTexture_TexelSize;

float2 LTSKKS_GetGrabUV(float4 grabPos)
{
    return grabPos.xy / max(grabPos.w, LTSKKS_EPS);
}

float3 LTSKKS_SampleRefraction(float2 refractUV, float perceptualRoughness, float clipW)
{
    #if defined(LTSKKS_REFRACTION_BLUR)
        const int sampleCount = 8;
        float blurOffset = perceptualRoughness / sqrt(max(clipW, LTSKKS_EPS));
        blurOffset *= (0.03 / sampleCount) * UNITY_MATRIX_P._m11;
        float aspect = _lilBackgroundTexture_TexelSize.x * _lilBackgroundTexture_TexelSize.w;
        float3 refractColor = 0.0;
        float weightSum = 0.0;
        [unroll]
        for(int j = -sampleCount; j <= sampleCount; j++)
        {
            float weight = exp(-(float)(j * j) / (sampleCount * sampleCount * 0.5));
            refractColor += tex2D(_lilBackgroundTexture, refractUV + float2(j * blurOffset * aspect, 0.0)).rgb * weight;
            refractColor += tex2D(_lilBackgroundTexture, refractUV + float2(0.0, j * blurOffset)).rgb * weight;
            weightSum += weight * 2.0;
        }
        return refractColor / max(weightSum, LTSKKS_EPS);
    #else
        return tex2D(_lilBackgroundTexture, refractUV).rgb;
    #endif
}

void LTSKKS_ApplyRefraction(inout LTSKKSFragData fd, float4 grabPos)
{
    #if defined(LTSKKS_REFRACTION) && !defined(LTSKKS_PASS_FORWARDADD)
        float2 refractUV = LTSKKS_GetGrabUV(grabPos);
        float fresnel = pow(saturate(1.0 - fd.nv), max(_RefractionFresnelPower, LTSKKS_EPS));
        float2 viewNormal = mul((float3x3)UNITY_MATRIX_V, fd.N).xy;
        refractUV += fresnel * _RefractionStrength * viewNormal;

        float smoothness = saturate(_Smoothness * LTSKKS_SAMPLE_TEX(_SmoothnessTex, fd.uvMain).r);
        float perceptualRoughness = 1.0 - smoothness;
        float3 refractColor = LTSKKS_SampleRefraction(refractUV, perceptualRoughness, grabPos.w) * _RefractionColor.rgb;
        if(_RefractionColorFromMain > 0.5) refractColor *= fd.albedo;

        fd.col.rgb = lerp(refractColor, fd.col.rgb, fd.col.a);
    #endif
}

#endif
