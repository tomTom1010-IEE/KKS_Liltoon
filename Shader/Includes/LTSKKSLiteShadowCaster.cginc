#ifndef LTSKKS_LITE_SHADOW_CASTER_INCLUDED
#define LTSKKS_LITE_SHADOW_CASTER_INCLUDED

#include "UnityCG.cginc"
#include "LTSKKSCommon.cginc"
#include "LTSKKSLiteInput.cginc"
#include "LTSKKSLiteAlpha.cginc"

struct LTSKKSLiteShadowV2F
{
    V2F_SHADOW_CASTER;
    float2 uvMain : TEXCOORD1;
    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

LTSKKSLiteShadowV2F vert(appdata_base v)
{
    LTSKKSLiteShadowV2F o;
    UNITY_SETUP_INSTANCE_ID(v);
    UNITY_INITIALIZE_OUTPUT(LTSKKSLiteShadowV2F, o);
    UNITY_TRANSFER_INSTANCE_ID(v, o);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
    o.uvMain = LTSKKS_CalcUV(v.texcoord.xy, _MainTex_ST, _MainTex_ScrollRotate);
    TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
    return o;
}

float4 frag(LTSKKSLiteShadowV2F i) : SV_Target
{
    UNITY_SETUP_INSTANCE_ID(i);
    if(_Invisible > 0.5) discard;
    float alpha = LTSKKS_LiteSampleAlpha(i.uvMain);
    LTSKKS_LiteClipDepthAlpha(alpha, i.pos);
    SHADOW_CASTER_FRAGMENT(i)
}

#endif
