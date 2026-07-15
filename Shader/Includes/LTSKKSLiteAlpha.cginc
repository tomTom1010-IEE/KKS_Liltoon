#ifndef LTSKKS_LITE_ALPHA_INCLUDED
#define LTSKKS_LITE_ALPHA_INCLUDED

float LTSKKS_LiteSampleAlpha(float2 uvMain)
{
    return saturate(tex2D(_MainTex, uvMain).a * _Color.a);
}

void LTSKKS_LiteClipForwardAlpha(inout float alpha)
{
    #if defined(LTSKKS_LITE_OPAQUE)
        alpha = 1.0;
    #else
        clip(alpha - _Cutoff);
    #endif
}

float LTSKKS_LiteSubpassDither(float alpha, float4 screenPos)
{
    float2 pixel = fmod(floor(screenPos.xy), 4.0);
    float3 uv = float3((pixel + 0.5) * 0.25, saturate(alpha) * 0.9375);
    return tex3D(_DitherMaskLOD, uv).a;
}

void LTSKKS_LiteClipDepthAlpha(float alpha, float4 screenPos)
{
    #if defined(LTSKKS_LITE_CUTOUT)
        clip(alpha - _Cutoff);
    #elif defined(LTSKKS_LITE_TRANSPARENT)
        clip(alpha - _Cutoff);
        clip(LTSKKS_LiteSubpassDither(alpha, screenPos) - _SubpassCutoff);
    #endif
}

float4 LTSKKS_LiteFinalizeAlpha(float4 color)
{
    #if defined(LTSKKS_LITE_TRANSPARENT)
        color.rgb *= saturate(color.a);
    #endif
    return color;
}

#endif
